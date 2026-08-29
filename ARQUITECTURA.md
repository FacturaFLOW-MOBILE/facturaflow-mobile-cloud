# FacturaFlow Mobile

Aplicación Flutter para **crear, revisar, aprobar y rechazar facturas** con dos
perfiles de trabajo: el usuario que emite y el contador que revisa.

Funciona **sin servidor** gracias al modo demostración: los repositorios se
resuelven contra implementaciones en memoria con datos de ejemplo.

---

## Índice

- [Arranque rápido](#arranque-rápido)
- [Cuentas de demostración](#cuentas-de-demostración)
- [Arquitectura MVVM](#arquitectura-mvvm)
- [Navegación](#navegación)
- [Roles y permisos](#roles-y-permisos)
- [Flujo de la factura](#flujo-de-la-factura)
- [Modo demostración y modo servidor](#modo-demostración-y-modo-servidor)
- [Pruebas](#pruebas)
- [Estructura de carpetas](#estructura-de-carpetas)
- [Historial y ramas Git](#historial-y-ramas-git)
- [Guía para el TECNO Spark 50](#guía-para-el-tecno-spark-50)

---

## Arranque rápido

```bash
flutter pub get
flutter run              # modo demostración (por defecto)
flutter test             # 79 pruebas
flutter analyze          # sin issues
```

Requisitos: Flutter 3.47+ / Dart 3.13+ (el proyecto usa *dot shorthands*,
*patterns* y *sealed classes* de Dart 3).

## Cuentas de demostración

Contraseña única: `demo1234`. En la pantalla de login basta con tocar la cuenta
para que se rellene el formulario.

| Correo                     | Rol           | Qué puede hacer                                  |
| -------------------------- | ------------- | ------------------------------------------------ |
| `ana@facturaflow.demo`     | Usuario emisor| Crear, editar, enviar y corregir sus facturas    |
| `carlos@facturaflow.demo`  | Contador      | Revisar la cola, aprobar y rechazar con motivo   |
| `lucia@facturaflow.demo`   | Administrador | Ambas cosas y ver todas las facturas             |

## Arquitectura MVVM

Tres capas, con dependencias siempre hacia abajo:

```
  View  ──observa──►  ViewModel  ──llama──►  Repository  ──►  Datos (demo/HTTP)
 (Widgets)          (ChangeNotifier)        (interfaz)
    │                     │                     │
 Sin lógica de       Sin widgets ni       Sin conocer la UI
 negocio             BuildContext
```

- **Model** — `lib/data/models/`: `Invoice`, `InvoiceItem`, `InvoiceEvent`,
  `AppUser`, `UserRole`, `InvoiceStatus`. Objetos inmutables que contienen las
  reglas de negocio (`validationErrors()`, `canBeReviewedBy()`, `approved()`…).
  Los importes se guardan en **centavos (`int`)** para evitar los errores de
  redondeo del `double`.
- **ViewModel** — `lib/viewmodels/`: extienden `BaseViewModel`
  (`ChangeNotifier`), que centraliza `busy/idle/error` y evita el clásico
  *notifyListeners after dispose*. Ningún ViewModel importa `material.dart`, por
  eso se prueban sin `WidgetTester`.
- **View** — `lib/views/`: solo pintan estado y enrutan eventos al ViewModel.
- **Repository** — `lib/data/repositories/`: interfaces. Las implementaciones
  viven en `lib/data/demo/` (memoria) y `lib/data/remote/` (HTTP, pendiente).

Errores como valor, no como excepción: toda la capa de datos devuelve
`Result<T>` (`Ok`/`Err`) con un `Failure` tipado
(`AuthFailure`, `PermissionFailure`, `ValidationFailure`, `NotFoundFailure`,
`NetworkFailure`, `ConfigFailure`). La UI muestra `failure.message` tal cual.

La inyección se hace con `provider`: `Dependencies` decide la implementación en
`main()` y `FacturaFlowApp` la publica; las vistas solo conocen la interfaz.

## Navegación

Rutas con nombre resueltas en `AppRouter.onGenerateRoute`
([lib/app/routes.dart](lib/app/routes.dart)):

| Ruta                | Pantalla            | Argumentos           | Devuelve al hacer *pop* |
| ------------------- | ------------------- | -------------------- | ----------------------- |
| `/`                 | `RootView` (guardia)| —                    | —                       |
| `/login`            | `LoginView`         | —                    | —                       |
| `/home`             | `HomeView`          | —                    | —                       |
| `/invoices/detail`  | `InvoiceDetailView` | `InvoiceDetailArgs`  | `true` si hubo cambios  |
| `/invoices/form`    | `InvoiceFormView`   | `InvoiceFormArgs`    | la `Invoice` guardada   |

- `RootView` es el **guardia de sesión**: muestra el splash mientras restaura la
  sesión y luego decide entre login y home; al cerrar sesión vuelve solo.
- Una ruta desconocida o sin argumentos no revienta: cae en una pantalla de
  error con botón para volver al inicio.
- El detalle usa `PopScope` para informar a la lista si debe recargarse.

## Roles y permisos

`UserRole` concentra las capacidades y `Invoice` las combina con el estado:

| Capacidad                          | Emisor | Contador | Administrador |
| ---------------------------------- | :----: | :------: | :-----------: |
| Crear / editar borradores propios  |   ✅   |    ❌    |      ✅       |
| Enviar a revisión                  |   ✅   |    ❌    |      ✅       |
| Aprobar / rechazar                 |   ❌   |    ✅    |      ✅       |
| Ver facturas de otros              |   ❌   |    ✅    |      ✅       |

Reglas adicionales que se aplican en el modelo *y* en el repositorio:

- Nadie revisa su **propia** factura (aplica también al administrador).
- Solo se edita en `borrador` o `rechazada`, y solo el emisor dueño.
- Solo se elimina en `borrador`.
- El rechazo **exige motivo**; queda guardado en la factura y en el historial.
- El número de factura es único.

## Flujo de la factura

```
   ┌──────────┐  enviar   ┌──────────┐  aprobar   ┌───────────┐
   │ Borrador │──────────►│ Enviada  │───────────►│ Aprobada  │  (final)
   └──────────┘           │(revisión)│            └───────────┘
        ▲                 └──────────┘
        │                       │ rechazar (con motivo)
        │      corregir         ▼
        └──────────────── ┌────────────┐
                          │ Rechazada  │
                          └────────────┘
```

Cada transición agrega un `InvoiceEvent` al historial (quién, cuándo, qué y con
qué comentario), que el detalle pinta como línea de tiempo.

## Modo demostración y modo servidor

```bash
# Demostración (por defecto): datos en memoria, sin red
flutter run

# Contra un backend real
flutter run --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=https://api.miempresa.com
```

En modo demostración:

- `DemoAuthRepository` y `DemoInvoiceRepository` guardan todo en memoria y
  simulan 350 ms de latencia para que la UI ejerza sus estados de carga.
- El set de datos incluye facturas en los cuatro estados.
- La app lo indica con una franja en la bandeja y con las cuentas del login.
- Los datos se reinician al cerrar la app.

El modo servidor está **cableado pero sin cliente HTTP**: `RemoteAuthRepository`
y `RemoteInvoiceRepository` devuelven un `Failure` explicando la situación, y en
[lib/data/remote/remote_repositories.dart](lib/data/remote/remote_repositories.dart)
está documentado el contrato de endpoints por implementar.

## Pruebas

```bash
flutter test                                  # todo
flutter test test/viewmodels                  # solo ViewModels
flutter test --coverage                       # con cobertura
```

79 pruebas repartidas en:

| Archivo                                            | Cubre                                            |
| -------------------------------------------------- | ------------------------------------------------ |
| `test/models/invoice_test.dart`                     | Totales, IVA, validación, permisos, transiciones, JSON |
| `test/core/formatters_test.dart`                    | Moneda, parseo de importes, fechas, porcentajes   |
| `test/data/demo_invoice_repository_test.dart`       | Permisos por rol, duplicados, aprobar/rechazar/reabrir/eliminar |
| `test/viewmodels/login_view_model_test.dart`        | Validación de formulario y sesión                 |
| `test/viewmodels/invoice_list_view_model_test.dart` | Ámbitos, filtros, búsqueda, contadores            |
| `test/viewmodels/invoice_form_view_model_test.dart` | Totales en vivo, guardar, guardar y enviar        |
| `test/viewmodels/invoice_detail_view_model_test.dart` | Acciones del flujo y auto-revisión bloqueada    |
| `test/widget_test.dart`                             | Login, bandeja por rol, aprobación y rechazo de punta a punta |

`test/helpers/fixtures.dart` trae `buildInvoice(...)` y un reloj fijo
(`testClock`), así ninguna prueba depende de la fecha real.

## Estructura de carpetas

```
lib/
├── main.dart                   # arranque: config + dependencias
├── app/                        # config, tema, rutas, contenedor de dependencias
├── core/                       # Result, Failure, Formatters
├── data/
│   ├── models/                 # Invoice, InvoiceItem, InvoiceEvent, AppUser, roles y estados
│   ├── repositories/           # interfaces (contratos)
│   ├── demo/                   # implementaciones en memoria + datos de ejemplo
│   └── remote/                 # implementaciones HTTP (pendientes)
├── viewmodels/                 # BaseViewModel + un ViewModel por pantalla
└── views/                      # widgets, sin lógica de negocio
    └── widgets/                # StatusChip, InvoiceCard, EmptyState
test/                           # espejo de lib/ + helpers/fixtures.dart
```

## Historial y ramas Git

El repositorio se construyó por funcionalidades, cada una en su rama y
fusionada en `main` sin *fast-forward* para que el grafo muestre el trabajo:

```bash
git log --oneline --graph --all     # ver el historial
git branch -a                       # ver las ramas
```

| Rama                          | Aporte                                        |
| ----------------------------- | --------------------------------------------- |
| `feature/arquitectura-base`   | Núcleo MVVM, `Result`/`Failure`, config        |
| `feature/modelo-facturas`     | Modelos, reglas de negocio y repositorios      |
| `feature/modo-demostracion`   | Datos e implementaciones en memoria            |
| `feature/navegacion-y-roles`  | Rutas, guardia de sesión, login y bandeja      |
| `feature/flujo-aprobacion`    | Formulario, detalle, aprobar/rechazar          |
| `feature/pruebas`             | Suite de pruebas                               |
| `docs/guia-dispositivo`       | README y guía del TECNO Spark 50               |

Las ramas se conservan tras la fusión; para seguir trabajando:

```bash
git switch -c feature/mi-cambio main
# ... trabajar ...
git commit -am "feat: descripción"
git switch main && git merge --no-ff feature/mi-cambio
```

## Guía para el TECNO Spark 50

Instrucciones completas de instalación en el dispositivo —opciones de
desarrollador, depuración USB o Wi‑Fi, APK y solución de problemas— en
[docs/guia_tecno_spark_50.md](docs/guia_tecno_spark_50.md).

Atajo si ya tienes el teléfono en modo desarrollador:

```bash
flutter devices
flutter run -d <id-del-dispositivo>
```
