# Diccionario de datos — FacturaFlow Mobile Cloud

> Generado automáticamente desde el catálogo de la base implementada
> (`information_schema` / `pg_catalog`) mediante `generar_diccionario.sql`.
> PostgreSQL 17.11 · esquema `facturaflow` · 2026-10-13

## Tabla `app_user`

Usuarios autenticados. El rol determina qué acciones del flujo de aprobación puede ejecutar.

| # | Campo | Tipo | Long./Prec. | PK | FK | Nulo | Predeterminado | Restricciones | Descripción |
|---|-------|------|-------------|----|----|------|----------------|---------------|-------------|
| 1 | `id` | uuid | 128 bits | Sí |  | No | `gen_random_uuid()` | — | Identificador único del usuario. |
| 2 | `full_name` | character varying | 120 |  |  | No | — | CHECK ((length(btrim((full_name)::text)) >= 3)) | Nombre completo. Mínimo 3 caracteres; se usa para las iniciales del avatar. |
| 3 | `email` | character varying | 254 |  |  | No | — | CHECK (((email)::text ~* '^[^@[:space:]]+@[^@[:space:]]+\.[a-z]{2,}$'::text)); UNIQUE (email) | Correo corporativo. Único en el sistema; es la credencial de acceso. |
| 4 | `password_hash` | character varying | 255 |  |  | No | — | — | Hash PBKDF2/Argon2 de la contraseña. Nunca se almacena la contraseña en claro. |
| 5 | `role` | facturaflow.user_role | — |  |  | No | `'emisor'::facturaflow.user_role` | — | emisor crea facturas; contador las revisa; administrador hace ambas y ve todas. |
| 6 | `is_active` | boolean | — |  |  | No | `true` | — | Baja lógica: FALSE impide iniciar sesión sin perder la trazabilidad histórica. |
| 7 | `created_at` | timestamp with time zone | — |  |  | No | `now()` | — | Fecha y hora de alta del usuario. |
| 8 | `updated_at` | timestamp with time zone | — |  |  | No | `now()` | — | Última modificación; la mantiene el trigger tg_app_user_updated_at. |
## Tabla `auth_session`

Sesión activa. Se guarda el hash del token, nunca el token en claro.

| # | Campo | Tipo | Long./Prec. | PK | FK | Nulo | Predeterminado | Restricciones | Descripción |
|---|-------|------|-------------|----|----|------|----------------|---------------|-------------|
| 1 | `id` | uuid | 128 bits | Sí |  | No | `gen_random_uuid()` | — | Identificador único de la sesión. |
| 2 | `user_id` | uuid | 128 bits |  | `app_user.id` | No | — | — | Usuario propietario de la sesión. CASCADE: se borra con el usuario. |
| 3 | `token_hash` | character varying | 255 |  |  | No | — | UNIQUE (token_hash) | Hash del token Bearer. Nunca se almacena el token en claro. |
| 4 | `issued_at` | timestamp with time zone | — |  |  | No | `now()` | CHECK ((expires_at > issued_at)) | Momento de emisión del token. |
| 5 | `expires_at` | timestamp with time zone | — |  |  | No | — | CHECK ((expires_at > issued_at)) | Caducidad del token. Debe ser posterior a issued_at. |
| 6 | `revoked_at` | timestamp with time zone | — |  |  | Sí | — | — | Momento del cierre de sesión. NULL mientras la sesión siga activa. |
## Tabla `invoice`

Factura y su estado en el flujo borrador -> enviada -> aprobada | rechazada.

