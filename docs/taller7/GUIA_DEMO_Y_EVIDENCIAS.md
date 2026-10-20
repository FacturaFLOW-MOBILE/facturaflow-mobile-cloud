# Taller 7 — Guion de Sprint Review, comandos y evidencias

**Repositorio oficial:** https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud  
**Fecha límite indicada en la guía:** 21/10/2026.  
**Documento principal:** [SPRINT_REVIEW_CORTE2.md](../../SPRINT_REVIEW_CORTE2.md).

> No confundir una demo en memoria con persistencia cloud. Para superar el Eje 2, una operación debe salir de Flutter y reflejarse en la misma base cloud del Taller 6. No publicar passwords, tokens, claves JSON de cuentas de servicio o .env.

## A. Preparación en Windows PowerShell

Ejecutar desde la copia oficial del repositorio (sin perder cambios locales):

~~~powershell
cd C:\PROYECTOS-FLUTTER\facturaflow-mobile-cloud
git status
git fetch origin --prune
git switch main
git pull --ff-only origin main
git log -1 --oneline
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter devices
~~~

Guardar captura del commit y del resultado real. Si hay cambios locales, resolverlos antes de cambiar de rama. Si el análisis o las pruebas fallan, registrar la falla en vez de marcar DoD completo.

## B. Auditoría y aprobación de PR

