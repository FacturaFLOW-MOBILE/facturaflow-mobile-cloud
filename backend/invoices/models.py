"""Modelos de FacturaFlow Mobile Cloud.

Enfoque *database-first*: la fuente de verdad del esquema es
`docs/taller6/schema.sql`, que la migración 0001 aplica tal cual. Estos
modelos mapean esas tablas para el ORM y Django REST Framework, pero no las
gestionan (`managed = False`), de modo que el esquema no puede divergir
entre el DDL documentado y lo que Django cree que existe.

Los campos reproducen uno a uno el dominio de la aplicación Flutter
(`lib/data/models/`). Las reglas de negocio de los Issues #40, #41 y #42
viven como restricciones de la base de datos y se replican aquí como
validación de aplicación.
"""

from django.core.validators import MinLengthValidator, MinValueValidator, RegexValidator
from django.db import models


class UserRole(models.TextChoices):
    """Equivale a `user_role.dart`."""

    EMISOR = "emisor", "Usuario emisor"
    CONTADOR = "contador", "Contador"
    ADMINISTRADOR = "administrador", "Administrador"


class InvoiceStatus(models.TextChoices):
    """Equivale a `invoice_status.dart`."""

    BORRADOR = "borrador", "Borrador"
    ENVIADA = "enviada", "En revisión"
    APROBADA = "aprobada", "Aprobada"
    RECHAZADA = "rechazada", "Rechazada"


class AppUser(models.Model):
    """Usuario autenticado. El rol determina sus permisos en el flujo."""

    id = models.UUIDField(primary_key=True)
    full_name = models.CharField(max_length=120, validators=[MinLengthValidator(3)])
    email = models.EmailField(max_length=254, unique=True)
    password_hash = models.CharField(max_length=255)
    role = models.CharField(max_length=20, choices=UserRole.choices, default=UserRole.EMISOR)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = "app_user"
        verbose_name = "usuario"
        verbose_name_plural = "usuarios"

    def __str__(self) -> str:
        return f"{self.full_name} ({self.role})"

    @property
    def can_create_invoices(self) -> bool:
        return self.role in {UserRole.EMISOR, UserRole.ADMINISTRADOR}

    @property
    def can_review_invoices(self) -> bool:
        return self.role in {UserRole.CONTADOR, UserRole.ADMINISTRADOR}

    @property
    def can_see_all_invoices(self) -> bool:
        return self.role != UserRole.EMISOR


class Supplier(models.Model):
    """Proveedor emisor, identificado por su NIT."""

    id = models.UUIDField(primary_key=True)
    tax_id = models.CharField(
        max_length=20,
        unique=True,
        validators=[RegexValidator(r"^[0-9.\-]{5,20}$", "El NIT solo admite números, puntos y guion.")],
    )
    name = models.CharField(max_length=160)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = "supplier"
        verbose_name = "proveedor"
        verbose_name_plural = "proveedores"

    def __str__(self) -> str:
        return f"{self.name} ({self.tax_id})"


