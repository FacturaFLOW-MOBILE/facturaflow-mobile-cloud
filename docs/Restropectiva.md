# RETROSPECTIVA CORTE I – FACTURAFLOW MOBILE CLOUD


### Integrantes
- David Santiago Piedrahita Cabeza – GitHub: @santkd16
- Jhon Vargas – GitHub: @jhon9036

---

## 1. Resumen de la retrospectiva

Durante el Corte I se trabajó en la evolución de FacturaFlow hacia una aplicación móvil desarrollada en Flutter. El proyecto tomó como referencia el sistema de facturación web desarrollado previamente en Django, reutilizando el análisis de requerimientos, historias de usuario, roles y procesos de facturación.

En el repositorio móvil se implementó una base funcional organizada con arquitectura MVVM. Actualmente la aplicación permite trabajar con tres perfiles: emisor, contador y administrador. El emisor puede crear, editar y enviar sus facturas; el contador puede revisar, aprobar o rechazar; y el administrador dispone de capacidades combinadas, manteniendo las restricciones definidas en las reglas de negocio.

Durante el corte también se implementaron navegación, control de sesión, estados de factura, historial de cambios, validaciones, control de duplicados y un modo demostración que permite ejecutar la aplicación sin depender todavía de un servidor.

La arquitectura contempla repositorios remotos para trabajar con un backend real. Sin embargo, la integración HTTP continúa pendiente, por lo cual esta necesidad se convirtió en una de las acciones prioritarias de mejora para el siguiente corte.

---

## 2. ¿Qué se hizo bien?

Uno de los principales aspectos positivos fue no iniciar la aplicación móvil desde cero. Se tomó como base el proyecto de facturación web previamente desarrollado y se conservaron los conceptos principales del sistema: usuarios, roles, facturas, validaciones, revisión, aprobación, rechazo y trazabilidad.

La aplicación móvil fue organizada con arquitectura MVVM, separando vistas, ViewModels, modelos y repositorios. Esta separación facilita el mantenimiento y las pruebas y permite cambiar posteriormente la fuente de datos sin tener que modificar directamente las interfaces.

También se implementó un flujo funcional de facturas. Una factura puede pasar de borrador a enviada para revisión y posteriormente ser aprobada o rechazada. Cuando se rechaza se exige un motivo y cada transición genera un evento en el historial.

Se trabajaron reglas de negocio importantes, entre ellas impedir que un usuario revise su propia factura, limitar la edición según el estado y el propietario, impedir números de factura duplicados y controlar las acciones permitidas según el rol.

Otro resultado importante fue la suite automatizada de 79 pruebas, que cubre modelos, formatos, repositorios de demostración, ViewModels y widgets. Además, el proyecto cuenta con documentación de arquitectura, estructura de carpetas, historial de ramas y una guía para ejecutar la aplicación en el dispositivo TECNO Spark 50.

---

## 3. ¿Qué se puede mejorar?

El principal aspecto por mejorar es la integración entre Flutter y el backend real. Actualmente el modo demostración funciona con repositorios en memoria y datos de ejemplo. El modo servidor está preparado en la arquitectura, pero el cliente HTTP todavía se encuentra pendiente.

También es necesario continuar el desarrollo de funcionalidades que hacen parte de la evolución planteada desde el sistema web, especialmente la conexión con datos reales, selección de empresa, carga de archivos, captura mediante cámara y OCR.

Otro aspecto identificado por el equipo es mejorar la planeación del alcance y la trazabilidad del backlog. Durante el proyecto se plantearon funcionalidades como OCR, carga de archivos, exportación, auditoría y conexión cloud, pero no todas podían completarse dentro del tiempo disponible del Corte I.

Para el siguiente corte se propone mantener una trazabilidad más clara mediante Issues, responsables, ramas y Pull Requests, de forma que cada acción de mejora pueda relacionarse con una evidencia concreta.

---

## 4. Acciones concretas propuestas

A partir de las Discussions de la retrospectiva se definieron dos acciones prioritarias.

La primera es conectar la aplicación con los datos reales y continuar las pantallas pendientes del prototipo. Esta acción fue registrada por Jhon Vargas en el Issue #32.

La segunda es implementar progresivamente la comunicación de Flutter con el backend Django REST para consultar y actualizar usuarios, empresas y facturas. Esta acción fue registrada por David Santiago Piedrahita Cabeza en el Issue #33.

Estas acciones permiten que el siguiente corte se concentre en pasar del modo demostración hacia una integración real, sin perder la arquitectura y los flujos ya construidos.

---

## 5. Tabla consolidada de acciones de mejora

