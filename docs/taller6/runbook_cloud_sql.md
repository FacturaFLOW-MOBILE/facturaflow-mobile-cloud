# Runbook — Implementación en Google Cloud SQL (PostgreSQL 17)

Procedimiento reproducible para desplegar el esquema de FacturaFlow Mobile
Cloud en Google Cloud SQL. Cada paso indica qué evidencia produce para el
documento académico.

> **Estado:** preparado, pendiente de ejecución. Requiere una cuenta de
> Google Cloud con facturación habilitada y la autorización del propietario,
> porque Cloud SQL **no tiene capa gratuita permanente**.

---

## 0. Requisitos previos

| Elemento | Estado en este equipo |
|---|---|
| Google Cloud CLI | ✅ instalado (`gcloud` 589.0.0) |
| Cuenta de Google | ⚠️ pendiente de autenticar |
| Proyecto GCP | ⚠️ pendiente de crear |
| Facturación habilitada | ⚠️ pendiente — **genera costos** |
| `schema.sql` validado | ✅ probado en PostgreSQL 17.11 local |

---

## 1. Autenticación

```bash
gcloud auth login
```

Abre el navegador. Se autoriza con la cuenta institucional o personal del
estudiante. **No se comparten contraseñas por ningún otro medio.**

```bash
gcloud auth list          # confirma la cuenta activa
```

---

## 2. Crear el proyecto

```bash
export PROJECT_ID="facturaflow-mcc-2026"
export REGION="us-central1"

gcloud projects create "$PROJECT_ID" --name="FacturaFlow Mobile Cloud"
gcloud config set project "$PROJECT_ID"
```

> **Evidencia — Figura 1:** consola de GCP mostrando el proyecto creado.

### Vincular la cuenta de facturación

```bash
gcloud billing accounts list
gcloud billing projects link "$PROJECT_ID" --billing-account=<ID_DE_FACTURACION>
```

---

## 3. Habilitar las APIs necesarias

```bash
gcloud services enable sqladmin.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

---

## 4. Crear la instancia de Cloud SQL

La configuración más económica apta para la actividad: edición Enterprise,
núcleo compartido, 10 GB de disco SSD, zona única.

```bash
gcloud sql instances create facturaflow-db \
  --database-version=POSTGRES_17 \
  --tier=db-f1-micro \
  --region="$REGION" \
  --storage-size=10GB \
  --storage-type=SSD \
  --availability-type=ZONAL \
  --backup-start-time=03:00 \
  --require-ssl
```

Puntos de la configuración que conviene sustentar:

- `POSTGRES_17` — misma versión mayor que el entorno local de pruebas, de
  modo que el esquema validado se aplica sin cambios.
- `--require-ssl` — rechaza cualquier conexión sin TLS.
- `--backup-start-time` — copia de seguridad diaria automática
  (**disponibilidad**, uno de los objetivos del taller).
- `--availability-type=ZONAL` — una sola zona. Para alta disponibilidad real
  sería `REGIONAL`, que duplica el costo; se documenta como mejora futura.

> **Evidencia — Figura 2:** instancia en estado *RUNNABLE* en la consola.

---

## 5. Crear la base de datos y el usuario de aplicación

```bash
gcloud sql databases create facturaflow --instance=facturaflow-db

# La contraseña se genera localmente y NO se escribe en ningún archivo
# versionado ni se comparte por chat.
export DB_APP_PASSWORD="$(openssl rand -base64 24)"

gcloud sql users create facturaflow_app \
  --instance=facturaflow-db \
  --password="$DB_APP_PASSWORD"
```

> **Evidencia — Figura 3:** base de datos `facturaflow` listada en la instancia.

### Guardar el secreto en Secret Manager

```bash
printf '%s' "$DB_APP_PASSWORD" | \
  gcloud secrets create facturaflow-db-password --data-file=-
```

---

## 6. Conectar de forma segura con Cloud SQL Auth Proxy

El proxy evita exponer la IP pública de la instancia y cifra el tráfico sin
gestionar certificados a mano.

```bash
gcloud components install cloud-sql-proxy

