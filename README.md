# 📱 FacturaFlow Mobile Cloud

FacturaFlow Mobile Cloud es una solución académica para la **gestión, procesamiento, validación y revisión de facturas**, desarrollada como extensión móvil de un sistema de facturación construido previamente con Django.

El proyecto integra una aplicación móvil en **Flutter**, una API en **Django REST Framework**, una base de datos **PostgreSQL 17** y procesamiento documental para archivos **XML, PDF, XLS e imágenes**. Además, incorpora captura mediante cámara y reconocimiento de texto **OCR** para apoyar la extracción de información desde facturas fotografiadas.

---

## 👥 Integrantes

- **David Santiago Piedrahita Cabeza** — GitHub: `@santkd16`
- **Jhon** — GitHub: `@jhon9036`

**Docente GitHub:** `@endijromero`

---

# 🎯 Visión del proyecto

FacturaFlow Mobile Cloud busca facilitar el registro y revisión de facturas desde un dispositivo móvil, reduciendo la digitación manual y mejorando la trazabilidad de los documentos.

La solución permite que un usuario pueda cargar una factura, tomar una fotografía, revisar la información extraída, corregir errores y enviarla a un contador para su aprobación o rechazo.

---

# 📌 Problema

Muchas empresas gestionan facturas de forma manual. Esto puede ocasionar:

- Errores de digitación.
- Duplicidad de registros.
- Pérdida de información.
- Retrasos en procesos administrativos y contables.
- Dificultad para organizar documentos.
- Poca trazabilidad sobre cambios y responsables.
- Mayor tiempo invertido en tareas repetitivas.

FacturaFlow busca automatizar parte de este proceso y centralizar la información asociada a los documentos de facturación.

---

# ❓ Pregunta problema

¿Cómo desarrollar un sistema de software que permita automatizar el procesamiento y la gestión de facturas, mejorando la eficiencia y reduciendo errores en el manejo de la información?

---

# 🎯 Objetivo general

Desarrollar una solución que permita registrar, procesar y gestionar facturas de forma automatizada, reduciendo errores y mejorando la eficiencia en el manejo de la información.

---

# ✅ Objetivos específicos

- Diseñar la arquitectura del sistema y su modelo de datos.
- Implementar la gestión de facturas.
- Permitir la creación, consulta, edición y listado de registros.
- Implementar procesamiento básico de documentos.
- Extraer campos principales de las facturas.
- Validar información antes de almacenarla.
- Mantener usuarios y roles.
- Almacenar información en PostgreSQL 17.
- Incorporar captura móvil mediante cámara.
- Incorporar OCR para facturas fotografiadas.
- Mantener trazabilidad y auditoría.
- Documentar instalación, uso y pruebas.
- Integrar la aplicación móvil con una API REST.

---

# 🚀 Funcionalidades principales

## 👤 Usuarios y autenticación

- Inicio de sesión.
- Cierre de sesión.
- Gestión de usuarios.
- Roles.
- Permisos.
- Acceso según rol.
- Control de acceso por empresa.

## 🏢 Empresas

- Consultar empresas autorizadas.
- Seleccionar empresa activa.
- Mantener la empresa seleccionada durante la sesión.
- Restringir el acceso a empresas no autorizadas.

## 🧾 Gestión de facturas

- Registro manual.
- Consulta.
- Edición.
- Listado.
- Detalle de factura.
- Estados.
- Búsqueda.
- Filtros.
- Asociación con proveedor.
- Validación de valores.
- Aprobación y rechazo.

## 📂 Carga de documentos

El sistema contempla carga de:

- XML.
- PDF.
- XLS.
- Imágenes.

Antes de procesar un documento se valida:

- Tipo de archivo.
- Tamaño.
- Usuario responsable.
- Empresa.
- Estado del documento.

Los documentos originales deben mantenerse protegidos y ser accesibles únicamente por usuarios autorizados.

---

# 📷 Cámara y OCR

La aplicación móvil permite tomar una fotografía de una factura utilizando la cámara del dispositivo.

Flujo de OCR:

