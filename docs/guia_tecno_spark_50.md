# Guía de instalación en el TECNO Spark 50

Cómo ejecutar **FacturaFlow** en un TECNO Spark 50 (HiOS sobre Android). Los
menús de HiOS cambian ligeramente entre versiones; cuando no encuentres una
opción, usa el buscador de Ajustes.

---

## 1. Preparar el teléfono

### 1.1 Activar las Opciones de desarrollador

1. **Ajustes → Acerca del teléfono**.
2. Toca **7 veces** sobre **Número de compilación** (en algunas versiones está
   dentro de *Información del software*).
3. Ingresa tu PIN. Aparece «Ya eres desarrollador».

### 1.2 Activar la depuración USB

1. **Ajustes → Sistema → Opciones de desarrollador**
   (en HiOS a veces: *Ajustes → Ajustes adicionales → Opciones de desarrollador*).
2. Activa **Depuración por USB**.
3. Activa también **Instalar vía USB** y **Verificación de apps por USB: desactivado**.
   Sin estas dos, HiOS bloquea la instalación y `flutter run` falla con
   `INSTALL_FAILED_USER_RESTRICTED`.
4. Recomendado: **Permanecer activo** (la pantalla no se apaga mientras carga).

> TECNO exige a veces tener una **cuenta Google iniciada y conexión a internet**
> la primera vez que se activa «Instalar vía USB».

### 1.3 Conectar el cable

1. Conecta el teléfono al PC con un cable **de datos** (algunos cables solo
   cargan).
2. En la notificación de USB elige **Transferencia de archivos (MTP)**.
3. Acepta el diálogo **¿Permitir depuración USB?** y marca *Siempre permitir
   desde este equipo*.

---

## 2. Verificar que el PC ve el dispositivo

```bash
flutter devices
```

Debe aparecer algo como:

```
TECNO SPARK 50 (mobile) • ABCD1234567890 • android-arm64 • Android 15 (API 35)
```

Si no aparece:

```bash
flutter doctor -v          # ¿falta el Android SDK o aceptar licencias?
flutter doctor --android-licenses
adb kill-server && adb devices   # reinicia el puente ADB
```

---

## 3. Ejecutar la app

### Opción A — Desarrollo con hot reload (recomendada)

```bash
flutter pub get
flutter run -d <id-del-dispositivo>
```

Con la app corriendo: `r` = hot reload, `R` = hot restart, `q` = salir.

La app arranca en **modo demostración**: no necesita servidor ni internet.
Entra con `ana@facturaflow.demo` / `demo1234` (o toca la cuenta en el login).

### Opción B — Instalar un APK y usar el teléfono suelto

```bash
# APK de depuración (rápido de compilar, pesado)
flutter build apk --debug

# APK optimizado para el Spark 50 (ARM 64 bits, ~40 % más liviano)
flutter build apk --release --target-platform android-arm64
```

El archivo queda en:

```
build/app/outputs/flutter-apk/app-release.apk
```

Instálalo por cable:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

O cópialo al teléfono y ábrelo con el explorador de archivos; HiOS pedirá
permitir **instalar apps de fuentes desconocidas** para esa aplicación.

> El APK de *release* va firmado con la clave de depuración (así viene el
> proyecto). Sirve para pruebas y demostraciones, **no** para publicar en Play
> Store: para eso hay que configurar una firma propia en
> `android/app/build.gradle.kts`.

### Opción C — Depuración por Wi-Fi (sin cable)

Con Android 11 o superior, en Opciones de desarrollador:

1. Activa **Depuración inalámbrica → Vincular dispositivo con código**.
2. En el PC:

```bash
adb pair <ip>:<puerto-de-vinculación>    # pide el código de 6 dígitos
adb connect <ip>:<puerto>
flutter run -d <ip>:<puerto>
```

---

## 4. Apuntar a un servidor real

```bash
flutter run -d <dispositivo> \
  --dart-define=DEMO_MODE=false \
  --dart-define=API_BASE_URL=https://api.miempresa.com
```

Ten en cuenta que el cliente HTTP todavía no está implementado (ver
`lib/data/remote/remote_repositories.dart`): la app mostrará un mensaje
explicándolo en vez de fallar en silencio.

Si el backend corre en tu PC, el teléfono **no** llega por `localhost`; usa la
IP de tu equipo en la red local (`ipconfig`) y, si es HTTP plano, recuerda que
Android bloquea el tráfico sin TLS salvo que se configure
`networkSecurityConfig`.

---

## 5. Problemas frecuentes

| Síntoma | Causa y solución |
| --- | --- |
| `No devices found` | Cable de solo carga, o falta aceptar el diálogo de depuración USB. Cambia el modo USB a MTP. |
| `INSTALL_FAILED_USER_RESTRICTED` | Falta activar **Instalar vía USB** en Opciones de desarrollador (típico de HiOS). |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Ya hay una versión firmada distinta: `adb uninstall com.example.factura_flow_mobile`. |
| La app se cierra al minimizarla | Ahorro de batería de HiOS: **Ajustes → Batería → FacturaFlow → Sin restricciones**. |
| La instalación se queda «verificando» | Desactiva la verificación de apps por USB o quita temporalmente la protección de Play Protect. |
| `Gradle task assembleDebug failed` | Ejecuta `flutter clean && flutter pub get`; revisa que el JDK sea 17 (`flutter doctor -v`). |
| Texto o botones cortados | La bandeja y el formulario son desplazables; si persiste, baja el **tamaño de fuente** en Pantalla. |

---

## 6. Comprobación rápida en el dispositivo

Recorrido de 2 minutos para validar que todo funciona:

1. Entra como **Ana Torres** (emisor) → verás sus facturas, incluida una
   rechazada con el motivo visible.
2. Toca **Nueva**, llena número, proveedor y NIT, agrega un ítem y usa
   **Guardar y enviar a revisión**.
3. Cierra sesión desde el avatar (esquina superior derecha).
4. Entra como **Carlos Ruiz** (contador) → la factura recién creada aparece en
   **Por revisar**.
5. Ábrela y prueba **Rechazar**: sin motivo no deja continuar; con motivo la
   factura queda rechazada y el historial registra quién y cuándo.
6. Vuelve a entrar como Ana: la factura muestra el rechazo y el botón
   **Corregir** para volver a borrador.

Como los datos viven en memoria, cerrar la app por completo restablece el set de
demostración original.
