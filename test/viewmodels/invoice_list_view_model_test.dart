import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/data/demo/demo_invoice_repository.dart';
import 'package:factura_flow_mobile/data/models/app_user.dart';
import 'package:factura_flow_mobile/data/models/invoice.dart';
import 'package:factura_flow_mobile/viewmodels/invoice_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  late DemoInvoiceRepository repository;

  setUp(() {
    repository = DemoInvoiceRepository(
      config: AppConfig.test(),
      clock: testClock,
      initialInvoices: [
        buildInvoice(id: '1', number: 'FE-A', owner: emisor),
        buildInvoice(
          id: '2',
          number: 'FE-B',
          owner: emisor,
          status: InvoiceStatus.enviada,
        ),
        buildInvoice(
          id: '3',
          number: 'FE-C',
          owner: emisor,
          status: InvoiceStatus.aprobada,
        ),
        buildInvoice(
          id: '4',
          number: 'FE-D',
          supplierName: 'Transportes Andinos',
          owner: administrador,
          status: InvoiceStatus.enviada,
        ),
      ],
    );
  });

  InvoiceListViewModel viewModelFor(AppUser user) =>
      InvoiceListViewModel(repository: repository, user: user);

  test('el emisor arranca viendo sus propias facturas', () async {
    final viewModel = viewModelFor(emisor);
    await viewModel.load();

    expect(viewModel.scope, InvoiceScope.propias);
    expect(viewModel.visible, hasLength(3));
    viewModel.dispose();
  });

  test('el contador arranca en la cola de revisión ajena', () async {
    final viewModel = viewModelFor(contador);
    await viewModel.load();

    expect(viewModel.scope, InvoiceScope.revision);
    expect(viewModel.visible, hasLength(2));
    expect(
      viewModel.visible.every((i) => i.status == InvoiceStatus.enviada),
      isTrue,
    );
    viewModel.dispose();
  });

  test('el ámbito "revisión" excluye las facturas propias del revisor',
      () async {
    final viewModel = viewModelFor(administrador);
    await viewModel.load();
    viewModel.setScope(InvoiceScope.revision);

    expect(viewModel.visible, hasLength(1));
    expect(viewModel.visible.single.number, 'FE-B');
    viewModel.dispose();
  });

  test('el filtro por estado reduce la lista', () async {
    final viewModel = viewModelFor(emisor);
    await viewModel.load();
    viewModel.setStatusFilter(InvoiceStatus.aprobada);

    expect(viewModel.visible, hasLength(1));
    expect(viewModel.visible.single.number, 'FE-C');
    viewModel.dispose();
  });

  test('la búsqueda encuentra por proveedor sin importar mayúsculas', () async {
    final viewModel = viewModelFor(contador);
    await viewModel.load();
    viewModel.setScope(InvoiceScope.todas);
    viewModel.setQuery('transportes');

    expect(viewModel.visible, hasLength(1));
    expect(viewModel.visible.single.number, 'FE-D');
    viewModel.dispose();
  });

  test('quitar filtros restaura la lista completa', () async {
    final viewModel = viewModelFor(emisor);
    await viewModel.load();
    viewModel.setQuery('no-existe');
    expect(viewModel.isEmpty, isTrue);

    viewModel.clearFilters();

    expect(viewModel.visible, hasLength(3));
    viewModel.dispose();
  });

  test('los contadores por estado reflejan el ámbito actual', () async {
    final viewModel = viewModelFor(emisor);
    await viewModel.load();

    final counts = viewModel.countsByStatus;
    expect(counts[InvoiceStatus.borrador], 1);
    expect(counts[InvoiceStatus.enviada], 1);
    expect(counts[InvoiceStatus.aprobada], 1);
    expect(counts[InvoiceStatus.rechazada], 0);
    viewModel.dispose();
  });

  test('el total aprobado suma solo las facturas aprobadas', () async {
    final viewModel = viewModelFor(emisor);
    await viewModel.load();

    expect(viewModel.approvedTotalCents, 119000);
    viewModel.dispose();
  });
}