```text
Cámara
   ↓
Fotografía
   ↓
OCR
   ↓
Texto reconocido
   ↓
Normalización
   ↓
Extracción de datos
   ↓
Validación
   ↓
Corrección manual
```

El OCR intenta identificar datos como:

- Número de factura.
- NIT.
- Proveedor.
- Razón social.
- Fecha.
- Subtotal.
- IVA.
- Total.

Los datos obtenidos mediante OCR deben ser revisados por el usuario antes de guardarse o enviarse.

---

# 🔎 Extracción de información

El procesamiento documental intenta extraer:

```text
Número de factura
Fecha
Emisor
NIT
Proveedor
Subtotal
IVA
Total
```

Cuando un campo no puede obtenerse automáticamente, queda disponible para corrección manual.

---

# ✏️ Corrección manual

Los usuarios pueden corregir los campos extraídos antes de guardar o enviar una factura.

Cada corrección relevante debe quedar disponible para trazabilidad.

---

# ✅ Validaciones

## Validación de campos obligatorios

El sistema verifica que existan los datos mínimos requeridos.

## Validación de valores

Se valida la relación:

```text
Subtotal + IVA ≈ Total
```

Cuando existe una inconsistencia, el sistema informa al usuario antes de continuar.

## Detección de duplicados

El sistema puede detectar posibles documentos repetidos mediante:

- Número de factura.
- NIT.
- Emisor.
- Fecha.
- Hash del archivo.

Para los archivos originales puede utilizarse un hash:

```text
SHA-256
```

Una coincidencia debe generar una advertencia para revisión.

---

# 🔄 Estados de procesamiento

Una factura puede pasar por estados como:

```text
Pendiente
Procesando
Procesada
Pendiente de revisión
Aprobada
Rechazada
Error
```

Si un proceso falla, el usuario puede consultar la causa y realizar un nuevo intento.

---

# 👨‍💼 Flujo del contador

El contador puede consultar una bandeja de facturas pendientes.

Puede revisar:

- Número de factura.
- Proveedor.
- Empresa.
- Fecha.
- Total.
- Documento original.
- Resultado de validaciones.
- Estado.

Después de revisar puede:

```text
Aprobar
```

o:

```text
Rechazar
```

Cuando rechaza una factura debe indicar una observación o motivo.

---

# 📊 Consultas y filtros

Las facturas pueden consultarse y filtrarse por:

- Fecha.
- Emisor.
- NIT.
- Proveedor.
- Estado.
- Empresa.

El sistema también contempla exportación de resultados a:

```text
CSV
Excel
```

---

# 🧾 Auditoría y trazabilidad

La aplicación registra acciones importantes como:

- Carga de documentos.
- Procesamiento.
- Correcciones.
- Cambios de estado.
- Reintentos.
- Aprobaciones.
- Rechazos.

Información registrada:

```text
Usuario
Fecha
Hora
Módulo
Acción
Factura
Observación
```

---

# 📱 Flujo principal de la aplicación

```text
Login
  ↓
Seleccionar empresa
  ↓
Panel principal
  ↓
Nueva factura
  ↓
┌─────────┬─────────┬─────────┬──────────┐
│   XML   │   PDF   │   XLS   │   FOTO   │
└─────────┴─────────┴─────────┴──────────┘
                                  ↓
                                 OCR
                                  ↓
                        Extracción de datos
                                  ↓
                             Validación
                                  ↓
                         Corrección manual
                                  ↓
                        Enviar al contador
                                  ↓
                       Pendiente de revisión
                                  ↓
                          Revisión contador
                              ↙       ↘
                         Aprobar     Rechazar
```

---

# 🛠️ Stack tecnológico

## Mobile

- Flutter.
- Dart.
- Material Design.
- Arquitectura MVVM.
- Cámara del dispositivo.
- Selector de archivos.
- OCR.

## Backend

- Python.
- Django.
- Django REST Framework.
- API REST.
- JWT.

## Base de datos

- PostgreSQL 17.

## Procesamiento documental

- XML.
- PDF.
- XLS.
- OCR.
- Validaciones.
- Hash SHA-256.

