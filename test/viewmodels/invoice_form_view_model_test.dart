import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/core/failure.dart';
import 'package:factura_flow_mobile/data/demo/demo_invoice_repository.dart';
import 'package:factura_flow_mobile/data/models/invoice.dart';
import 'package:factura_flow_mobile/viewmodels/invoice_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  late DemoInvoiceRepository repository;

  setUp(() {
    repository = DemoInvoiceRepository(
      config: AppConfig.test(),
      clock: testClock,
      initialInvoices: [buildInvoice(id: 'inv-1', number: 'FE-1')],
    );
  });

  InvoiceFormViewModel newForm() => InvoiceFormViewModel(
        repository: repository,
        user: emisor,
        clock: testClock,
      );

  void fillValidFields(InvoiceFormViewModel viewModel) {
    viewModel
      ..setNumber('FE-2026')
      ..setSupplierName('Proveedor S.A.S.')
      ..setSupplierTaxId('900123456-7')
      ..addItem(
        const InvoiceItem(
          description: 'Servicio',
          quantity: 3,
          unitPriceCents: 200000,
        ),
      );
  }

  test('los totales se recalculan al agregar y quitar ítems', () {
    final viewModel = newForm();
    expect(viewModel.totalCents, 0);

    viewModel.addItem(
      const InvoiceItem(
        description: 'A',
        quantity: 2,
        unitPriceCents: 100000,
      ),
    );

    expect(viewModel.subtotalCents, 200000);
    expect(viewModel.taxCents, 38000);
    expect(viewModel.totalCents, 238000);

    viewModel.removeItemAt(0);
    expect(viewModel.totalCents, 0);
    viewModel.dispose();
  });

  test('no guarda si faltan campos obligatorios', () async {
    final viewModel = newForm();

    final result = await viewModel.save();

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(viewModel.hasError, isTrue);
    expect(repository.snapshot, hasLength(1));
    viewModel.dispose();
  });

  test('guarda un borrador válido', () async {
    final viewModel = newForm();
    fillValidFields(viewModel);

    final result = await viewModel.save();
    final invoice = result.valueOrNull!;

    expect(invoice.status, InvoiceStatus.borrador);
    expect(invoice.number, 'FE-2026');
    expect(invoice.totalCents, 714000);
    expect(repository.snapshot, hasLength(2));
    viewModel.dispose();
  });

  test('guardar y enviar deja la factura en revisión', () async {
    final viewModel = newForm();
    fillValidFields(viewModel);

    final result = await viewModel.saveAndSubmit();

    expect(result.valueOrNull?.status, InvoiceStatus.enviada);
    viewModel.dispose();
  });

  test('enviar sin ítems falla antes de tocar el repositorio', () async {
    final viewModel = newForm()
      ..setNumber('FE-3000')
      ..setSupplierName('Proveedor')
      ..setSupplierTaxId('900111222');

    final result = await viewModel.saveAndSubmit();

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(repository.snapshot, hasLength(1));
    viewModel.dispose();
  });

  test('en modo edición precarga los datos de la factura', () async {
    final existing = repository.snapshot.single;
    final viewModel = InvoiceFormViewModel(
      repository: repository,
      user: emisor,
      existing: existing,
    );

    expect(viewModel.isEditing, isTrue);
    expect(viewModel.number, existing.number);
    expect(viewModel.items, hasLength(existing.items.length));

    viewModel.setSupplierName('Proveedor Corregido');
    final result = await viewModel.save();

    expect(result.valueOrNull?.supplierName, 'Proveedor Corregido');
    expect(repository.snapshot, hasLength(1));
    viewModel.dispose();
  });

  test('valida el formato del NIT', () {
    final viewModel = newForm();

    expect(viewModel.validateSupplierTaxId('abc'), isNotNull);
    expect(viewModel.validateSupplierTaxId('900123456-7'), isNull);
    viewModel.dispose();
  });
}
