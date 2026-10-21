-- =====================================================================
-- FacturaFlow Mobile Cloud — Modelo físico (PostgreSQL 17)
-- Actividad Evaluable 06 — Modelado e implementación de la base de datos
--
-- El esquema deriva del modelo de dominio real de la aplicación Flutter
-- (lib/data/models/) y del contrato REST implementado en el PR #51.
-- Las reglas de negocio provienen de los Issues del Corte II:
--   #40 — el motivo de rechazo exige al menos 10 caracteres
--   #41 — el número de factura es único por proveedor, no global
--   #42 — al reabrir una factura se descarta el motivo del rechazo
-- =====================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS facturaflow;
SET search_path TO facturaflow, public;

-- ---------------------------------------------------------------------
-- Tipos enumerados
-- Reproducen los enum de Dart (user_role.dart, invoice_status.dart).
-- Se usan ENUM nativos en vez de tablas de catálogo porque el conjunto de
-- valores es cerrado y lo fija el código de la aplicación.
-- ---------------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('emisor', 'contador', 'administrador');

CREATE TYPE invoice_status AS ENUM ('borrador', 'enviada', 'aprobada', 'rechazada');

-- ---------------------------------------------------------------------
-- app_user — personas que usan el sistema
-- ---------------------------------------------------------------------
CREATE TABLE app_user (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name     VARCHAR(120) NOT NULL,
    email         VARCHAR(254) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role          user_role    NOT NULL DEFAULT 'emisor',
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uq_app_user_email      UNIQUE (email),
    CONSTRAINT ck_app_user_full_name  CHECK (length(btrim(full_name)) >= 3),
    CONSTRAINT ck_app_user_email      CHECK (email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[a-z]{2,}$')
);

COMMENT ON TABLE  app_user IS 'Usuarios autenticados. El rol determina qué acciones del flujo de aprobación puede ejecutar.';
COMMENT ON COLUMN app_user.password_hash IS 'Hash PBKDF2/Argon2 de la contraseña. Nunca se almacena la contraseña en claro.';
COMMENT ON COLUMN app_user.role IS 'emisor crea facturas; contador las revisa; administrador hace ambas y ve todas.';

-- ---------------------------------------------------------------------
-- supplier — proveedores que emiten las facturas
--
-- Se normaliza fuera de invoice (3FN): supplier_name y supplier_tax_id se
-- repetían en cada factura. El Issue #41 estableció que el número de
-- factura es un consecutivo *por proveedor*, lo que confirma que el
-- proveedor es una entidad propia y no un atributo de la factura.
-- ---------------------------------------------------------------------
CREATE TABLE supplier (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_id     VARCHAR(20)  NOT NULL,
    name       VARCHAR(160) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uq_supplier_tax_id UNIQUE (tax_id),
    CONSTRAINT ck_supplier_tax_id CHECK (tax_id ~ '^[0-9.\-]{5,20}$'),
    CONSTRAINT ck_supplier_name   CHECK (length(btrim(name)) >= 1)
);

COMMENT ON TABLE  supplier IS 'Proveedor emisor de facturas, identificado por su NIT.';
COMMENT ON COLUMN supplier.tax_id IS 'NIT o documento. Formato validado en InvoiceFormViewModel.validateSupplierTaxId.';

-- ---------------------------------------------------------------------
-- invoice — documento de cobro y su estado en el flujo de aprobación
-- ---------------------------------------------------------------------
CREATE TABLE invoice (
    id               UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    number           VARCHAR(40)    NOT NULL,
    supplier_id      UUID           NOT NULL,
    issue_date       DATE           NOT NULL,
    status           invoice_status NOT NULL DEFAULT 'borrador',
    created_by_id    UUID           NOT NULL,
    notes            TEXT           NOT NULL DEFAULT '',
    rejection_reason TEXT           NULL,
    created_at       TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT fk_invoice_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier (id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_invoice_created_by
        FOREIGN KEY (created_by_id) REFERENCES app_user (id)
        ON DELETE RESTRICT,

    -- Issue #41: la unicidad es (número, proveedor), no el número solo.
    CONSTRAINT uq_invoice_number_supplier UNIQUE (number, supplier_id),

    CONSTRAINT ck_invoice_number CHECK (length(btrim(number)) >= 3),

    -- Issue #40: un motivo de rechazo debe justificar realmente el rechazo.
    CONSTRAINT ck_invoice_rejection_reason_length
        CHECK (rejection_reason IS NULL OR length(btrim(rejection_reason)) >= 10),

    -- Issues #40 y #42: solo una factura rechazada conserva motivo; al
    -- reabrirla (vuelve a 'borrador') el motivo queda en NULL.
    CONSTRAINT ck_invoice_rejection_requires_status
        CHECK (
            (status = 'rechazada' AND rejection_reason IS NOT NULL)
            OR (status <> 'rechazada' AND rejection_reason IS NULL)
        )
);

COMMENT ON TABLE  invoice IS 'Factura y su estado en el flujo borrador -> enviada -> aprobada | rechazada.';
COMMENT ON COLUMN invoice.number IS 'Consecutivo que asigna el proveedor. Único dentro del proveedor (Issue #41).';
COMMENT ON COLUMN invoice.rejection_reason IS 'Motivo del rechazo vigente, mínimo 10 caracteres (Issue #40). NULL en cualquier estado distinto de rechazada (Issue #42).';

CREATE INDEX ix_invoice_status      ON invoice (status);
CREATE INDEX ix_invoice_created_by  ON invoice (created_by_id);
CREATE INDEX ix_invoice_supplier    ON invoice (supplier_id);
CREATE INDEX ix_invoice_updated_at  ON invoice (updated_at DESC);

-- ---------------------------------------------------------------------
-- invoice_item — líneas de detalle
--
-- Los importes se guardan en centavos (BIGINT) para evitar los errores de
-- redondeo del punto flotante, igual que InvoiceItem.unitPriceCents en Dart.
-- ---------------------------------------------------------------------
CREATE TABLE invoice_item (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id       UUID         NOT NULL,
    line_number      SMALLINT     NOT NULL,
    description      VARCHAR(255) NOT NULL,
    quantity         INTEGER      NOT NULL,
    unit_price_cents BIGINT       NOT NULL,
    tax_rate         NUMERIC(5,4) NOT NULL DEFAULT 0.1900,

    CONSTRAINT fk_invoice_item_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoice (id)
        ON DELETE CASCADE,

    CONSTRAINT uq_invoice_item_line  UNIQUE (invoice_id, line_number),
    CONSTRAINT ck_invoice_item_desc  CHECK (length(btrim(description)) >= 1),
    CONSTRAINT ck_invoice_item_qty   CHECK (quantity > 0),
    CONSTRAINT ck_invoice_item_price CHECK (unit_price_cents > 0),
    CONSTRAINT ck_invoice_item_tax   CHECK (tax_rate >= 0 AND tax_rate <= 1)
);

COMMENT ON TABLE  invoice_item IS 'Línea de detalle de una factura. Se elimina en cascada con la factura.';
COMMENT ON COLUMN invoice_item.unit_price_cents IS 'Precio unitario en centavos. Entero para evitar redondeo de punto flotante.';
COMMENT ON COLUMN invoice_item.tax_rate IS 'Tasa de IVA de la línea: 0.1900 = 19%.';

CREATE INDEX ix_invoice_item_invoice ON invoice_item (invoice_id);

-- ---------------------------------------------------------------------
-- invoice_event — historial de auditoría del flujo de aprobación
--
-- Append-only: cada transición agrega una fila y ninguna se modifica.
-- Es la bitácora que conserva el motivo del rechazo después de que la
-- factura se reabre y invoice.rejection_reason vuelve a NULL (Issue #42).
-- ---------------------------------------------------------------------
CREATE TABLE invoice_event (
    id          UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id  UUID           NOT NULL,
    actor_id    UUID           NOT NULL,
    status      invoice_status NOT NULL,
    description VARCHAR(255)   NOT NULL,
    comment     TEXT           NULL,
    occurred_at TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT fk_invoice_event_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoice (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_invoice_event_actor
        FOREIGN KEY (actor_id) REFERENCES app_user (id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_invoice_event_description CHECK (length(btrim(description)) >= 1)
);

COMMENT ON TABLE  invoice_event IS 'Bitácora append-only del flujo de aprobación. Conserva el motivo del rechazo aunque la factura se reabra (Issue #42).';
COMMENT ON COLUMN invoice_event.status IS 'Estado en el que quedó la factura tras el evento.';
COMMENT ON COLUMN invoice_event.comment IS 'Comentario del actor. Obligatorio de hecho en los rechazos.';

CREATE INDEX ix_invoice_event_invoice ON invoice_event (invoice_id, occurred_at);
CREATE INDEX ix_invoice_event_actor   ON invoice_event (actor_id);

-- ---------------------------------------------------------------------
-- auth_session — token emitido por POST /auth/login
-- Soporta el contrato REST implementado en el PR #51 (Issue #43).
-- ---------------------------------------------------------------------
CREATE TABLE auth_session (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID        NOT NULL,
    token_hash   VARCHAR(255) NOT NULL,
    issued_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at   TIMESTAMPTZ NOT NULL,
    revoked_at   TIMESTAMPTZ NULL,

    CONSTRAINT fk_auth_session_user
        FOREIGN KEY (user_id) REFERENCES app_user (id)
        ON DELETE CASCADE,

    CONSTRAINT uq_auth_session_token   UNIQUE (token_hash),
    CONSTRAINT ck_auth_session_expires CHECK (expires_at > issued_at)
);

COMMENT ON TABLE  auth_session IS 'Sesión activa. Se guarda el hash del token, nunca el token en claro.';

CREATE INDEX ix_auth_session_user ON auth_session (user_id);

-- ---------------------------------------------------------------------
-- Vista de totales
-- Reproduce Invoice.subtotalCents / taxCents / totalCents de Dart, para que
-- el cálculo del monto no se duplique en la aplicación y el servidor.
-- ---------------------------------------------------------------------
CREATE VIEW invoice_totals AS
SELECT
    i.id                                                             AS invoice_id,
    COALESCE(SUM(it.quantity * it.unit_price_cents), 0)              AS subtotal_cents,
    COALESCE(SUM(ROUND(it.quantity * it.unit_price_cents * it.tax_rate)), 0) AS tax_cents,
    COALESCE(SUM(ROUND(it.quantity * it.unit_price_cents * (1 + it.tax_rate))), 0) AS total_cents
FROM invoice i
LEFT JOIN invoice_item it ON it.invoice_id = i.id
GROUP BY i.id;

COMMENT ON VIEW invoice_totals IS 'Subtotal, IVA y total en centavos por factura.';

-- ---------------------------------------------------------------------
-- Mantenimiento de updated_at
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_app_user_updated_at
    BEFORE UPDATE ON app_user
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER tg_invoice_updated_at
    BEFORE UPDATE ON invoice
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;

-- =====================================================================
-- Descripciones de columna
-- Alimentan el diccionario de datos, que se genera leyendo el catálogo
-- (docs/taller6/generar_diccionario.sql). Documentar aquí garantiza que
-- el diccionario nunca se desincronice del esquema.
-- =====================================================================
SET search_path TO facturaflow, public;

COMMENT ON COLUMN app_user.id         IS 'Identificador único del usuario.';
COMMENT ON COLUMN app_user.full_name  IS 'Nombre completo. Mínimo 3 caracteres; se usa para las iniciales del avatar.';
COMMENT ON COLUMN app_user.email      IS 'Correo corporativo. Único en el sistema; es la credencial de acceso.';
COMMENT ON COLUMN app_user.is_active  IS 'Baja lógica: FALSE impide iniciar sesión sin perder la trazabilidad histórica.';
COMMENT ON COLUMN app_user.created_at IS 'Fecha y hora de alta del usuario.';
COMMENT ON COLUMN app_user.updated_at IS 'Última modificación; la mantiene el trigger tg_app_user_updated_at.';

COMMENT ON COLUMN supplier.id         IS 'Identificador único del proveedor.';
COMMENT ON COLUMN supplier.name       IS 'Razón social del proveedor.';
COMMENT ON COLUMN supplier.created_at IS 'Fecha y hora de registro del proveedor.';

COMMENT ON COLUMN invoice.id            IS 'Identificador único de la factura.';
COMMENT ON COLUMN invoice.supplier_id   IS 'Proveedor que emite la factura. RESTRICT: no se borra un proveedor con facturas.';
COMMENT ON COLUMN invoice.issue_date    IS 'Fecha de emisión que figura en el documento del proveedor.';
COMMENT ON COLUMN invoice.status        IS 'Estado en el flujo: borrador, enviada, aprobada o rechazada.';
COMMENT ON COLUMN invoice.created_by_id IS 'Usuario emisor que registró la factura. RESTRICT preserva la autoría.';
COMMENT ON COLUMN invoice.notes         IS 'Observaciones libres del emisor. Cadena vacía cuando no hay notas.';
COMMENT ON COLUMN invoice.created_at    IS 'Fecha y hora de registro en el sistema.';
COMMENT ON COLUMN invoice.updated_at    IS 'Última modificación; la mantiene el trigger tg_invoice_updated_at.';

COMMENT ON COLUMN invoice_item.id          IS 'Identificador único de la línea.';
COMMENT ON COLUMN invoice_item.invoice_id  IS 'Factura a la que pertenece la línea. CASCADE: se borra con ella.';
COMMENT ON COLUMN invoice_item.line_number IS 'Orden de la línea dentro de la factura, empezando en 1.';
COMMENT ON COLUMN invoice_item.description IS 'Concepto facturado.';
COMMENT ON COLUMN invoice_item.quantity    IS 'Unidades facturadas. Debe ser mayor que cero.';

COMMENT ON COLUMN invoice_event.id          IS 'Identificador único del evento.';
COMMENT ON COLUMN invoice_event.invoice_id  IS 'Factura auditada. CASCADE: el historial se borra con la factura.';
COMMENT ON COLUMN invoice_event.actor_id    IS 'Usuario que ejecutó la transición. RESTRICT preserva la trazabilidad.';
COMMENT ON COLUMN invoice_event.description IS 'Texto legible del evento, por ejemplo "Aprobada por Carlos Ruiz".';
COMMENT ON COLUMN invoice_event.occurred_at IS 'Momento del evento. Ordena el historial cronológicamente.';

COMMENT ON COLUMN auth_session.id         IS 'Identificador único de la sesión.';
COMMENT ON COLUMN auth_session.user_id    IS 'Usuario propietario de la sesión. CASCADE: se borra con el usuario.';
COMMENT ON COLUMN auth_session.token_hash IS 'Hash del token Bearer. Nunca se almacena el token en claro.';
COMMENT ON COLUMN auth_session.issued_at  IS 'Momento de emisión del token.';
COMMENT ON COLUMN auth_session.expires_at IS 'Caducidad del token. Debe ser posterior a issued_at.';
COMMENT ON COLUMN auth_session.revoked_at IS 'Momento del cierre de sesión. NULL mientras la sesión siga activa.';