**PR propios de Santiago hacia dev:** [#54](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/54), [#55](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/55), [#56](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/56), [#57](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/57), [#58](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/58), [#59](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/59).

**Modelo del Taller 6:** [#61](https://github.com/FacturaFLOW-MOBILE/facturaflow-mobile-cloud/pull/61), realizado por Jhon hacia main.

1. Jhon revisa el código de #54–#59 y registra comentarios/APROBACIÓN reales. Santiago corrige los hallazgos.
2. Santiago revisa el #61, especialmente reglas de Firestore, autenticación, scripts destructivos y ausencia de endpoints Django; Jhon corrige los hallazgos.
3. Integrar los PR secuencialmente, volver a ejecutar CI y resolver conflictos: en especial el uso compartido de \`lib/core/formatters.dart\` en #57 y #58, y el efecto del #59 sobre datos demo y tests.
4. Después del merge a dev, integrar dev a main con revisión según el flujo acordado.
5. Capturar URL del PR, revisión \`APPROVED\`, merge commit, Issues relacionados y resultado CI.

El reporte no puede declarar una revisión inexistente; un comentario \`COMMENTED\` no equivale automáticamente a \`APPROVED\`.

## C. Demostración del incremento móvil

### En modo demo — valida interfaces, NO cloud

~~~powershell
flutter run -d chrome --dart-define=DEMO_MODE=true
~~~

Mostrar inicio de sesión, roles, creación de factura, búsqueda, edición, envío, aprobación/rechazo e historial. Registrar cuál Issue corrige cada flujo. En la rúbrica se solicita dispositivo físico o emulador; Chrome puede ayudar durante la preparación, pero no lo sustituye.

Para preparar una APK de demostración (requiere Android SDK completo):

~~~powershell
flutter build apk --release --dart-define=DEMO_MODE=true
Get-Item .\build\app\outputs\flutter-apk\app-release.apk
~~~

Probar la APK realmente en un dispositivo antes de publicarla en GitHub Releases. Documentar que es una APK **demo** si fue compilada con \`DEMO_MODE=true\`.

### En modo remoto — requisito cloud

Solo después de desplegar una API real compatible con las rutas Flutter, autenticación funcional y BD accesible:

~~~powershell
$API = 'https://REEMPLAZAR-CON-TU-API-REAL'
flutter run -d chrome --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=$API
~~~

**No ejecutar con una URL inventada:** la API debe responder realmente a autenticación y facturas. Para APK remota:

~~~powershell
flutter build apk --release --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=$API
~~~

Probar inicio de sesión, crear un registro de prueba con número identificable, consultar en la consola/BD, editarlo, recargar la app y comprobar persistencia. Registrar resultado y hora. Si no existe el backend, marcar este criterio incompleto.

## D. Prueba móvil-cloud y coherencia con el Taller 6

1. Identificar **un único proyecto cloud** y registrar su ID exacto: en el PR #61 figura \`facturaflow-mcc-2026\`; en las pruebas de preparación también se utilizó \`facturaflow-mobile-cloud\`. No mezclar capturas de dos proyectos.
2. Verificar el usuario docente \`endiromero@gmail.com\` en IAM/Firebase y capturar el permiso actual (mínimo privilegio).
3. Mostrar el ER, el diccionario y un registro con columnas/documentos coherentes.
4. Crear factura desde Flutter: conservar UID de usuario, NIT, número, estado y marca de tiempo.
5. Mostrar el mismo registro en base cloud, sus items y eventos.
6. Actualizar desde Flutter y consultar otra vez desde base cloud.
7. Reiniciar la app: verificar recuperación del estado guardado.
8. Tomar capturas con evidencia de **app y BD simultáneamente**, evitando exponer información personal o claves.

**Importante:** los scripts \`cargar_modelo.py\` y \`verificar_integracion.py\` del PR #61 pueden borrar datos. No ejecutarlos sobre una base compartida o con facturas reales.

## E. GitHub Discussion

Crear en el repositorio original, pestaña Discussions > New discussion > General.

**Título exacto:**

Sprint Review Corte II – Mobile Cloud Computing IS0276 – FacturaFLOW Mobile Cloud

Publicar el texto del archivo [BORRADOR_DISCUSSION.md](BORRADOR_DISCUSSION.md), completar los enlaces faltantes y publicar. Luego **cada integrante desde su propia cuenta** debe comentar sus responsabilidades y añadir capturas reales. No publicar un comentario en nombre del compañero.

Enlazar Discussion, archivo \`SPRINT_REVIEW_CORTE2.md\` de main, APK/Release o video en la descripción inicial.

## F. Guion oral sugerido (8–10 minutos si es video)

| Tiempo orientativo | Presenta | Acción demostrable |
| --- | --- | --- |
| 0:00–1:00 | Ambos | Objetivo Sprint Review, repositorio único, alcance y estado real |
| 1:00–3:00 | Santiago | Búsqueda, NIT, modo demo, importes, intl y JSON; explicar PR #54–#59 |
| 3:00–5:00 | Jhon | Rechazo, NIT/número, reapertura, navegación, diseño y cliente HTTP; PR #46–#51 |
| 5:00–7:00 | Ambos | Mostrar ER/diccionario y **lectura/escritura móvil-cloud si está funcional**; de lo contrario reconocer bloqueo |
| 7:00–8:30 | Ambos | Git Flow, revisiones aprobadas, merges, CI, Definition of Done |
| 8:30–10:00 | Ambos | Acciones de retrospectiva #32/#33, backlog Corte III, feedback y conclusiones |

La participación individual y la autenticidad de las capturas forman parte de la evaluación.

## G. Checklist antes de entregar

- [ ] El incremento está en main y muestra commit concreto.
- [ ] Análisis, tests y APK ejecutados; resultados reales adjuntos.
- [ ] PR de Santiago revisados y fusionados.
- [ ] PR #61 corregido, revisado y fusionado.
- [ ] Demostración Android en dispositivo o emulador.
- [ ] Base cloud real identificada, con escritura/lectura desde la app.
- [ ] Acceso docente verificado.
- [ ] Diagrama y diccionario del Taller 6 coinciden con la base demostrada.
- [ ] GitHub Discussion publicada; comentarios individuales de Santiago y Jhon.
- [ ] \`SPRINT_REVIEW_CORTE2.md\` actualizado, revisado y fusionado a main.
- [ ] APK en Releases o video con enlace público/no listado y todas las evidencias.
- [ ] Backlog de Corte III actualizado con pendientes sin falsos "Done".
