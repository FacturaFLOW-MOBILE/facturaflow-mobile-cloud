import '../data/demo/demo_auth_repository.dart';
import '../data/demo/demo_invoice_repository.dart';
import '../data/remote/api_client.dart';
import '../data/remote/remote_repositories.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/invoice_repository.dart';
import 'app_config.dart';

/// Contenedor de dependencias: resuelve qué implementación de repositorio usar
/// según [AppConfig.demoMode].
///
/// Se construye una sola vez en `main()` y se inyecta con `Provider`, de modo
/// que ninguna vista conoce la clase concreta.
class Dependencies {
  Dependencies._({
    required this.config,
    required this.authRepository,
    required this.invoiceRepository,
    this.apiClient,
  });

  factory Dependencies({
    required AppConfig config,
    AuthRepository? auth,
    InvoiceRepository? invoices,
  }) {
    if (config.demoMode) {
      return Dependencies._(
        config: config,
        authRepository: auth ?? DemoAuthRepository(config: config),
        invoiceRepository: invoices ?? DemoInvoiceRepository(config: config),
      );
    }
    // Un único cliente HTTP compartido: el repositorio de autenticación
    // guarda en él el token que firmará también las llamadas de facturas.
    final api = ApiClient(config: config);
    return Dependencies._(
      config: config,
      authRepository: auth ?? RemoteAuthRepository(api),
      invoiceRepository: invoices ?? RemoteInvoiceRepository(api),
      apiClient: api,
    );
  }

  /// Dependencias en memoria y sin latencia, para pruebas de widget.
  factory Dependencies.forTests({AppConfig? config}) {
    final testConfig = config ?? AppConfig.test();
    return Dependencies(
      config: testConfig,
      auth: DemoAuthRepository(config: testConfig),
      invoices: DemoInvoiceRepository(config: testConfig),
    );
  }

  final AppConfig config;
  final AuthRepository authRepository;
  final InvoiceRepository invoiceRepository;

  /// Cliente HTTP compartido. Es `null` en modo demostración, donde no se
  /// hace ninguna llamada de red.
  final ApiClient? apiClient;
}
