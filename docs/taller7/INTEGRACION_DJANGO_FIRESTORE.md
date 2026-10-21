# Issue #33 — Conexión Flutter → Django → Google Cloud Firestore

Proyecto confirmado: `facturaflow-mcc-2026`, base `(default)`; documentos actuales `invoices`, `users`, `suppliers`, `sessions`. La consulta Python de `830998877-3_FE-2001` funcionó. Este PR implementa los endpoints existentes de `lib/data/remote/remote_repositories.dart`, **sin Firebase SDK ni Firebase Authentication en Flutter**.

## Importante antes de comenzar

**Google Cloud tiene `billingEnabled: false`**. Puedes probar Flutter en tu TECNO KN8 con Django ejecutándose en el PC, aunque las facturas persisten en Firestore cloud. **Para que el móvil funcione desde cualquier lugar con el PC apagado, falta desplegar Django en una URL HTTPS (por ejemplo Cloud Run, que requiere facturación habilitada).** No declarar ese paso como completado sin una URL real.

Este backend está separado del antiguo backend PostgreSQL del PR #61. No ejecutes `migrate` ni `docs/taller6/firestore/cargar_modelo.py`: el último script borra colecciones antes de cargar datos de demostración.

## 1. Abrir esta rama en el PC (PowerShell)

```powershell
cd C:\PROYECTOS-FLUTTER\facturaflow-mobile-cloud
git status
git stash list
git fetch origin --prune
git switch -c santiago/issue-33-django-firestore origin/santiago/issue-33-django-firestore
```

Si la rama ya existe localmente: `git switch santiago/issue-33-django-firestore` y `git pull --ff-only origin santiago/issue-33-django-firestore`. No borrar los tres stashes existentes ni hacer `git reset --hard`.

## 2. Instalar dependencias Python en entorno aislado

```powershell
py -3.12 -m venv backend\.venv
.\backend\.venv\Scripts\python.exe -m pip install -r backend\requirements_firestore.txt
Copy-Item backend\.env.firestore.example backend\.env.firestore
```

El archivo `backend/.env.firestore` ya incluye el proyecto correcto y `DJANGO_DEBUG=true`. **No subir archivos `.env` ni ADC a GitHub**. ADC fue configurado previamente mediante `gcloud auth application-default login`.

## 3. Crear contraseña de FacturaFLOW para un usuario existente

Los perfiles `users/u-ana`, `users/u-carlos`, `users/u-lucia` son datos de ejemplo y todavía no son cuentas de login. El siguiente comando agrega **solo un hash de contraseña** en la colección privada `credentials/u-ana`, sin borrar ninguna factura ni cambiar el perfil:

```powershell
.\backend\.venv\Scripts\python.exe backend\crear_usuario_firestore.py --id u-ana --email ana@facturaflow.demo
```

El script pedirá una contraseña nueva y su confirmación (mínimo 12 caracteres). Para crear usuarios nuevos puedes usar `--email usuario@dominio.com --name "Usuario Prueba" --role emisor` (sin `--id`). Los usuarios nuevos no pueden ver facturas de otros emisores. Para los otros perfiles demo, proporcionar sus respectivos IDs y correos existentes.

## 4. Iniciar Django (PowerShell 1)

```powershell
.\backend\.venv\Scripts\python.exe backend\manage_firestore.py check
.\backend\.venv\Scripts\python.exe backend\manage_firestore.py test cloud_api --verbosity 2
.\backend\.venv\Scripts\python.exe backend\manage_firestore.py runserver 127.0.0.1:8000
```

Dejar esa ventana abierta. En otra ventana:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

Se espera `status=ok`, `database=connected` y `project=facturaflow-mcc-2026`. Si aparece un error `403`, revisar IAM del usuario con que se ejecuta ADC; no ejecutar cambios destructivos.

## 5. Conectar Android por USB al Django local (PowerShell 2)

La forma más fiable en TECNO KN8 es `adb reverse` (Android puerto 8000 hacia tu PC puerto 8000). **El cable USB y el servidor Django deben permanecer conectados durante esta prueba**:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
& $adb -s 1638515626004918 reverse tcp:8000 tcp:8000

flutter pub get
flutter analyze
flutter test
flutter run -d 1638515626004918 --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Iniciar sesión con correo y contraseña creados en el paso 3 (no la contraseña de Google). **El manifiesto Android permite HTTP solo para debug**. Para una APK release definitiva se exige HTTPS y servidor publicado.

## 6. Evidencias reales para el Taller 7

1. Iniciar sesión en Android con el emisor.
2. Consultar sus facturas en `/invoices`.
3. Crear una factura de prueba con NIT y número únicos, por ejemplo `FE-3001`.
4. Abrir Google Cloud Console → Firestore `(default)` → `invoices` y verificar el documento `{NIT}_{numero}` y sus subcolecciones `items` y `events`.
5. Cerrar/reabrir la app y comprobar que el registro persiste.
6. Enviar factura a revisión. Iniciar sesión con otro usuario rol contador; aprobar/rechazar y verificar el estado y la bitácora.
7. Guardar capturas con fecha, ID de factura, URL de PR, salida de pruebas y app Android.

**Nota:** número y NIT de una factura creada no se pueden renombrar en esta API porque constituyen la clave del documento. La API sí permite editar notas, fecha e ítems mientras esté en estado editable.

## 7. Publicación pública pendiente

Para ejecutar Django con el PC apagado necesitas vincular facturación del proyecto, un servidor público HTTPS y una identidad IAM del servidor con permisos mínimos para Firestore. Se incluye `backend/Dockerfile` como base de despliegue futura, pero **no** se despliega Cloud Run ni se activa facturación automáticamente. En producción usar `DJANGO_DEBUG=false`, `DJANGO_SECRET_KEY` único, el host válido en `DJANGO_ALLOWED_HOSTS`, rate limiting de login, control de costos y credenciales de identidad de servicio, no ADC personales. El comando de compilación release será:

```powershell
flutter build apk --release --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=https://URL-REAL-DE-DJANGO
```

## Seguridad

La biblioteca de Firestore para servidor Python opera con IAM y **no evalúa Firestore Security Rules**. Django valida roles, propietarios y cambios de estado. Los hashes de claves se guardan en `credentials` (separados de perfiles `users`); las sesiones almacenan un hash del token, no el token original. Revisión de seguridad y pruebas de integración sobre una BD de ensayo son indispensables antes de un despliegue público.

