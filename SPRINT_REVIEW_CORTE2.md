# Reporte de Sprint Review - Cierre de Corte II

**Asignatura:** Mobile and Cloud Computing - IS0276 - 210  
**Proyecto:** FacturaFLOW Mobile Cloud  
**Repositorio oficial:** https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud  
**Equipo de desarrollo:** David Santiago Piedrahita Cabeza (@santkd16) — Issues #34–#39 e integración #33; Jhon Vargas (@jhon9036) — Issues #40–#45, modelado cloud y mejora #32.  
**Fecha prevista de la Sprint Review:** 21/10/2026.  
**Estado del documento:** Preparación de la Review, corte de verificación 20/10/2026. No sustituye pruebas en vivo ni aprobaciones de terceros.  
**Discusión de GitHub:** PENDIENTE de crear y enlazar.  
**APK / Release:** PENDIENTE de generar y publicar.  
**Video demostrativo (si aplica):** PENDIENTE de grabar y enlazar.

> **Criterio de transparencia:** este reporte distingue lo implementado, lo registrado en GitHub y lo pendiente de verificar. No se llama "Done" a un PR abierto, una prueba no ejecutada en el incremento integrado o una conexión cloud que no se haya demostrado desde la aplicación.

## 1. Resumen ejecutivo del incremento de software

