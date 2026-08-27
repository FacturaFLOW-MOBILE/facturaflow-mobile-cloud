import '../data/demo/demo_auth_repository.dart';
import '../data/demo/demo_invoice_repository.dart';
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
  Dependencies({required this.config, AuthRepository? auth, InvoiceRepository? invoices})
      : authRepository = auth ??
            (config.demoMode
                ? DemoAuthRepository(config: config)
                : RemoteAuthRepository(config)),
        invoiceRepository = invoices ??
            (config.demoMode
                ? DemoInvoiceRepository(config: config)
                : RemoteInvoiceRepository(config));

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
}
