# Reporte de Sprint Review - Cierre de Corte II

**Asignatura:** Mobile and Cloud Computing - IS0276 - 210

**Proyecto:** FacturaFlow Mobile Cloud

**Equipo de Desarrollo:**
- David Santiago Piedrahita Cabeza - [@santkd16](https://github.com/santkd16) - Desarrollo Flutter (Issues #34–#39), API Django → Cloud Firestore (Issue #33, PR #63) e integración continua
- Jhon Alexander Vargas Catuche - [@jhon9036](https://github.com/jhon9036) - Desarrollo Flutter (Issues #40–#45), modelado e implementación de la base de datos cloud (Taller 6, PR #61) y revisión de código

**Fecha de la Sprint Review:** 21/10/2026

**Enlace a la Discusión en GitHub Discussions:** PENDIENTE — se enlaza al publicarla

**Enlace a la Demo en Video (si aplica):** PENDIENTE

**Enlace al APK / Release:** PENDIENTE

---

## 1. Resumen Ejecutivo del Incremento de Software

FacturaFlow es una aplicación Flutter para Android que registra facturas de proveedores y las lleva por un flujo de revisión: el emisor crea y envía, el contador aprueba o rechaza con un motivo, y cada cambio queda en una bitácora. La arquitectura es MVVM: las vistas consumen ViewModels mediante Provider, y los ViewModels dependen de interfaces de repositorio con dos implementaciones, una de demostración en memoria y otra remota por HTTP.

El incremento del Corte II se compone de:

- **Correcciones de los 12 reportes del docente.** Las de los Issues #40–#45 están integradas en `main`; las de los Issues #34–#39 tienen PR revisado y pendiente de merge.
- **Modelo de datos.** Diagrama ER, diccionario de datos y esquema validado en PostgreSQL 17, e implementación en Cloud Firestore (Taller 6, [PR #61](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/61)).
- **Persistencia real.** Una API Django expone el contrato REST que la app ya consumía y guarda los datos en Firestore ([PR #63](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/63)). Con `DEMO_MODE=false`, la app deja los datos de ejemplo y lee y escribe en la nube a través de esa API.

**Estado de la persistencia desde el teléfono:** PENDIENTE de evidencia (sección 3).

**Limitación conocida:** la API se ejecuta en el PC del equipo y el teléfono la alcanza por USB (`adb reverse`). Publicarla en Cloud Run exige habilitar facturación en el proyecto, que no está activa; por eso no hay todavía un servidor HTTPS público para una APK de release.

---

## 2. Matriz de Trazabilidad: Historias de Usuario y Bugs del Sprint (Taller 5)

El Sprint del Taller 5 no incluyó historias de usuario: los 12 ítems son reportes del docente (@endijromero), clasificados por él como bug o *code smell*. Estado verificado en GitHub el 20/10/2026.

| Tipo (HU/Bug) | ID Issue | Título de la Incidencia | Responsable | Rama Git | Pull Request (PR) | Estado (Done / Incomplete) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Bug | [#34](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/34) | Búsqueda limitada en facturas | @santkd16 | `santiago/issue-34-busqueda-facturas` | [#54](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/54) (abierto → `dev`; aprobado) | Incomplete: falta merge |
| Bug | [#35](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/35) | Validación incompleta del NIT | @santkd16 | `santiago/issue-35-validacion-nit` | [#55](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/55) (abierto → `dev`; aprobado) | Incomplete: falta merge |
| Bug | [#36](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/36) | Fallo en modo producción por defecto | @santkd16 | `santiago/issue-36-modo-produccion` | [#56](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/56) (abierto → `dev`; aprobado) | Incomplete: falta merge |
| Bug | [#37](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/37) | Error de parseo de moneda | @santkd16 | `santiago/issue-37-parseo-moneda` | [#57](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/57) (abierto → `dev`; aprobado) | Incomplete: falta merge |
| Code Smell | [#38](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/38) | Formateador de moneda y fecha manual | @santkd16 | `santiago/issue-38-formatos-intl` | [#58](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/58) (abierto → `dev`; aprobado) | Incomplete: falta merge |
| Code Smell | [#39](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/39) | Datos hardcodeados en producción | @santkd16 | `santiago/issue-39-demo-assets` | [#59](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/59) (abierto → `dev`; cambios solicitados) | Incomplete: corregir NIT del JSON y merge |
| Bug | [#40](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/40) | Falta de validación en comentario de rechazo | @jhon9036 | `jhon/issue-40-validacion-rechazo` | [#47](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/47) (merged → `main`; revisión posterior al merge) | Incomplete: falta prueba con persistencia cloud |
| Bug | [#41](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/41) | Duplicidad de número de factura global | @jhon9036 | `jhon/issue-41-duplicidad-numero-nit` | [#48](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/48) (merged → `main`; revisión posterior al merge) | Incomplete: falta prueba con persistencia cloud |
| Bug | [#42](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/42) | Inconsistencia del motivo de rechazo al reabrir | @jhon9036 | `jhon/issue-42-limpiar-motivo-reapertura` | [#46](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/46) (merged → `main`; revisión posterior al merge) | Incomplete: falta prueba con persistencia cloud |
| Bug | [#43](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/43) | Ausencia de implementación de cliente HTTP | @jhon9036 | `jhon/issue-43-cliente-http` | [#51](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/51) (merged → `main`; revisión posterior al merge) | Incomplete: falta prueba con persistencia cloud |
| Code Smell | [#44](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/44) | Navegación mágica (magic strings) | @jhon9036 | `jhon/issue-44-go-router` | [#50](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/50) (merged → `main`; aprobado antes del merge) | Done |
| Code Smell | [#45](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/45) | Uso de valores mágicos en UI | @jhon9036 | `jhon/issue-45-design-tokens` | [#49](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/49) (merged → `main`; revisión posterior al merge) | Done |

Trabajo asociado al Sprint:

- [PR #53](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/53) (merged): restauró la dependencia `http`, que se perdió al integrar el enrutador.
- [PR #61](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/61) (abierto): modelo de datos del Taller 6.
- [PR #63](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/63) (abierto): API Django → Firestore (Issue #33).

---

## 3. Integración y Persistencia con la Base de Datos Cloud (Taller 6)

- **Plataforma Cloud utilizada:** Google Cloud Firestore en modo nativo. Proyecto `facturaflow-mcc-2026`, base `(default)`, región `nam5`, sin facturación habilitada. La app no accede a Firestore directamente: llama a la API Django del PR #63, que usa credenciales de servidor (IAM).

- **Cuenta con acceso docente:** `endiromero@gmail.com` (Verificada: Sí). Rol `roles/datastore.viewer` (solo lectura), comprobado con `gcloud projects get-iam-policy facturaflow-mcc-2026` el 20/10/2026.

- **Coherencia con el Modelo ER y Diccionario de Datos:**

  El modelo relacional del Taller 6 ([diagrama ER, diccionario y esquema](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/tree/docs/taller-6-modelado-bd/docs/taller6)) se traduce a Firestore así:

  | Entidad (ER) | Colección en Firestore | Cómo se conserva la regla del modelo |
  | :--- | :--- | :--- |
  | `app_user` | `/users/{id}` | Perfil y rol. El hash de la contraseña se separa en `/credentials/{id}`, que ningún cliente puede leer |
  | `supplier` | `/suppliers/{NIT}` | El NIT es el id del documento: equivale a `UNIQUE (tax_id)` |
  | `invoice` | `/invoices/{NIT}_{número}` | El id compuesto equivale a `UNIQUE (number, supplier_id)` del Issue #41 |
  | `invoice_item` | `/invoices/{id}/items/{línea}` | Subcolección: equivale a la llave foránea con `ON DELETE CASCADE` |
  | `invoice_event` | `/invoices/{id}/events/{evento}` | Subcolección: bitácora de auditoría |
  | `auth_session` | `/sessions/{id}` | Guarda el hash del token, nunca el token |

  Los campos conservan los nombres del diccionario en *camelCase* (`tax_id` → `taxId`, `unit_price_cents` → `unitPriceCents`). La factura guarda además `supplierName`, `createdByName` y los totales, porque Firestore no tiene `JOIN`. Las reglas de los Issues #40, #41 y #42, que en PostgreSQL son restricciones `CHECK` y `UNIQUE`, las valida la API en el servidor.

- **Evidencias de Persistencia en Tiempo Real:**

  PENDIENTE: capturas de la app en el teléfono y de la consola de Firestore mostrando la misma factura (crear, enviar, aprobar o rechazar, y releer tras reiniciar la app).

  La app no escucha cambios en tiempo real. Lo que hace en el teléfono aparece de inmediato en Firestore, y los cambios hechos desde otra sesión se ven en la app al deslizar la lista hacia abajo para recargarla.

---

## 4. Auditoría de Flujo Git y Code Review

- **Cumplimiento de la regla de ramas individuales:** cada uno de los 12 Issues tiene su rama, creada por su responsable: `santiago/issue-34…39-*` y `jhon/issue-40…45-*`. El trabajo del Taller 6 está en `docs/taller-6-modelado-bd` y la API en `santiago/issue-33-django-firestore`. Ninguna rama se eliminó tras el merge, para conservar la trazabilidad.

- **Code Review y Aprobación de Pull Requests:**

  | PR | Revisión | Antes del merge |
  | :--- | :--- | :--- |
  | [#50](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/50#pullrequestreview-5398921083) | @santkd16: aprobado | Sí |
  | [#46](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/46#pullrequestreview-5401748065), [#47](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/47#pullrequestreview-5401748106), [#48](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/48#pullrequestreview-5401748148), [#49](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/49#pullrequestreview-5401748198), [#51](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/51#pullrequestreview-5401748238), [#53](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/53#pullrequestreview-5401748277) | @santkd16: comentarios | No: revisión posterior al merge |
  | [#54](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/54#pullrequestreview-5594741547), [#55](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/55#pullrequestreview-5594741730), [#56](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/56#pullrequestreview-5594741923), [#57](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/57#pullrequestreview-5594742114), [#58](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/58#pullrequestreview-5594742255) | @jhon9036: aprobado | Sí (pendientes de merge) |
  | [#59](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/59#pullrequestreview-5594742400) | @jhon9036: cambios solicitados (NIT inválidos en el JSON) | Sí |
  | [#61](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/61#pullrequestreview-5590456037) | @santkd16: 4 hallazgos; corregidos y nueva revisión solicitada | Sí |
  | [#63](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/63#pullrequestreview-5594981953) | @jhon9036: cambios solicitados (normalización del NIT) | Sí |

  Las revisiones de @jhon9036 verificaron el código antes de opinar: los seis PR #54–#59 se integraron en una simulación sobre `dev` sin conflictos y con 145 pruebas en verde, y la API del PR #63 se probó con 48 comprobaciones HTTP contra el emulador de Firestore.

---

## 5. Verificación de la Definition of Done (DoD)

| Criterio de la Definition of Done (DoD) | Cumplimiento | Evidencia / Justificación |
| :--- | :---: | :--- |
| Código compila sin errores en la rama principal | ✅ | `main` en `6a61680`: `flutter analyze` sin problemas, 134 pruebas en verde y `flutter build apk --release` correcto (20/10/2026) |
| Ramas individuales creadas por cada HU/Bug | ✅ | 12 ramas, una por Issue (sección 4) |
| Pull Requests individuales enlazados a issues | ❌ | Cada Issue tiene su propio PR, pero los PR #54–#59 apuntan a `dev`: GitHub solo enlaza el cierre (`Closes #N`) cuando el PR va a la rama por defecto, y los Issues #34–#39 no quedan vinculados |
| Code review realizado y aprobado por pares | ❌ | De los PR de @jhon9036, solo #50 tuvo aprobación antes del merge; #46–#49, #51 y #53 se revisaron después. Los PR #54–#58 están aprobados y #59 tiene cambios solicitados, todos sin merge |
| Persistencia funcional en la base de datos cloud | ❌ | PENDIENTE: prueba de punta a punta app → API → Firestore en el teléfono |
| Acceso otorgado a endiromero@gmail.com | ✅ | `roles/datastore.viewer` sobre `facturaflow-mcc-2026`, verificado el 20/10/2026 |
| Pruebas de usuario y verificación funcional | ❌ | PENDIENTE: recorrido en el teléfono con emisor y contador |

---

## 6. Balance de Acciones de Mejora del Corte I (Taller 4)

La retrospectiva del Corte I ([#29](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/29), [#30](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/30), [#31](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/31)) dejó dos acciones registradas como Issues. No se creó la etiqueta `retro-action`, así que se identifican por su número.

| Acción de mejora | Issue | Resultado en el Corte II |
| :--- | :--- | :--- |
| Conectar la app con la base de datos en la nube y desarrollar las pantallas pendientes del prototipo | [#32](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/32) (@jhon9036) | Parcial. La conexión se resolvió con la API del PR #63. Las pantallas de selección de empresa, carga de archivos, cámara y OCR no se iniciaron |
| Integrar Flutter con el backend Django REST | [#33](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/33) (@santkd16) | Implementado en el PR #63, con cambios solicitados y sin merge. El Issue se cerró antes de la revisión; se propone reabrirlo hasta que el PR se fusione |

Qué mejoró en el proceso:

- **Flujo de ramas:** todas las incidencias del Sprint se trabajaron en una rama propia con PR independiente.
- **Revisión de código:** en el Taller 5, seis PR (#46–#49, #51 y #53) se fusionaron antes de recibir revisión. En este cierre, los PR #54–#59, #61 y #63 se revisaron antes de cualquier merge, con pruebas que respaldan cada observación.
- **Integración continua:** los PR #54–#59, #62 y #63 incorporan workflows de GitHub Actions que ejecutan `flutter analyze` y `flutter test`; los de #62 y #63 compilan además la APK, y el de #63 ejecuta las pruebas de la API. Todavía no están en `main`.

---

## 7. Adaptaciones y Proyección para el Corte III

- **Lecciones aprendidas durante la Sprint Review:** PENDIENTE: se registran después de la sesión con el docente.

- **Deuda técnica o ítems pendientes (Not Done):**
  - Merge de los PR #54–#59, #61 y #63 tras resolver los cambios solicitados.
  - Publicar la API en un servidor HTTPS; Cloud Run requiere habilitar facturación.
  - Validar el dígito de verificación del NIT en la API, después de corregir los NIT de los datos existentes.
  - Pantallas del prototipo pendientes del Issue #32: selección de empresa, carga de archivos, cámara y OCR.
  - Limitar intentos de inicio de sesión y usar una cuenta de servicio con permisos mínimos en lugar de credenciales personales.

- **Próximos pasos en el Product Backlog (Corte III):**
  1. Multimedia: captura con cámara, carga de PDF y XML, y OCR para prellenar la factura.
  2. Seguridad: API sobre HTTPS, límite de intentos de inicio de sesión y cuenta de servicio con permisos mínimos.
  3. CI/CD: despliegue automático de la API y APK publicada en GitHub Releases desde Actions.
  4. Sincronización: actualizar la lista sin recargar a mano.