FacturaFLOW es una aplicación Flutter con arquitectura MVVM que separa vistas, ViewModels y repositorios de datos. Incorpora roles de emisor, contador y administrador; creación, edición, envío, aprobación y rechazo de facturas; validaciones e historial de eventos. En la rama principal están disponibles repositorios demo y el cliente HTTP remoto (integrado mediante PR #51).

El Corte II incluye correcciones y refactorizaciones específicas de los Issues #34–#45 y el trabajo de modelado y persistencia del Taller 6. Las correcciones de Jhon (#40–#45) fueron fusionadas; las de Santiago (#34–#39) están implementadas en sus ramas y propuestas mediante PR separados, pero permanecen abiertas. El material del Taller 6 (Django, PostgreSQL, diagrama, diccionario, archivos y scripts de Cloud Firestore) existe en el PR #61 y todavía no está integrado a main.

**Limitación actual:** en main la configuración \`DEMO_MODE\` tiene por defecto el valor \`true\`. El backend Django del PR #61 contiene modelos y migraciones, pero \`backend/facturaflow/urls.py\` no expone aún los endpoints REST utilizados por Flutter. No hay evidencia verificada aquí de creación/edición de facturas *desde la app móvil* reflejada en Cloud SQL o Firestore. Esta integración sigue pendiente, vinculada con los Issues #32 y #33.

## 2. Matriz de trazabilidad: HU y Bugs del Sprint (Taller 5)

Estado verificado con los PR de GitHub el 20/10/2026. "Incompleto" significa que aún no cumple toda la Definition of Done del Taller 7 (revisión, merge y demostración cloud), aunque exista código y pruebas por rama.

| Tipo | Issue | Incidencia / cambio | Responsable | Rama | Pull Request | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| Bug | [#34](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/34) | Búsqueda por ítems y monto | @santkd16 | santiago/issue-34-busqueda-facturas | [#54](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/54) abierto → dev | Incompleto: merge/review/cloud |
| Bug | [#35](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/35) | Validación de NIT | @santkd16 | santiago/issue-35-validacion-nit | [#55](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/55) abierto → dev | Incompleto: merge/review/cloud |
| Bug | [#36](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/36) | Modo demo por defecto | @santkd16 | santiago/issue-36-modo-produccion | [#56](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/56) abierto → dev | Incompleto: merge/review/cloud |
| Bug | [#37](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/37) | Parseo de moneda | @santkd16 | santiago/issue-37-parseo-moneda | [#57](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/57) abierto → dev | Incompleto: merge/review/cloud |
| Mejora | [#38](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/38) | Formatos mediante intl | @santkd16 | santiago/issue-38-formatos-intl | [#58](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/58) abierto → dev | Incompleto: merge/review/cloud |
| Mejora | [#39](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/39) | Datos demo desde JSON | @santkd16 | santiago/issue-39-demo-assets | [#59](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/59) abierto → dev | Incompleto: merge/review/cloud |
| Bug | [#40](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/40) | Motivo mínimo de rechazo | @jhon9036 | jhon/issue-40-validacion-rechazo | [#47](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/47) fusionado → main | Código integrado; falta demo cloud |
| Bug | [#41](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/41) | Número único por NIT | @jhon9036 | jhon/issue-41-duplicidad-numero-nit | [#48](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/48) fusionado → main | Código integrado; falta demo cloud |
| Bug | [#42](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/42) | Limpiar motivo al reabrir | @jhon9036 | jhon/issue-42-limpiar-motivo-reapertura | [#46](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/46) fusionado → main | Código integrado; falta demo cloud |
| Mejora | [#43](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/43) | Cliente HTTP remoto | @jhon9036 | jhon/issue-43-cliente-http | [#51](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/51) fusionado → main | Cliente integrado; API aún pendiente |
| Mejora | [#44](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/44) | Navegación go_router | @jhon9036 | jhon/issue-44-go-router | [#50](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/50) fusionado → main | Código integrado; revisión aprobada registrada |
| Mejora | [#45](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/45) | Design tokens | @jhon9036 | jhon/issue-45-design-tokens | [#49](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/49) fusionado → main | Código integrado; falta demo integrada |

**Corrección de dependencias:** [PR #53](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/53) fue fusionado a main para restaurar \`http\` después de la integración del enrutador.

**Verificaciones CI observadas:** las últimas ejecuciones automáticas disponibles para los PR #54–#59 finalizaron con \`success\` en sus ramas individuales. Esto no equivale a probar todos los cambios combinados en main o en Android.

## 3. Integración y persistencia con la base de datos cloud (Taller 6)

**Diseño relacional:** PostgreSQL 17, con seis tablas (app_user, supplier, invoice, invoice_item, invoice_event, auth_session).  
**Implementación documental y scripts cloud:** Cloud Firestore, modelado en el [PR #61](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/61), todavía abierto.  
**Carpeta técnica:** [docs/taller6](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/tree/docs/taller-6-modelado-bd/docs/taller6).

El PR #61 declara el proyecto \`facturaflow-mcc-2026\`, base \`(default)\`, región \`nam5\`, y documenta los resultados de 50 aserciones sobre PostgreSQL, Django y Firestore. Son **resultados aportados en el PR**, no una nueva ejecución ni una prueba de extremo a extremo Flutter→Cloud verificada en esta Review.

Existe además un proyecto Firebase utilizado durante la preparación por el equipo con ID \`facturaflow-mobile-cloud\`; **son IDs distintos**. Antes de la presentación debe escogerse y comprobarse el proyecto cloud efectivo, su contenido actual y sus reglas.

**Cuenta del docente:** \`endiromero@gmail.com\`. El PR #61 documenta \`roles/datastore.viewer\` sobre el proyecto de Jhon; hay que verificar en IAM que el permiso siga vigente. Esta revisión de GitHub no permite comprobar directamente IAM.

**Persistencia móvil-cloud — PENDIENTE de evidencia:**
1. Ejecutar app en dispositivo o emulador Android con una API cloud real, \`DEMO_MODE=false\` y \`API_BASE_URL\` operativo.
2. Crear una factura desde la app, registrar su número e ID y mostrar el registro en la consola/consulta de la base.
3. Editar la factura desde la app y comprobar la actualización persistida.
4. Consultar de nuevo tras reiniciar la aplicación y verificar que la factura sigue allí.
5. Mostrar las relaciones factura-proveedor-items-eventos de acuerdo con el ER y el diccionario del Taller 6.

**No confundir:** correr Flutter con \`DEMO_MODE=true\`, visualizar documentos Firestore desde la consola o ejecutar scripts Python de carga no demuestra por sí solo lectura/escritura desde la aplicación móvil.

### Riesgos técnicos abiertos

- El PR #61 aún no expone las rutas REST de Django que consume el cliente HTTP.
- Se requiere un servidor accesible desde el dispositivo y credenciales configuradas de forma segura.
- Antes de utilizar las reglas Firestore en producción se deben probar permisos por rol, acceso a subcolecciones y transiciones de estados desde clientes autenticados.
- Los scripts de carga y verificación del PR #61 pueden eliminar registros preexistentes; usar solo un entorno de prueba o hacerlos no destructivos.
- La instancia Cloud SQL exige facturación habilitada; no declarar un despliegue PostgreSQL en GCP sin evidencia de la instancia.

## 4. Auditoría del flujo Git y Code Review

**Regla de ramas:** se identifican ramas independientes de Santiago para #34–#39 y de Jhon para #40–#45.

**PR individuales:** todos los Issues #34–#45 cuentan con un PR propio. Los PR de Santiago (#54–#59) permanecen abiertos con destino \`dev\`; los PR de Jhon (#46–#51) están integrados en \`main\`. \`main\`, \`dev\` y \`feature/taller6-firebase\` apuntaban al mismo commit \`6a61680\` durante la verificación.

**Code Reviews:** existe una revisión \`APPROVED\` de @santkd16 en el PR #50; en los PR #46–#49 y #51 se observaron revisiones \`COMMENTED\`. En los PR #54–#59 y #61 no se observaron revisiones aprobadas. No inventar una aprobación: cada integrante debe revisar realmente el código y registrar su revisión antes del merge.

**Acciones pendientes:**
- Solicitar y completar code review de #54–#59, resolver los comentarios y fusionarlos en orden verificando conflictos entre #37 y #38.
- Revisar los problemas de seguridad y pruebas del PR #61; fusionarlo solo después de validación.
- Ejecutar \`flutter analyze\`, \`flutter test\`, compilación APK y smoke test en el commit de la rama principal resultante.
- Conservar enlaces a los comentarios de revisión y capturas de los merges.

## 5. Definition of Done (DoD)

| Criterio | Estado 20/10/2026 | Evidencia / razón |
| --- | --- | --- |
| Flutter compila en el incremento final/main | PENDIENTE | Ejecutar pruebas y build después de integrar PR |
| Ramas individuales por HU/Bug | SÍ | Ramas #34–#45 identificadas en GitHub |
| PR independientes enlazados | SÍ | #46–#51 y #54–#59 |
| Todos los PR revisados y aprobados | NO | Faltan aprobaciones formales en PR abiertos |
| Todos los cambios del sprint integrados | NO | #54–#59 pendientes |
| Modelo ER y diccionario elaborados | SÍ, en PR | PR #61, pendiente merge |
| Persistencia real desde app hacia cloud | NO VERIFICADO | Issues #32 y #33 abiertos; falta demo E2E |
| Acceso del profesor en cloud | POR VERIFICAR | Verificar IAM con captura actual |
| APK o demo móvil para la Review | PENDIENTE | Generar y enlazar Release o video |
| Discussion de Sprint Review y comentarios individuales | PENDIENTE | Crear Discussion y registrar aportes reales |
| Documento SPRINT_REVIEW_CORTE2.md | EN PREPARACIÓN | Este archivo debe revisarse, completar evidencias y fusionarse |

La clasificación "Done" se reserva para cambios revisados, integrados, probados y demostrados según la rúbrica.

## 6. Balance de acciones de mejora del Corte I (Taller 4)

Fuente: [docs/Restropectiva.md](docs/Restropectiva.md) y Discussions del Corte I:
- [Discussion #29 — Qué se hizo bien](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/29)
- [Discussion #30 — Qué se puede mejorar](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/30)
- [Discussion #31 — Qué acciones propones](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/31)

| Acción retro-action | Issue | Resultado | Estado |
| --- | --- | --- | --- |
| Integrar datos reales y completar selección de empresa, carga y OCR | [#32](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/32) | Modelo cloud documentado en PR #61; pantallas y persistencia móvil pendientes | Abierto |
| Integrar Flutter con Django REST | [#33](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/33) | Cliente HTTP del PR #51 integrado; endpoints reales y despliegue pendientes | Abierto |
| Mejorar trazabilidad con ramas y PR por incidencia | #34–#45 | Cada incidencia trabajada tiene rama y PR independiente; cierres incompletos | Parcial |
| Fortalecer pruebas automáticas | PR #54–#59 | Últimas ejecuciones CI de esas ramas exitosas; pruebas del incremento combinado pendientes | Parcial |

**Aprendizaje:** separar responsabilidades en MVVM y trabajar por PR mejora la auditabilidad; para afirmar la finalización de una HU hace falta integrar, revisar y demostrar la persistencia real, no solo ejecutar tests locales.

## 7. Adaptaciones y proyección para el Corte III

**Deuda técnica / Not Done:** completar la API Django REST y la conexión real con PostgreSQL/Firestore; pruebas de permisos; sincronización de identidad; funciones de empresa/documentos/OCR; consolidar PR de Santiago y el PR #61; automatizar build móvil y evidencia cloud.

**Próximos pasos priorizados:**
1. Resolver revisiones, dependencias y merge de #54–#59 y #61; estabilizar main.
2. Cerrar técnicamente #33: endpoints de autenticación y facturas, servicio HTTPS, pruebas de lectura/escritura desde Flutter.
3. Continuar #32: selección de empresa, carga XML/PDF/imágenes, cámara y OCR.
4. Añadir pruebas de integración, seguridad y persistencia en CI; actualizar backlog y Definition of Done según feedback del docente.

**Feedback del docente durante la Sprint Review:** PENDIENTE de registrar.

## 8. Evidencias y guion de sustentación (pendientes de adjuntar)

- Evidencia A — \`flutter analyze\`, \`flutter test\` y \`flutter build apk --release\` en main con commit visible.
- Evidencia B — App en Android: inicio de sesión, crear factura, envío, rechazo/aprobación y búsqueda.
- Evidencia C — Consola de nube: lectura/escritura de **la misma factura** originada desde la app, antes/después, con marcas temporales y reinicio.
- Evidencia D — Diagrama ER, diccionario de datos y estructura real de tablas/colecciones.
- Evidencia E — IAM/Firebase mostrando acceso de \`endiromero@gmail.com\` con mínimo privilegio.
- Evidencia F — Páginas de PR con comentarios de revisión aprobados y estado merged; Issue vinculado.
- Evidencia G — GitHub Discussion con dos intervenciones individuales, captura y enlaces.
- Evidencia H — Enlace al APK de GitHub Releases o video técnico de máximo 8 a 10 minutos si la sustentación es asincrónica.

Ver [guion y checklist](docs/taller7/GUIA_DEMO_Y_EVIDENCIAS.md) para el orden de pruebas y las verificaciones que faltan.

---

**Regla para el cierre:** actualizar enlaces y los campos PENDIENTE con evidencias reales, crear la discusión y recibir feedback; hacer commit y merge del reporte final mediante PR. El archivo no constituye una certificación de despliegue o de aprobación del profesor.