| Acción | Responsable | Issue | Prioridad | Estado |
|---|---|---|---|---|
| Integración con la base de datos en la nube y pantallas pendientes del prototipo | Jhon Vargas (@jhon9036) | [#32](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/32) | Alta | Abierto |
| Integrar la aplicación Flutter con el backend Django REST | David Santiago Piedrahita Cabeza (@santkd16) | [#33](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/33) | Alta | Abierto |

---

## 6. Evidencias del Corte I

Las principales evidencias verificables en el repositorio son:

- Código fuente Flutter organizado en `lib/`.
- Arquitectura MVVM.
- Modelos de factura, ítems, eventos, usuarios, roles y estados.
- Repositorios para separar el acceso a datos.
- Modo demostración con información almacenada en memoria.
- Estructura preparada para repositorios remotos.
- Navegación mediante rutas.
- Guardia de sesión.
- Perfiles emisor, contador y administrador.
- Creación y edición de facturas.
- Envío de facturas a revisión.
- Aprobación y rechazo con motivo.
- Historial de eventos de la factura.
- Validación de permisos y reglas de negocio.
- Documentación `README.md`.
- Documentación técnica `ARQUITECTURA.md`.
- Guía de ejecución en TECNO Spark 50.
- Historial organizado mediante ramas funcionales.

---

## 7. Discussions de la retrospectiva

La retrospectiva se desarrolló mediante GitHub Discussions con participación de los integrantes del equipo.

### Discussion #29 – ¿Qué se hizo bien?
https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/29

En esta discusión se documentaron los aspectos positivos del Corte I, entre ellos la arquitectura MVVM, el flujo de facturas, roles, validaciones, pruebas automatizadas y la continuidad entre el sistema web original y la aplicación Flutter.

### Discussion #30 – ¿Qué se puede mejorar?
https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/30

Se identificaron como oportunidades de mejora la integración con el backend y la nube, el desarrollo de funcionalidades pendientes y una mejor planeación y trazabilidad del backlog.

### Discussion #31 – ¿Qué acciones propones?
https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/discussions/31

Se propuso avanzar hacia datos reales mediante la integración Flutter–backend, completar las pantallas pendientes y organizar las nuevas funcionalidades mediante Issues, responsables, ramas y Pull Requests.

---

## 8. Issues generados desde la retrospectiva

### Issue #32 – Integración con la base de datos en la nube y pantallas pendientes del prototipo

**Responsable:** @jhon9036  
**Estado:** Abierto  
**Tipo:** Feature  

La acción busca dejar de depender de los datos de ejemplo y avanzar en selección de empresa, carga de archivos y captura mediante cámara/OCR.

https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/32

### Issue #33 – Integrar la aplicación Flutter con el backend Django REST

**Responsable:** @santkd16  
**Estado:** Abierto  
**Tipo:** Feature  

La acción propone conectar progresivamente Flutter con la API REST de Django para consultar y actualizar información real de usuarios, empresas y facturas.

https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/issues/33

---

## 9. Arquitectura y estado actual

La aplicación utiliza una arquitectura MVVM con el siguiente flujo general:

```text
View
  ↓
ViewModel
  ↓
Repository
  ↓
Datos (Demo / HTTP)
```

Actualmente el modo demostración utiliza `DemoAuthRepository` y `DemoInvoiceRepository`, almacenando los datos en memoria. Esto permite ejecutar y demostrar los flujos principales sin servidor.

La estructura también contempla `RemoteAuthRepository` y `RemoteInvoiceRepository`. La implementación del cliente HTTP es una tarea pendiente y está directamente relacionada con las acciones definidas en los Issues #32 y #33.

---

## 10. Flujo actual de facturas

```text
Borrador
   ↓ enviar
Enviada / En revisión
   ├── aprobar → Aprobada
   └── rechazar → Rechazada
                     ↓ corregir
                  Borrador
```

Cada transición genera información para el historial y se aplican reglas de permisos según el rol y el propietario de la factura.

---

## 11. Relación con el siguiente corte

El Corte I permitió dejar una base móvil funcional y comprobable. Para el Corte II el objetivo de mejora identificado por el equipo es avanzar desde el modo demostración hacia una integración con servicios reales.

Las prioridades planteadas son:

1. Integrar Flutter con el backend Django REST.
2. Avanzar en la persistencia de información real/cloud.
3. Completar pantallas y funcionalidades pendientes del prototipo.
4. Mantener pruebas y evidencias para cada nueva funcionalidad.
5. Trabajar las mejoras mediante Issues, ramas y Pull Requests.

---

## 12. Conclusión

La retrospectiva permitió comprobar que el Corte I dejó una base organizada para FacturaFlow Mobile Cloud. Se cuenta con arquitectura MVVM, navegación, sesión, roles, reglas de negocio, flujo de aprobación y rechazo, historial y pruebas automatizadas.

Al mismo tiempo, se identificó claramente que la siguiente evolución del proyecto debe concentrarse en sustituir progresivamente los datos de demostración por una integración real con el backend y los servicios de datos.

Las acciones de mejora quedaron registradas en los Issues #32 y #33, con responsables definidos, lo que permite mantener trazabilidad entre la reflexión realizada en las Discussions y el trabajo propuesto para el siguiente corte.
