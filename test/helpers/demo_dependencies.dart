import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/app/dependencies.dart';
import 'package:factura_flow_mobile/data/demo/demo_auth_repository.dart';
import 'package:factura_flow_mobile/data/demo/demo_invoice_repository.dart';
import 'package:factura_flow_mobile/data/demo/demo_seed.dart';

/// Carga el asset real antes de entrar al reloj simulado de widgets.
Future<Dependencies> loadDemoDependencies() async {
  final seed = await DemoSeed.load();
  final config = AppConfig.test();
  return Dependencies(
    config: config,
    auth: DemoAuthRepository(config: config, initialAccounts: seed.accounts),
    invoices: DemoInvoiceRepository(
      config: config,
      initialInvoices: seed.invoices,
    ),
  );
}
