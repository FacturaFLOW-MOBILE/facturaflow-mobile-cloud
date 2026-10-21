# Borrador para GitHub Discussions — Sprint Review Corte II

**Este archivo es un borrador publicable, no una discusión ya creada.** Antes de publicarlo reemplazar los campos PENDIENTE por enlaces reales. Si la integración cloud sigue incompleta, mantener esa condición explícita.

## Discusión principal

**Categoría:** General (o Sprint Review, si existe)

**Título:** Sprint Review Corte II – Mobile Cloud Computing IS0276 – FacturaFLOW Mobile Cloud

### Resumen ejecutivo

Durante el Corte II desarrollamos y verificamos nuevas correcciones del flujo de facturas en Flutter: validaciones de NIT, búsqueda, formatos monetarios, datos demo, motivos de rechazo, duplicidad por NIT, reapertura, navegación y cliente HTTP. Mantuvimos una arquitectura MVVM con separación View–ViewModel–Repository y un repositorio único de GitHub.

El trabajo de Jhon correspondiente a Issues #40–#45 ya está integrado en main. El trabajo de Santiago correspondiente a Issues #34–#39 cuenta con ramas y PR independientes todavía pendientes de revisión y merge. El Taller 6 incluye el modelo PostgreSQL, ER, diccionario, backend Django y artefactos Firestore en el PR #61, actualmente abierto.

**Estado cloud:** el diseño y la evidencia de base documental están en el PR #61. La persistencia de extremo a extremo desde la app Flutter hacia la nube sigue **pendiente de demostración**; no debe registrarse como terminada hasta que se haga la prueba de creación, edición y lectura desde el cliente móvil.

### Matriz resumida de incrementos

| Responsabilidad | Issues | PR | Estado GitHub |
| --- | --- | --- | --- |
| Santiago — búsqueda, NIT, demo, moneda, intl, datos JSON | #34–#39 | [#54](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/54), [#55](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/55), [#56](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/56), [#57](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/57), [#58](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/58), [#59](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/59) | Abiertos hacia dev |
| Jhon — rechazo, duplicados, reapertura, HTTP, navegación, estilos | #40–#45 | [#47](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/47), [#48](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/48), [#46](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/46), [#51](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/51), [#50](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/50), [#49](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/49) | Fusionados a main |
| Taller 6 — ER, diccionario, Django, SQL y Firestore | Taller 6 | [#61](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/61) | Abierto hacia main |

### Modelo y persistencia cloud

Repositorio oficial: https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud  
Base del Taller 6: https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/tree/docs/taller-6-modelado-bd/docs/taller6

El modelo SQL contiene las entidades app_user, supplier, invoice, invoice_item, invoice_event y auth_session, con llaves y restricciones documentadas. La versión Firestore utiliza users, suppliers, invoices (subcolecciones items y events) y sessions.

**Proyecto cloud seleccionado para sustentación:** PENDIENTE de confirmar entre \`facturaflow-mcc-2026\` y \`facturaflow-mobile-cloud\`.  
**Acceso de endiromero@gmail.com:** PENDIENTE de verificar con evidencia IAM actual.  
**Video o prueba real de CRUD Flutter ↔ cloud:** PENDIENTE de adjuntar.

### Evidencias y entregables

- Documento consolidado: [SPRINT_REVIEW_CORTE2.md](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/blob/docs/taller-7-sprint-review-corte2/SPRINT_REVIEW_CORTE2.md). Actualizar URL a main tras su merge.
- APK / GitHub Release: PENDIENTE.
- Capturas de pruebas Flutter, app en Android, consola cloud y PR revisados: PENDIENTE.
- Demostración en video (si aplica): PENDIENTE.

### Definition of Done y adaptación

Los PR abiertos aún requieren code review y merge; la persistencia cloud móvil no se ha demostrado. El backlog de Corte III conservará las necesidades de [integración #32](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/32) y [backend #33](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/33), junto con pendientes surgidos de la Review.

Agradecemos observaciones del docente para priorizar las mejoras del siguiente corte.

---

## Comentario individual: Santiago (@santkd16) — BORRADOR, debe publicarlo Santiago

En el Corte II me encargué de los Issues #34–#39. Implementé mejoras de búsqueda de facturas por descripción y monto, validación del NIT, configuración de modo demo, lectura de formatos monetarios locales/estadounidenses, formateadores con intl y carga de datos desde JSON. Cada cambio se trabajó en una rama individual y se propuso mediante los PR [#54](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/54), [#55](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/55), [#56](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/56), [#57](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/57), [#58](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/58) y [#59](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/59).

A fecha de la preparación, mis PR todavía están abiertos. El Issue [#33](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/33) documenta la conexión pendiente entre Flutter y Django REST. En la sustentación mostraré [PENDIENTE: registrar capturas reales de mi demo y, si la API está operativa, el mismo registro persistido en cloud]. No afirmaré que una prueba local equivale a sincronización en nube.

Mi aporte a la retrospectiva fue mejorar la trazabilidad de tareas, ejecutar pruebas y orientar la aplicación hacia consumo de datos reales.

---

## Comentario individual: Jhon (@jhon9036) — BORRADOR, debe revisarlo y publicarlo Jhon personalmente

Durante el Corte II trabajé los Issues #40–#45: validación del motivo de rechazo, duplicidad de número por proveedor, eliminación del motivo al reabrir, cliente HTTP, navegación con go_router y design tokens. Estos cambios están reflejados en los PR [#47](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/47), [#48](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/48), [#46](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/46), [#51](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/51), [#50](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/50) y [#49](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/49), integrados en main.

También preparé en el [PR #61](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/61) el modelado de datos para PostgreSQL, diagrama ER, diccionario, modelos Django y artefactos de Cloud Firestore. Este PR se encuentra pendiente de revisión y cierre.

Durante la demostración mostraré [PENDIENTE: incorporar evidencia capturada personalmente, estado del despliegue y prueba móvil-cloud si está disponible]. En la siguiente iteración daré continuidad al Issue [#32](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/32).

---

**Nota:** Actualizar el cuerpo principal después de completar las revisiones/merges y adjuntar las capturas. Cada integrante debe intervenir con su propia cuenta para cumplir la calificación individual.