## Herramientas

- Visual Studio Code.
- Git.
- GitHub.
- GitHub Projects.
- Figma.
- Docker.

---

# 🏗️ Arquitectura

La aplicación móvil utiliza el patrón **MVVM**.

```text
View (Flutter)
      ↓
ViewModel
      ↓
Domain
      ↓
Repository
      ↓
Django REST API
      ↓
PostgreSQL 17
```

Flutter se encarga de la experiencia móvil.

Django concentra:

- Reglas de negocio.
- Validaciones.
- Autenticación.
- Permisos.
- Procesamiento documental.
- Persistencia.
- Auditoría.

---

# ☁️ Arquitectura Cloud

```text
Flutter Mobile
       ↓
    Internet
       ↓
Django REST API
      PaaS
       ↓
PostgreSQL
   DBaaS / PaaS
       ↓
Object Storage
```

Servicios previstos:

- **PaaS:** backend Django REST.
- **DBaaS/PaaS:** PostgreSQL administrado.
- **Object Storage:** XML, PDF, XLS, JPG y PNG.
- **GitHub:** código, Issues, Pull Requests, Product Backlog y evidencias.

---

# 📂 Estructura general del proyecto

```text
facturaflow-mobile-cloud/
│
├── mobile/
│   └── Aplicación Flutter
│
├── backend/
│   └── API Django REST
│
├── docs/
│   └── Documentación
│
├── .github/
│   └── Configuración GitHub
│
├── .env.example
├── .gitignore
└── README.md
```

La estructura se mantiene simple para facilitar desarrollo, mantenimiento y sustentación.

---

# 📱 Estructura Flutter

```text
mobile/
│
├── lib/
│   ├── core/
│   ├── data/
│   ├── domain/
│   ├── presentation/
│   └── main.dart
│
├── android/
├── test/
└── pubspec.yaml
```

## Core

```text
core/
├── config/
├── constants/
├── network/
├── routes/
├── session/
└── theme/
```

## Data

```text
data/
├── datasources/
├── repositories/
└── services/
```

## Domain

```text
domain/
├── entities/
├── repositories/
└── usecases/
```

## Presentation

```text
presentation/
├── views/
├── viewmodels/
└── widgets/
```

---

# 🌐 Estructura Backend

```text
backend/
│
├── accounts/
├── companies/
├── invoices/
├── services/
├── config/
├── requirements.txt
└── manage.py
```

## Accounts

Gestiona usuarios, roles, autenticación, JWT y permisos.

## Companies

Gestiona empresas, accesos y usuarios por empresa.

## Invoices

Gestiona facturas, proveedores, documentos, procesamiento, estados, detalles y auditoría.

## Services

Contiene lógica especializada:

```text
OCR
XML Parser
PDF Parser
Validaciones
Hash
Duplicados
Normalización
```

---

# 🗄️ Modelo de datos

Principales entidades:

```text
Usuario
Empresa
Proveedor
DocumentoCargado
ProcesamientoDocumento
ResultadoExtraccion
Factura
DetalleFactura
Auditoria
```

Relación conceptual:

```text
Usuario
   │
   └── DocumentoCargado
             │
             ▼
      ProcesamientoDocumento
             │
             ▼
       ResultadoExtraccion
             │
             ▼
          Factura
          /             ▼      ▼
  Proveedor  DetalleFactura
             │
             ▼
          Auditoria
```

---

# 🧩 Requerimientos funcionales principales

- RF-01 Autenticación.
- RF-02 Usuarios y roles.
- RF-03 Registro manual.
- RF-04 Carga PDF/XML/XLS.
- RF-05 Extracción de campos.
- RF-06 Validación de información.
- RF-07 CRUD de facturas.
- RF-08 Búsqueda y filtros.
- RF-09 Metadatos.
- RF-10 Documentación y pruebas.
- RF-11 Corrección manual.
- RF-12 Documento original.
- RF-13 Estado de procesamiento.
- RF-14 Reintentos.
- RF-15 Duplicados.
- RF-16 Validación subtotal/IVA/total.
- RF-17 Reglas mínimas de validación.
- RF-18 Proveedores.
- RF-19 Exportación CSV/Excel.
- RF-20 Filtros de procesamiento.
- RF-21 Auditoría.

