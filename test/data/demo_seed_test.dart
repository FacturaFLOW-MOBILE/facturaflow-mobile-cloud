import 'dart:convert';

import 'package:factura_flow_mobile/data/demo/demo_seed.dart';
import 'package:factura_flow_mobile/data/demo/demo_invoice_repository.dart';
import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

class InvalidBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('{invalid')));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carga los usuarios, facturas y fechas relativas desde JSON', () async {
    final seed = await DemoSeed.load(now: fechaFija);
    expect(seed.accounts, hasLength(3));
    expect(seed.invoices, hasLength(5));
    expect(seed.accounts.first.user, emisor);
    final invoice = seed.invoices.first;
    expect(invoice.number, 'FE-1001');
    expect(invoice.items, hasLength(2));
    expect(invoice.createdAt, fechaFija.subtract(const Duration(days: 2)));
    expect(invoice.history.first.actorId, emisor.id);
  });

  test('cargas concurrentes no duplican facturas demo', () async {
    final repository = DemoInvoiceRepository(
      config: AppConfig.test(),
      clock: testClock,
    );
    await Future.wait([
      repository.fetchAll(emisor),
      repository.fetchAll(emisor),
    ]);
    expect(repository.snapshot, hasLength(5));
  });

  test('un JSON inválido falla sin fabricar datos', () async {
    await expectLater(
      DemoSeed.load(bundle: InvalidBundle()),
      throwsFormatException,
    );
  });
}
