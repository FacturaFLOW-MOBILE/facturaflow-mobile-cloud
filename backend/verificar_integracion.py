"""Verificación de la integración Django <-> PostgreSQL.

Comprueba que los modelos del ORM operan contra el esquema autoritativo
aplicado por la migración 0001 y que las reglas de negocio de los Issues
#40, #41 y #42 se cumplen en la base.

Uso:  python verificar_integracion.py
"""

from __future__ import annotations

import os
import uuid
from datetime import date, datetime, timedelta, timezone

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "facturaflow.settings")
django.setup()

from django.db import IntegrityError, connection, transaction  # noqa: E402

from invoices.models import (  # noqa: E402
    AppUser,
    AuthSession,
    Invoice,
    InvoiceEvent,
    InvoiceItem,
    InvoiceStatus,
    Supplier,
    UserRole,
)

ok = 0
fail = 0


def check(label: str, condition: bool, detail: str = "") -> None:
    global ok, fail
    if condition:
        ok += 1
        print(f"  PASA  {label}" + (f" — {detail}" if detail else ""))
    else:
        fail += 1
        print(f"  FALLA {label}" + (f" — {detail}" if detail else ""))


def now() -> datetime:
    return datetime.now(timezone.utc)


print("=" * 70)
print("PRUEBA 1 — Conexión a la base de datos")
print("=" * 70)
with connection.cursor() as cur:
    cur.execute("SELECT version(), current_database(), current_schema();")
    version, dbname, schema = cur.fetchone()
check("Conexión establecida", True, version.split(",")[0])
check("Base y esquema correctos", dbname == "facturaflow" and schema == "facturaflow",
      f"{dbname}/{schema}")

print()
print("=" * 70)
print("PRUEBA 2 — Tablas visibles para el ORM")
print("=" * 70)
with connection.cursor() as cur:
    cur.execute(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_schema='facturaflow' AND table_type='BASE TABLE' ORDER BY 1;"
    )
    tablas = [r[0] for r in cur.fetchall()]
esperadas = {"app_user", "auth_session", "invoice", "invoice_event", "invoice_item", "supplier"}
check("Las 6 tablas del modelo existen", esperadas.issubset(set(tablas)), ", ".join(tablas))

print()
print("=" * 70)
print("PRUEBA 6 — Inserción mediante el ORM")
print("=" * 70)

# Limpieza de una ejecución previa.
InvoiceEvent.objects.all().delete()
InvoiceItem.objects.all().delete()
Invoice.objects.all().delete()
AuthSession.objects.all().delete()
Supplier.objects.all().delete()
AppUser.objects.all().delete()

emisor = AppUser.objects.create(
    id=uuid.uuid4(), full_name="Ana Torres", email="ana@facturaflow.demo",
    password_hash="pbkdf2$demo", role=UserRole.EMISOR,
    created_at=now(), updated_at=now(),
)
contador = AppUser.objects.create(
    id=uuid.uuid4(), full_name="Carlos Ruiz", email="carlos@facturaflow.demo",
    password_hash="pbkdf2$demo", role=UserRole.CONTADOR,
    created_at=now(), updated_at=now(),
)
papeleria = Supplier.objects.create(
    id=uuid.uuid4(), tax_id="900123456-7", name="Papelería La 45", created_at=now()
)
transportes = Supplier.objects.create(
    id=uuid.uuid4(), tax_id="901555222-1", name="Transportes Andinos S.A.S.", created_at=now()
)
factura = Invoice.objects.create(
    id=uuid.uuid4(), number="FE-1001", supplier=papeleria, issue_date=date(2026, 10, 1),
    status=InvoiceStatus.BORRADOR, created_by=emisor,
    notes="Pendiente de adjuntar la orden de compra.",
    created_at=now(), updated_at=now(),
)
InvoiceItem.objects.create(
    id=uuid.uuid4(), invoice=factura, line_number=1,
    description="Resma de papel carta", quantity=12, unit_price_cents=1_850_000, tax_rate="0.19",
)
InvoiceItem.objects.create(
    id=uuid.uuid4(), invoice=factura, line_number=2,
    description="Tóner impresora láser", quantity=2, unit_price_cents=24_500_000, tax_rate="0.19",
)
InvoiceEvent.objects.create(
    id=uuid.uuid4(), invoice=factura, actor=emisor,
    status=InvoiceStatus.BORRADOR, description="Factura creada", occurred_at=now(),
)
AuthSession.objects.create(
    id=uuid.uuid4(), user=emisor, token_hash="sha256$demo",
    issued_at=now(), expires_at=now() + timedelta(hours=8),
)
check("Inserción de 2 usuarios, 2 proveedores, 1 factura, 2 ítems, 1 evento, 1 sesión", True)