La aplicación móvil extiende estos requerimientos con:

- Captura mediante cámara.
- OCR.
- Flujo móvil de revisión.
- Envío al contador.
- Aprobación/rechazo desde móvil.
- Notificaciones como mejora futura.

---

# 🛡️ Requerimientos no funcionales relevantes

- Interfaz responsive / mobile-first.
- Control de acceso por usuario y rol.
- Información privada protegida.
- Código organizado y mantenible.
- Trazabilidad básica.
- Validación de archivos.
- Archivos originales no públicos.
- Hash para detección de duplicados.
- Historial de correcciones.
- Separación entre procesamiento y vistas.
- Mensajes entendibles para errores y validaciones.
- Configuración mediante variables de entorno.
- Compatibilidad con entorno de desarrollo local.

---

# 📋 Product Backlog

Las historias de usuario se administran mediante **GitHub Issues**.

Formato:

```text
Como [perfil]
quiero [acción]
para [beneficio].
```

El backlog cubre:

- Autenticación.
- Usuarios.
- Roles.
- Empresas.
- Registro manual.
- Carga XML/PDF/XLS.
- OCR.
- Extracción.
- Correcciones.
- CRUD.
- Filtros.
- Estados.
- Reintentos.
- Duplicados.
- Proveedores.
- Exportación.
- Auditoría.
- Envío al contador.
- Bandeja del contador.
- Aprobación.
- Rechazo.
- Notificaciones.

---

# 🏃 Metodología

El proyecto utiliza **Scrum**.

Elementos principales:

```text
Product Backlog
Sprint Backlog
Historias de Usuario
Incremento
Definition of Done
```

Herramientas:

```text
GitHub Issues
GitHub Projects
Pull Requests
```

---

# 📊 Kanban

```text
Backlog
   ↓
Ready
   ↓
In Progress
   ↓
In Review
   ↓
Done
```

---

# 🔀 Git

Flujo recomendado:

```text
main
│
└── develop
     │
     ├── feature/mobile-navigation
     ├── feature/ocr-camera
     ├── feature/backend-api
     ├── feature/invoice-validation
     └── feature/database
```

Convención de commits:

```text
feat(mobile): implement invoice screen
feat(ocr): add invoice camera recognition
feat(api): add invoice endpoints
feat(database): add invoice models
fix(validation): correct invoice totals
docs: update README
test(api): add invoice tests
```

---

# 🧪 Pruebas

El proyecto contempla pruebas sobre:

- Inicio de sesión.
- Roles.
- Permisos.
- Empresas.
- Carga de XML.
- Carga de PDF.
- Carga de XLS.
- Cámara.
- OCR.
- Extracción.
- Corrección.
- Validaciones.
- Duplicados.
- Estados.
- Proveedores.
- Consultas.
- Exportación.
- Aprobación.
- Rechazo.
- Auditoría.

El proyecto original incluye pruebas de caja negra y caja blanca.

---

# 🔐 Seguridad

- Autenticación JWT.
- Roles.
- Permisos.
- Acceso por empresa.
- Validación de archivos.
- Documentos privados.
- Endpoints autenticados.
- Variables de entorno.
- Hash de documentos.
- Auditoría.

No deben almacenarse contraseñas ni secretos reales en GitHub.

---

# ⚙️ Requisitos de desarrollo

```text
Flutter
Dart
Android SDK
Visual Studio Code
Python
PostgreSQL 17
Git
GitHub CLI
```

Verificar:

```bash
flutter doctor
python --version
psql --version
```

---

# 📱 Ejecución Flutter

```bash
flutter pub get
flutter run
```

Compilar APK:

```bash
flutter build apk --release
```

Compilar App Bundle:

```bash
flutter build appbundle --release
```

---

# 🌐 Ejecución Django

Crear entorno virtual:

```bash
python -m venv venv
```

Activar en Windows:

```powershell
.\venv\Scripts\Activate.ps1
```

Instalar dependencias:

```bash
pip install -r requirements.txt
```

Migraciones:

```bash
python manage.py makemigrations
python manage.py migrate
```

Servidor:

```bash
python manage.py runserver
```

---

# 🗃️ PostgreSQL 17

```env
DB_NAME=facturaflow
DB_USER=postgres
DB_PASSWORD=TU_PASSWORD
DB_HOST=localhost
DB_PORT=5432
```

El archivo `.env` real no debe subirse al repositorio.

---

# 🔗 Comunicación Flutter - Django

```text
Flutter
   ↓
HTTP
   ↓
Django REST API
   ↓
PostgreSQL 17
```

En emulador Android puede utilizarse:

```text
http://10.0.2.2:8000/api/
```

---

# 📡 API propuesta

```text
/api/auth/
/api/companies/
/api/invoices/
/api/documents/
/api/providers/
/api/audit/
```

Ejemplos:

```text
POST /api/auth/login/
GET  /api/companies/
GET  /api/invoices/
POST /api/invoices/
POST /api/documents/
GET  /api/invoices/{id}/
POST /api/invoices/{id}/approve/
POST /api/invoices/{id}/reject/
```

---

# 🎨 Diseño UI/UX

**Figma**

https://www.figma.com/design/bt24H5ZbpFqQDB8WzfZNwF/Untitled

Pantallas principales:

```text
Login
Seleccionar empresa
Inicio
Nueva factura
Cargar XML
Tomar foto
Validar factura
Factura enviada
Pendientes contador
Revisar factura
Factura aprobada
Factura rechazada
```

---

# 📚 Entregables académicos

## Sprint 1 - Inception del proyecto y Product Backlog

- Product Backlog.
- Historias de usuario.
- 6 historias asignadas por integrante.
- 3 criterios de aceptación por historia.
- GitHub Project.
- README/Pitch.
- Visión.
- Problema.
- Stack tecnológico.

## Sprint 2 - Diseño UX/UI y definición arquitectónica

- Prototipo interactivo navegable.
- Flujo principal del usuario.
- Arquitectura MVVM.
- Servicios Cloud.
- Evidencia Kanban.

## Sprint 3 - Esqueleto móvil y navegación básica

- Código fuente mediante Pull Request.
- Estructura de carpetas.
- Vistas conectadas.
- Navegación.
- APK o App Bundle.
- Commits descriptivos.
- Ramas.
- Demostración en dispositivo o emulador.

---

# 📦 APK

```bash
flutter build apk --release
```

Ruta habitual:

```text
build/app/outputs/flutter-apk/app-release.apk
```

App Bundle:

```bash
flutter build appbundle --release
```

---

# 📌 Repositorio

https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud

---

# 🎓 Información académica

**Programa:** Ingeniería de Sistemas  
**Asignatura:** Mobile Cloud Computing - IS0249 - 210  
**Proyecto:** FacturaFlow Mobile Cloud

---

# ⚠️ Alcance

FacturaFlow Mobile Cloud corresponde a un **prototipo académico**.

El proyecto busca demostrar:

- Análisis.
- Diseño.
- Desarrollo.
- Procesamiento documental.
- Validación.
- Arquitectura móvil.
- Integración Mobile + Cloud.
- Pruebas.
- Trazabilidad.

No incluye:

- Facturación electrónica oficial.
- Integración directa con plataformas tributarias.
- Firma electrónica.
- Certificación fiscal.
- Automatización contable completa.
- Seguridad empresarial avanzada.
- Procesamiento masivo productivo.

El OCR se utiliza como herramienta de extracción de información y no como mecanismo para certificar la autenticidad fiscal de una factura.

---

# 📖 Referencias del proyecto

El proyecto se fundamenta en conceptos y documentación relacionados con:

- Django.
- Ingeniería de requisitos.
- UML.
- Scrum.
- Ingeniería de software.
- Modelado entidad-relación.
- Pruebas de software.
- Arquitectura MVVM.
- Mobile Cloud Computing.