cloud-sql-proxy "$PROJECT_ID:$REGION:facturaflow-db" --port 5432
```

Deja el proxy corriendo en una terminal aparte; la base queda accesible en
`127.0.0.1:5432`.

---

## 7. Aplicar el esquema

Dos caminos equivalentes. **Se recomienda el B**, porque deja constancia de
la migración aplicada en la tabla `django_migrations`.

### A — SQL directo

```bash
psql "host=127.0.0.1 port=5432 user=facturaflow_app dbname=facturaflow" \
     -v ON_ERROR_STOP=1 -f docs/taller6/schema.sql
```

### B — Migración de Django (recomendado)

```bash
cd backend
cp .env.example .env     # completar con los datos de Cloud SQL
# DB_HOST=127.0.0.1  DB_PORT=5432  DB_USER=facturaflow_app
# DB_PASSWORD=<desde Secret Manager>  DB_SSLMODE=disable (el proxy ya cifra)

./.venv/Scripts/python.exe manage.py migrate
```

> **Evidencia — Figura 7:** salida de `migrate` con `invoices.0001_initial... OK`.

---

## 8. Verificar la implementación

```bash
# Tablas creadas
psql ... -c "\dt facturaflow.*"

# Llaves foráneas y reglas de borrado
psql ... -f docs/taller6/pruebas.sql

# Integración completa del ORM
cd backend && ./.venv/Scripts/python.exe verificar_integracion.py
```

> **Evidencias — Figuras 4, 5, 6, 8, 9, 11:** listado de tablas, estructura,
> llaves foráneas, consulta SQL y su resultado, y pruebas de persistencia.

---

## 9. Acceso para el docente

Se concede el rol **`roles/cloudsql.viewer`**, que permite inspeccionar la
instancia y su configuración sin poder modificarla ni eliminarla.

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:endiromero@gmail.com" \
  --role="roles/cloudsql.viewer"
```

Para que además pueda consultar los datos, se crea un usuario de base de
datos de solo lectura:

```sql
CREATE USER docente_readonly WITH PASSWORD '<generada aparte>';
GRANT CONNECT ON DATABASE facturaflow TO docente_readonly;
GRANT USAGE ON SCHEMA facturaflow TO docente_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA facturaflow TO docente_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA facturaflow
  GRANT SELECT ON TABLES TO docente_readonly;
```

> **Principio de mínimo privilegio:** solo lectura. No se concede
> `roles/owner` ni `roles/editor`, ni se comparten credenciales personales.

---

## 10. Control de costos

```bash
# Detener la instancia cuando no se use (deja de cobrar cómputo)
gcloud sql instances patch facturaflow-db --activation-policy=NEVER

# Reanudar para la sustentación
gcloud sql instances patch facturaflow-db --activation-policy=ALWAYS

# Eliminar definitivamente al terminar la asignatura
gcloud sql instances delete facturaflow-db
```

> Detener la instancia **no** elimina el cobro por almacenamiento, solo el de
> cómputo. Para dejar de pagar por completo hay que eliminarla.

---

## Checklist de evidencias para el documento

| Figura | Contenido | Comando / pantalla |
|---|---|---|
| 1 | Proyecto en GCP | Consola → Inicio |
| 2 | Instancia PostgreSQL 17 | Consola → SQL → Resumen |
| 3 | Base de datos creada | Consola → SQL → Bases de datos |
| 4 | Listado de tablas | `\dt facturaflow.*` |
| 5 | Estructura de una tabla | `\d facturaflow.invoice` |
| 6 | Llaves foráneas | Consulta de `information_schema` |
| 7 | Migraciones aplicadas | `manage.py migrate` |
| 8 | Consulta SQL ejecutada | `SELECT` con JOIN |
| 9 | Resultado de la consulta | salida de psql |
| 10 | Conexión del backend | `verificar_integracion.py` |
| 11 | Pruebas de persistencia | `pruebas.sql` |
| 12 | Acceso del docente | Consola → IAM |