print()
print("=" * 70)
print("PRUEBA 5 y 7 — Relaciones y consulta con JOIN")
print("=" * 70)
leida = Invoice.objects.select_related("supplier", "created_by").prefetch_related("items").get(pk=factura.pk)
check("FK a proveedor navegable", leida.supplier.name == "Papelería La 45", leida.supplier.tax_id)
check("FK a usuario navegable", leida.created_by.full_name == "Ana Torres")
check("Relación inversa de ítems", leida.items.count() == 2)
check("Totales calculados", leida.subtotal_cents == 71_200_000,
      f"subtotal={leida.subtotal_cents} iva={leida.tax_cents} total={leida.total_cents}")

print()
print("=" * 70)
print("PRUEBA 14 — Reglas de negocio de los Issues del Corte II")
print("=" * 70)

# Issue #41: mismo número, distinto proveedor -> permitido.
try:
    with transaction.atomic():
        otra = Invoice.objects.create(
            id=uuid.uuid4(), number="FE-1001", supplier=transportes,
            issue_date=date(2026, 10, 2), created_by=emisor,
            created_at=now(), updated_at=now(),
        )
    check("Issue #41 — dos proveedores pueden usar FE-1001", True)
except IntegrityError as exc:
    check("Issue #41 — dos proveedores pueden usar FE-1001", False, str(exc)[:60])

# Issue #41: mismo número y mismo proveedor -> rechazado.
try:
    with transaction.atomic():
        Invoice.objects.create(
            id=uuid.uuid4(), number="FE-1001", supplier=papeleria,
            issue_date=date(2026, 10, 3), created_by=emisor,
            created_at=now(), updated_at=now(),
        )
    check("Issue #41 — rechaza número duplicado en el mismo proveedor", False, "se aceptó")
except IntegrityError:
    check("Issue #41 — rechaza número duplicado en el mismo proveedor", True)

# Issue #40: validación de aplicación, idéntica a la de Dart.
check("Issue #40 — rechaza motivo vacío", Invoice.rejection_reason_error("") is not None)
check("Issue #40 — rechaza motivo de un carácter", Invoice.rejection_reason_error(".") is not None)
check("Issue #40 — acepta una justificación real",
      Invoice.rejection_reason_error("Falta la orden de compra") is None)

# Issue #40: la misma regla, a nivel de base de datos.
try:
    with transaction.atomic():
        Invoice.objects.filter(pk=factura.pk).update(
            status=InvoiceStatus.RECHAZADA, rejection_reason="."
        )
    check("Issue #40 — la BD rechaza un motivo demasiado corto", False, "se aceptó")
except IntegrityError:
    check("Issue #40 — la BD rechaza un motivo demasiado corto", True)

# Rechazo válido.
Invoice.objects.filter(pk=factura.pk).update(
    status=InvoiceStatus.RECHAZADA, rejection_reason="Falta la orden de compra firmada"
)
InvoiceEvent.objects.create(
    id=uuid.uuid4(), invoice=factura, actor=contador, status=InvoiceStatus.RECHAZADA,
    description="Rechazada por Carlos Ruiz", comment="Falta la orden de compra firmada",
    occurred_at=now(),
)
check("PRUEBA 8 — actualización de estado", Invoice.objects.get(pk=factura.pk).status == "rechazada")

# Issue #42: volver a borrador conservando el motivo debe ser imposible.
try:
    with transaction.atomic():
        Invoice.objects.filter(pk=factura.pk).update(status=InvoiceStatus.BORRADOR)
    check("Issue #42 — la BD impide un borrador con motivo", False, "se aceptó")
except IntegrityError:
    check("Issue #42 — la BD impide un borrador con motivo", True)

# La reapertura correcta limpia el motivo.
Invoice.objects.filter(pk=factura.pk).update(
    status=InvoiceStatus.BORRADOR, rejection_reason=None
)
reabierta = Invoice.objects.get(pk=factura.pk)
check("Issue #42 — al reabrir, el motivo queda en NULL",
      reabierta.status == "borrador" and reabierta.rejection_reason is None)
check("Issue #42 — el historial conserva el motivo",
      InvoiceEvent.objects.filter(invoice=factura, comment__isnull=False).exists())

print()
print("=" * 70)
print("PRUEBA 10 — Integridad referencial")
print("=" * 70)
try:
    with transaction.atomic():
        Supplier.objects.filter(pk=transportes.pk).delete()
    check("PROTECT impide borrar un proveedor con facturas", False, "se borró")
except Exception as exc:  # django.db.models.ProtectedError o IntegrityError
    check("PROTECT impide borrar un proveedor con facturas", True, type(exc).__name__)

print()
print("=" * 70)
print("PRUEBA 9 — Borrado en cascada")
print("=" * 70)
items_antes = InvoiceItem.objects.filter(invoice=factura).count()
with connection.cursor() as cur:
    cur.execute("DELETE FROM invoice WHERE id = %s;", [str(factura.pk)])
items_despues = InvoiceItem.objects.filter(invoice_id=factura.pk).count()
check("CASCADE elimina los ítems con la factura",
      items_antes == 2 and items_despues == 0, f"{items_antes} -> {items_despues}")

print()
print("=" * 70)
print(f"RESULTADO: {ok} aserciones PASA, {fail} FALLA")
print("=" * 70)
raise SystemExit(1 if fail else 0)