class Invoice(models.Model):
    """Factura y su estado en el flujo de aprobación."""

    #: Longitud mínima del motivo de rechazo (Issue #40).
    MIN_REJECTION_REASON_LENGTH = 10

    id = models.UUIDField(primary_key=True)
    number = models.CharField(max_length=40, validators=[MinLengthValidator(3)])
    supplier = models.ForeignKey(
        Supplier, on_delete=models.PROTECT, db_column="supplier_id", related_name="invoices"
    )
    issue_date = models.DateField()
    status = models.CharField(max_length=20, choices=InvoiceStatus.choices, default=InvoiceStatus.BORRADOR)
    created_by = models.ForeignKey(
        AppUser, on_delete=models.PROTECT, db_column="created_by_id", related_name="created_invoices"
    )
    notes = models.TextField(blank=True, default="")
    rejection_reason = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = "invoice"
        verbose_name = "factura"
        verbose_name_plural = "facturas"
        # Issue #41: el consecutivo lo lleva cada proveedor.
        constraints = [
            models.UniqueConstraint(fields=["number", "supplier"], name="uq_invoice_number_supplier"),
        ]

    def __str__(self) -> str:
        return f"{self.number} — {self.get_status_display()}"

    @classmethod
    def rejection_reason_error(cls, reason: str | None) -> str | None:
        """Valida el motivo de rechazo (Issue #40).

        Es el equivalente en el backend de `Invoice.rejectionReasonError` en
        Dart: la misma regla, aplicada en la misma forma.
        """
        text = (reason or "").strip()
        if not text:
            return "Debes indicar el motivo del rechazo."
        if len(text) < cls.MIN_REJECTION_REASON_LENGTH:
            return f"Explica el motivo con al menos {cls.MIN_REJECTION_REASON_LENGTH} caracteres."
        return None

    @property
    def subtotal_cents(self) -> int:
        return sum(item.subtotal_cents for item in self.items.all())

    @property
    def tax_cents(self) -> int:
        return sum(item.tax_cents for item in self.items.all())

    @property
    def total_cents(self) -> int:
        return self.subtotal_cents + self.tax_cents


class InvoiceItem(models.Model):
    """Línea de detalle. Los importes se guardan en centavos."""

    id = models.UUIDField(primary_key=True)
    invoice = models.ForeignKey(
        Invoice, on_delete=models.CASCADE, db_column="invoice_id", related_name="items"
    )
    line_number = models.SmallIntegerField()
    description = models.CharField(max_length=255)
    quantity = models.IntegerField(validators=[MinValueValidator(1)])
    unit_price_cents = models.BigIntegerField(validators=[MinValueValidator(1)])
    tax_rate = models.DecimalField(max_digits=5, decimal_places=4, default=0.19)

    class Meta:
        managed = False
        db_table = "invoice_item"
        ordering = ["line_number"]
        verbose_name = "ítem de factura"
        verbose_name_plural = "ítems de factura"
        constraints = [
            models.UniqueConstraint(fields=["invoice", "line_number"], name="uq_invoice_item_line"),
        ]

    def __str__(self) -> str:
        return f"{self.quantity} × {self.description}"

    @property
    def subtotal_cents(self) -> int:
        return self.quantity * self.unit_price_cents

    @property
    def tax_cents(self) -> int:
        return round(self.subtotal_cents * float(self.tax_rate))


class InvoiceEvent(models.Model):
    """Bitácora append-only del flujo de aprobación.

    Conserva el motivo del rechazo aunque la factura se reabra y
    `Invoice.rejection_reason` vuelva a NULL (Issue #42).
    """

    id = models.UUIDField(primary_key=True)
    invoice = models.ForeignKey(
        Invoice, on_delete=models.CASCADE, db_column="invoice_id", related_name="history"
    )
    actor = models.ForeignKey(
        AppUser, on_delete=models.PROTECT, db_column="actor_id", related_name="invoice_events"
    )
    status = models.CharField(max_length=20, choices=InvoiceStatus.choices)
    description = models.CharField(max_length=255)
    comment = models.TextField(null=True, blank=True)
    occurred_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = "invoice_event"
        ordering = ["occurred_at"]
        verbose_name = "evento de factura"
        verbose_name_plural = "eventos de factura"

    def __str__(self) -> str:
        return f"{self.occurred_at:%Y-%m-%d %H:%M} — {self.description}"


class AuthSession(models.Model):
    """Sesión emitida por `POST /auth/login`. Guarda el hash del token."""

    id = models.UUIDField(primary_key=True)
    user = models.ForeignKey(
        AppUser, on_delete=models.CASCADE, db_column="user_id", related_name="sessions"
    )
    token_hash = models.CharField(max_length=255, unique=True)
    issued_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = "auth_session"
        verbose_name = "sesión"
        verbose_name_plural = "sesiones"

    def __str__(self) -> str:
        return f"sesión de {self.user_id}"