| # | Campo | Tipo | Long./Prec. | PK | FK | Nulo | Predeterminado | Restricciones | Descripción |
|---|-------|------|-------------|----|----|------|----------------|---------------|-------------|
| 1 | `id` | uuid | 128 bits | Sí |  | No | `gen_random_uuid()` | — | Identificador único de la factura. |
| 2 | `number` | character varying | 40 |  |  | No | — | CHECK ((length(btrim((number)::text)) >= 3)); UNIQUE (number, supplier_id) | Consecutivo que asigna el proveedor. Único dentro del proveedor (Issue #41). |
| 3 | `supplier_id` | uuid | 128 bits |  | `supplier.id` | No | — | UNIQUE (number, supplier_id) | Proveedor que emite la factura. RESTRICT: no se borra un proveedor con facturas. |
| 4 | `issue_date` | date | — |  |  | No | — | — | Fecha de emisión que figura en el documento del proveedor. |
| 5 | `status` | facturaflow.invoice_status | — |  |  | No | `'borrador'::facturaflow.invoice_status` | CHECK ((((status = 'rechazada'::facturaflow.invoice_status) AND (rejection_reason IS NOT NULL)) OR ((status <> 'rechazada'::facturaflow.invoice_status) AND (rejection_reason IS NULL)))) | Estado en el flujo: borrador, enviada, aprobada o rechazada. |
| 6 | `created_by_id` | uuid | 128 bits |  | `app_user.id` | No | — | — | Usuario emisor que registró la factura. RESTRICT preserva la autoría. |
| 7 | `notes` | text | — |  |  | No | `''::text` | — | Observaciones libres del emisor. Cadena vacía cuando no hay notas. |
| 8 | `rejection_reason` | text | — |  |  | Sí | — | CHECK (((rejection_reason IS NULL) OR (length(btrim(rejection_reason)) >= 10))); CHECK ((((status = 'rechazada'::facturaflow.invoice_status) AND (rejection_reason IS NOT NULL)) OR ((status <> 'rechazada'::facturaflow.invoice_status) AND (rejection_reason IS NULL)))) | Motivo del rechazo vigente, mínimo 10 caracteres (Issue #40). NULL en cualquier estado distinto de rechazada (Issue #42). |
| 9 | `created_at` | timestamp with time zone | — |  |  | No | `now()` | — | Fecha y hora de registro en el sistema. |
| 10 | `updated_at` | timestamp with time zone | — |  |  | No | `now()` | — | Última modificación; la mantiene el trigger tg_invoice_updated_at. |
## Tabla `invoice_event`

Bitácora append-only del flujo de aprobación. Conserva el motivo del rechazo aunque la factura se reabra (Issue #42).

| # | Campo | Tipo | Long./Prec. | PK | FK | Nulo | Predeterminado | Restricciones | Descripción |
|---|-------|------|-------------|----|----|------|----------------|---------------|-------------|
| 1 | `id` | uuid | 128 bits | Sí |  | No | `gen_random_uuid()` | — | Identificador único del evento. |
| 2 | `invoice_id` | uuid | 128 bits |  | `invoice.id` | No | — | — | Factura auditada. CASCADE: el historial se borra con la factura. |
| 3 | `actor_id` | uuid | 128 bits |  | `app_user.id` | No | — | — | Usuario que ejecutó la transición. RESTRICT preserva la trazabilidad. |
| 4 | `status` | facturaflow.invoice_status | — |  |  | No | — | — | Estado en el que quedó la factura tras el evento. |
| 5 | `description` | character varying | 255 |  |  | No | — | CHECK ((length(btrim((description)::text)) >= 1)) | Texto legible del evento, por ejemplo "Aprobada por Carlos Ruiz". |
| 6 | `comment` | text | — |  |  | Sí | — | — | Comentario del actor. Obligatorio de hecho en los rechazos. |
| 7 | `occurred_at` | timestamp with time zone | — |  |  | No | `now()` | — | Momento del evento. Ordena el historial cronológicamente. |
## Tabla `invoice_item`

Línea de detalle de una factura. Se elimina en cascada con la factura.

| # | Campo | Tipo | Long./Prec. | PK | FK | Nulo | Predeterminado | Restricciones | Descripción |
|---|-------|------|-------------|----|----|------|----------------|---------------|-------------|
| 1 | `id` | uuid | 128 bits | Sí |  | No | `gen_random_uuid()` | — | Identificador único de la línea. |
| 2 | `invoice_id` | uuid | 128 bits |  | `invoice.id` | No | — | UNIQUE (invoice_id, line_number) | Factura a la que pertenece la línea. CASCADE: se borra con ella. |
| 3 | `line_number` | smallint | 16 bits |  |  | No | — | UNIQUE (invoice_id, line_number) | Orden de la línea dentro de la factura, empezando en 1. |
| 4 | `description` | character varying | 255 |  |  | No | — | CHECK ((length(btrim((description)::text)) >= 1)) | Concepto facturado. |
| 5 | `quantity` | integer | 32 bits |  |  | No | — | CHECK ((quantity > 0)) | Unidades facturadas. Debe ser mayor que cero. |
| 6 | `unit_price_cents` | bigint | 64 bits |  |  | No | — | CHECK ((unit_price_cents > 0)) | Precio unitario en centavos. Entero para evitar redondeo de punto flotante. |
| 7 | `tax_rate` | numeric | 5,4 |  |  | No | `0.1900` | CHECK (((tax_rate >= (0)::numeric) AND (tax_rate <= (1)::numeric))) | Tasa de IVA de la línea: 0.1900 = 19%. |
## Tabla `supplier`

Proveedor emisor de facturas, identificado por su NIT.

| # | Campo | Tipo | Long./Prec. | PK | FK | Nulo | Predeterminado | Restricciones | Descripción |
|---|-------|------|-------------|----|----|------|----------------|---------------|-------------|
| 1 | `id` | uuid | 128 bits | Sí |  | No | `gen_random_uuid()` | — | Identificador único del proveedor. |
| 2 | `tax_id` | character varying | 20 |  |  | No | — | CHECK (((tax_id)::text ~ '^[0-9.\-]{5,20}$'::text)); UNIQUE (tax_id) | NIT o documento. Formato validado en InvoiceFormViewModel.validateSupplierTaxId. |
| 3 | `name` | character varying | 160 |  |  | No | — | CHECK ((length(btrim((name)::text)) >= 1)) | Razón social del proveedor. |
| 4 | `created_at` | timestamp with time zone | — |  |  | No | `now()` | — | Fecha y hora de registro del proveedor. |
