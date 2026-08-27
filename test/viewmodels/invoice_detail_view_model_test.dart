import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/core/failure.dart';
import 'package:factura_flow_mobile/data/demo/demo_invoice_repository.dart';
import 'package:factura_flow_mobile/data/models/app_user.dart';
import 'package:factura_flow_mobile/data/models/invoice.dart';
import 'package:factura_flow_mobile/viewmodels/invoice_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  late DemoInvoiceRepository repository;

  setUp(() {
    repository = DemoInvoiceRepository(
      config: AppConfig.test(),
      clock: testClock,
      initialInvoices: [
        buildInvoice(id: 'borrador', number: 'FE-1', owner: emisor),
        buildInvoice(
          id: 'enviada',
          number: 'FE-2',
          owner: emisor,
          status: InvoiceStatus.enviada,
        ),
        buildInvoice(
          id: 'propia-contador',
          number: 'FE-3',
          owner: contador,
          status: InvoiceStatus.enviada,
        ),
      ],
    );
  });

  InvoiceDetailViewModel viewModelFor(AppUser user, String id) =>
      InvoiceDetailViewModel(
        repository: repository,
        user: user,
        invoiceId: id,
      );

  test('carga la factura y expone los permisos del emisor', () async {
    final viewModel = viewModelFor(emisor, 'borrador');
    await viewModel.load();

    expect(viewModel.invoice?.number, 'FE-1');
    expect(viewModel.canEdit, isTrue);
    expect(viewModel.canSubmit, isTrue);
    expect(viewModel.canReview, isFalse);
    expect(viewModel.canDelete, isTrue);
    viewModel.dispose();
  });

  test('el emisor envía a revisión y la factura queda marcada como cambiada',
      () async {
    final viewModel = viewModelFor(emisor, 'borrador');
    await viewModel.load();

    final result = await viewModel.submit();

    expect(result.isOk, isTrue);
    expect(viewModel.invoice?.status, InvoiceStatus.enviada);
    expect(viewModel.hasChanges, isTrue);
    expect(viewModel.canSubmit, isFalse);
    viewModel.dispose();
  });

  test('el contador aprueba una factura en revisión', () async {
    final viewModel = viewModelFor(contador, 'enviada');
    await viewModel.load();
    expect(viewModel.canReview, isTrue);

    final result = await viewModel.approve(comment: 'Soportes completos');

    expect(result.isOk, isTrue);
    expect(viewModel.invoice?.status, InvoiceStatus.aprobada);
    expect(viewModel.invoice?.history.last.comment, 'Soportes completos');
    viewModel.dispose();
  });

  test('el rechazo sin motivo no llega al repositorio', () async {
    final viewModel = viewModelFor(contador, 'enviada');
    await viewModel.load();

    final result = await viewModel.reject('   ');

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(viewModel.invoice?.status, InvoiceStatus.enviada);
    viewModel.dispose();
  });

  test('el rechazo con motivo actualiza estado y razón', () async {
    final viewModel = viewModelFor(contador, 'enviada');
    await viewModel.load();

    await viewModel.reject('Falta el certificado de retención');

    expect(viewModel.invoice?.status, InvoiceStatus.rechazada);
    expect(
      viewModel.invoice?.rejectionReason,
      'Falta el certificado de retención',
    );
    viewModel.dispose();
  });

  test('tras el rechazo el emisor puede reabrir para corregir', () async {
    final revisor = viewModelFor(contador, 'enviada');
    await revisor.load();
    await revisor.reject('Datos incorrectos');
    revisor.dispose();

    final autor = viewModelFor(emisor, 'enviada');
    await autor.load();
    expect(autor.canReopen, isTrue);

    await autor.reopen();

    expect(autor.invoice?.status, InvoiceStatus.borrador);
    autor.dispose();
  });

  test('un contador no puede revisar su propia factura', () async {
    final viewModel = viewModelFor(contador, 'propia-contador');
    await viewModel.load();

    expect(viewModel.canReview, isFalse);
    expect(viewModel.blockedReason, contains('creada por ti'));

    final result = await viewModel.approve();
    expect(result.failureOrNull, isA<PermissionFailure>());
    viewModel.dispose();
  });

  test('el emisor no ve acciones de revisión sobre una factura enviada',
      () async {
    final viewModel = viewModelFor(emisor, 'enviada');
    await viewModel.load();

    expect(viewModel.canReview, isFalse);
    expect(viewModel.canEdit, isFalse);
    expect(viewModel.blockedReason, contains('revisión del contador'));
    viewModel.dispose();
  });

  test('una factura inexistente deja el ViewModel en error', () async {
    final viewModel = viewModelFor(emisor, 'no-existe');
    await viewModel.load();

    expect(viewModel.hasError, isTrue);
    expect(viewModel.invoice, isNull);
    viewModel.dispose();
  });
}
