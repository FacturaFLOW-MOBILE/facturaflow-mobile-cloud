# FacturaFlow Mobile Cloud

Aplicación móvil independiente para **capturar, cargar, validar, revisar y aprobar facturas** desde un dispositivo móvil. Proyecto académico de **Mobile Cloud Computing - IS0249 - 210**.

## Integrantes

| Integrante | GitHub | Historias asignadas |
|---|---|---|
| David Santiago Piedrahita Cabeza | @santkd16 | HU impares: 14 historias |
| Jhon | @jhon9036 | HU pares: 14 historias |

**Docente GitHub:** @endijromero

## Visión del producto

FacturaFlow Mobile Cloud permite que un usuario cargue una factura desde su celular mediante **XML, PDF, XLS o fotografía**. Cuando se usa una fotografía, la app aplica OCR para proponer los datos principales. Después, el usuario confirma o corrige la información y la envía a un contador, quien revisa el documento original y puede aprobar o rechazar la factura.

## Problema a resolver

La recepción y revisión manual de facturas puede generar errores de digitación, registros duplicados, pérdida de trazabilidad y demoras. El proyecto busca reducir esas tareas repetitivas mediante captura móvil, extracción de datos, validaciones, flujo de revisión y auditoría.

## Stack tecnológico

### Aplicación móvil
- Flutter
- Dart
- Material Design 3
- Arquitectura MVVM
- Cámara y selección de archivos
- Google ML Kit Text Recognition para OCR

### Backend
- Python
- Django
- Django REST Framework
- JWT para autenticación
- API REST

### Persistencia
- PostgreSQL 17
- Almacenamiento privado de XML, PDF, XLS e imágenes

### DevOps / Cloud
- GitHub y GitHub Projects
- GitHub Actions
- Backend desplegable como PaaS
- PostgreSQL administrado como servicio de base de datos
- Object Storage para documentos

## Arquitectura por capas

```text
Flutter Mobile
|
+-- Presentation
|   +-- Views
|   +-- ViewModels
|   +-- Widgets
|
+-- Domain
|   +-- Entities
|   +-- Use Cases
|   +-- Repository Contracts
|
+-- Data
|   +-- API Client
|   +-- Repository Implementations
|   +-- OCR / File Services
|
+-- Core
    +-- Config
    +-- Theme
    +-- Session
    +-- Secure Storage
            |
            v
       Django REST API
            |
      +-----+------+
      |            |
PostgreSQL 17   File Storage
```

## Flujo principal

```text
Login
  -> Seleccionar empresa
  -> Inicio
  -> Nueva factura
       -> XML / PDF / XLS
       -> Foto + OCR
  -> Extracción y validación
  -> Corrección manual
  -> Enviar al contador
  -> Pendiente de revisión
  -> Contador revisa
       -> Aprobar
       -> Rechazar con observación
  -> Auditoría y trazabilidad
```

## OCR

La captura mediante fotografía sigue este flujo:

```text
Cámara
 -> Imagen
 -> OCR
 -> Texto reconocido
 -> Normalización
 -> Número / NIT / proveedor / fecha / subtotal / IVA / total
 -> Confirmación manual
 -> Envío al contador
```

El OCR ayuda a extraer información, pero la fotografía no se considera por sí sola una validación de autenticidad fiscal. La revisión final corresponde al contador.

## Product Backlog

El repositorio contiene **28 historias de usuario**. Cada historia tiene **3 criterios de aceptación**.

**Distribución:**
- @santkd16: HU-01, HU-03, HU-05, HU-07, HU-09, HU-11, HU-13, HU-15, HU-17, HU-19, HU-21, HU-23, HU-25 y HU-27.
- @jhon9036: HU-02, HU-04, HU-06, HU-08, HU-10, HU-12, HU-14, HU-16, HU-18, HU-20, HU-22, HU-24, HU-26 y HU-28.

Para el **Sprint 1**, el equipo seleccionará como mínimo 6 historias por integrante, cumpliendo el requisito académico de distribución equitativa.

## Taller 1 - Inception y Product Backlog

Entregables cubiertos:
- Repositorio público del proyecto.
- Product Backlog en GitHub Issues.
- 28 historias de usuario con 3 criterios de aceptación cada una.
- Distribución 14/14 entre los integrantes.
- README/Pitch con visión, problema y stack tecnológico.

## Taller 2 - Diseño UX/UI y definición arquitectónica

Entregables:
- Prototipo interactivo navegable en Figma.
- Arquitectura MVVM.
- Servicios Cloud identificados y justificados.

**Figma:** https://www.figma.com/design/bt24H5ZbpFqQDB8WzfZNwF/Untitled

## Taller 3 - Esqueleto móvil y navegación básica

Objetivo del incremento:
- Estructura Flutter organizada por MVVM y capas.
- Vistas principales conectadas.
- Navegación entre pantallas.
- Código entregado mediante ramas y Pull Request.
- APK o App Bundle funcional para demostración.

Flujo Git recomendado:

```text
main
└── develop
    ├── feature/sprint-3-navigation
    ├── feature/ocr-camera
    └── feature/backend-api
```

Convención de commits:

```text
feat(mobile): ...
feat(api): ...
feat(ocr): ...
fix(...): ...
docs: ...
test(...): ...
```

## Configuración local

Requisitos:
- Git
- GitHub CLI
- Flutter SDK
- Android SDK / Android Studio
- Extensiones Flutter y Dart para Visual Studio Code
- Python
- PostgreSQL 17

Comandos de comprobación:

```powershell
git --version
gh --version
flutter doctor
python --version
psql --version
```

## PostgreSQL 17

Ejemplo de variables de entorno:

```env
DB_NAME=facturaflow
DB_USER=postgres
DB_PASSWORD=CAMBIAR_PASSWORD
DB_HOST=localhost
DB_PORT=5432
```

No se deben subir contraseñas reales ni el archivo `.env` al repositorio.

## Seguridad

- Autenticación JWT.
- Control de acceso por rol.
- Control de acceso por empresa.
- Documentos servidos mediante endpoints autenticados.
- Validación de formato y tamaño.
- Hash del documento para apoyar detección de duplicados.
- Auditoría de cargas, correcciones, revisiones, aprobaciones y rechazos.

## Estado actual

- [x] Repositorio creado
- [x] README/Pitch
- [x] 28 historias de usuario creadas
- [x] Prototipo Figma
- [x] Arquitectura MVVM definida
- [ ] @jhon9036 con permisos de colaborador suficientes para ser asignado formalmente
- [ ] Historias agregadas/organizadas en GitHub Project
- [ ] Código Flutter subido por rama y Pull Request
- [ ] Backend conectado a PostgreSQL 17
- [ ] OCR probado en dispositivo
- [ ] APK/App Bundle generado y probado

## Alcance

Proyecto académico. La solución busca demostrar captura, procesamiento, validación y revisión móvil de facturas. No reemplaza una plataforma oficial de facturación electrónica ni certifica por sí sola la autenticidad tributaria del documento.
