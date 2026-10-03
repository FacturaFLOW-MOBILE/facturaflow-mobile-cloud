import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/app/dependencies.dart';
import 'package:factura_flow_mobile/data/remote/remote_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sin flags usa repositorios remotos y no datos demo', () {
    final config = AppConfig.fromEnvironment();
    expect(config.demoMode, isFalse);
    final dependencies = Dependencies(config: config);
    expect(dependencies.authRepository, isA<RemoteAuthRepository>());
    expect(dependencies.invoiceRepository, isA<RemoteInvoiceRepository>());
  });
  test('las pruebas conservan la opción demo explícita', () {
    expect(AppConfig.test().demoMode, isTrue);
  });
}
