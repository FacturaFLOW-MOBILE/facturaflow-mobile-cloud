import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/core/failure.dart';
import 'package:factura_flow_mobile/data/demo/demo_invoice_repository.dart';
import 'package:factura_flow_mobile/data/models/invoice.dart';
import 'package:factura_flow_mobile/data/repositories/invoice_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  late DemoInvoiceRepository repository;

  InvoiceDraft draft({String number = 'FE-7001'}) => InvoiceDraft(
        number: number,
        supplierName: 'Proveedor Nuevo',
        supplierTaxId: '901222333-4',
        issueDate: fechaFija,
        items: const [
          InvoiceItem(
            description: 'Consultoría',
            quantity: 2,
            unitPriceCents: 500000,
          ),
        ],
      );

  setUp(() {
    repository = DemoInvoiceRepository(
      config: AppConfig.test(),
      clock: testClock,
      initialInvoices: [
        buildInvoice(id: 'inv-a', number: 'FE-A', owner: emisor),
        buildInvoice(
          id: 'inv-b',
          number: 'FE-B',
          owner: emisor,
          status: InvoiceStatus.enviada,
        ),
        buildInvoice(id: 'inv-c', number: 'FE-C', owner: administrador),
      ],
    );
  });

  group('fetchAll', () {
    test('el emisor solo ve sus propias facturas', () async {
      final result = await repository.fetchAll(emisor);
      final invoices = result.valueOrNull!;

      expect(invoices, hasLength(2));
      expect(invoices.every((invoice) => invoice.isOwnedBy(emisor)), isTrue);
    });

    test('el contador ve todas las facturas', () async {
      final result = await repository.fetchAll(contador);
      expect(result.valueOrNull, hasLength(3));
    });
  });

  group('create', () {
    test('crea la factura en borrador y la deja consultable', () async {
      final result = await repository.create(draft(), emisor);
      final invoice = result.valueOrNull!;

      expect(invoice.status, InvoiceStatus.borrador);
      expect(invoice.createdById, emisor.id);
      expect(invoice.totalCents, 1190000);
      expect(repository.snapshot, hasLength(4));
    });

    test('el contador no puede crear facturas', () async {
      final result = await repository.create(draft(), contador);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('rechaza números de factura duplicados', () async {
      final result = await repository.create(draft(number: 'FE-A'), emisor);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('submit', () {
    test('el dueño envía su borrador a revisión', () async {
      final result = await repository.submit('inv-a', emisor);
      expect(result.valueOrNull?.status, InvoiceStatus.enviada);
    });

    test('un borrador incompleto no se puede enviar', () async {
      final incompleta = DemoInvoiceRepository(
        config: AppConfig.test(),
        clock: testClock,
        initialInvoices: [buildInvoice(id: 'inv-x', items: const [])],
      );
      final result = await incompleta.submit('inv-x', emisor);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('al menos un ítem'));
    });

    test('una factura inexistente devuelve NotFound', () async {
      final result = await repository.submit('inv-zzz', emisor);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('approve / reject', () {
    test('el contador aprueba una factura enviada', () async {
      final result = await repository.approve('inv-b', contador);
      final invoice = result.valueOrNull!;

      expect(invoice.status, InvoiceStatus.aprobada);
      expect(invoice.history.last.actorId, contador.id);
    });

    test('el emisor no puede aprobar', () async {
      final result = await repository.approve('inv-b', emisor);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('no se aprueba lo que no está en revisión', () async {
      final result = await repository.approve('inv-a', contador);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('el rechazo exige un motivo', () async {
      final result = await repository.reject('inv-b', contador, reason: '  ');
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('el rechazo guarda el motivo en la factura', () async {
      final result = await repository.reject(
        'inv-b',
        contador,
        reason: 'Falta la orden de compra',
      );
      final invoice = result.valueOrNull!;

      expect(invoice.status, InvoiceStatus.rechazada);
      expect(invoice.rejectionReason, 'Falta la orden de compra');
    });

    test('un administrador no revisa su propia factura', () async {
      final enviada = await repository.submit('inv-c', administrador);
      expect(enviada.isOk, isTrue);

      final result = await repository.approve('inv-c', administrador);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('reopen y delete', () {
    test('una factura rechazada vuelve a borrador', () async {
      await repository.reject('inv-b', contador, reason: 'Datos erróneos');
      final result = await repository.reopen('inv-b', emisor);

      expect(result.valueOrNull?.status, InvoiceStatus.borrador);
    });

    test('solo se eliminan borradores', () async {
      final enviada = await repository.delete('inv-b', emisor);
      expect(enviada.failureOrNull, isA<ValidationFailure>());

      final borrador = await repository.delete('inv-a', emisor);
      expect(borrador.isOk, isTrue);
      expect(repository.snapshot, hasLength(2));
    });
  });
}
