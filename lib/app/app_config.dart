/// Configuración de arranque de la aplicación.
///
/// El modo demostración permite ejecutar la app completa sin backend:
/// los repositorios se resuelven contra implementaciones en memoria.
///
/// Para apuntar a un servidor real:
///   flutter run --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=https://api.miempresa.com
class AppConfig {
  const AppConfig({
    required this.demoMode,
    required this.apiBaseUrl,
    this.simulatedLatency = const Duration(milliseconds: 350),
  });

  /// Configuración leída de los `--dart-define` del build.
  factory AppConfig.fromEnvironment() {
    const demo = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    return const AppConfig(demoMode: demo, apiBaseUrl: baseUrl);
  }

  /// Configuración para pruebas: sin latencia artificial.
  factory AppConfig.test() =>
      const AppConfig(demoMode: true, apiBaseUrl: '', simulatedLatency: Duration.zero);

  /// Si es `true` los datos viven en memoria y no se hace ninguna llamada de red.
  final bool demoMode;

  /// URL base del backend. Solo se usa cuando [demoMode] es `false`.
  final String apiBaseUrl;

  /// Retardo artificial de los repositorios demo, para que la UI muestre
  /// sus estados de carga igual que contra un servidor real.
  final Duration simulatedLatency;

  bool get hasApiBaseUrl => apiBaseUrl.isNotEmpty;
}
