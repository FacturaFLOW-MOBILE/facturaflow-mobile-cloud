import 'package:factura_flow_mobile/data/models/app_user.dart';
import 'package:factura_flow_mobile/data/models/invoice.dart';
import 'package:factura_flow_mobile/data/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('Totales', () {
    test('suma subtotal, IVA y total de todas las líneas', () {
      final invoice = buildInvoice(
        items: const [
          InvoiceItem(
            description: 'Servicio A',
            quantity: 2,
            unitPriceCents: 100000, // $1.000,00 c/u
          ),
          InvoiceItem(
            description: 'Servicio B',
            quantity: 1,
            unitPriceCents: 50000,
            taxRate: 0.05,
          ),
        ],
      );

      expect(invoice.subtotalCents, 250000);
      expect(invoice.taxCents, 38000 + 2500);
      expect(invoice.totalCents, 250000 + 40500);
    });

    test('una factura sin ítems suma cero', () {
      final invoice = buildInvoice(items: const []);
      expect(invoice.totalCents, 0);
    });

    test('el IVA se redondea al centavo', () {
      const item = InvoiceItem(
        description: 'Redondeo',
        quantity: 1,
        unitPriceCents: 333,
        taxRate: 0.19,
      );
      // 333 * 0.19 = 63.27 -> 63
      expect(item.taxCents, 63);
      expect(item.totalCents, 396);
    });
  });

  group('Validación', () {
    test('detecta los campos obligatorios vacíos', () {
      final invoice = buildInvoice(
        number: '',
        supplierName: '',
        supplierTaxId: '',
        items: const [],
      );
      final errors = invoice.validationErrors();

      expect(errors, hasLength(4));
      expect(errors.first, contains('número'));
    });

    test('rechaza cantidades y precios no positivos', () {
      final invoice = buildInvoice(
        items: const [
          InvoiceItem(description: 'X', quantity: 0, unitPriceCents: 0),
        ],
      );
      final errors = invoice.validationErrors();

      expect(errors, contains('Las cantidades deben ser mayores que cero.'));
      expect(
        errors,
        contains('Los precios unitarios deben ser mayores que cero.'),
      );
    });

    test('una factura completa no tiene errores', () {
      expect(buildInvoice().validationErrors(), isEmpty);
    });
  });

  group('Permisos por rol', () {
    test('el emisor dueño puede editar su borrador', () {
      final invoice = buildInvoice(owner: emisor);
      expect(invoice.canBeEditedBy(emisor), isTrue);
      expect(invoice.canBeSubmittedBy(emisor), isTrue);
    });

    test('otro emisor no puede editar una factura ajena', () {
      const otro = AppUser(
        id: 'u-otro',
        fullName: 'Otro Emisor',
        email: 'otro@demo.test',
        role: UserRole.emisor,
      );
      final invoice = buildInvoice(owner: emisor);
      expect(invoice.canBeEditedBy(otro), isFalse);
    });

    test('el contador no edita, pero revisa lo que está enviado', () {
      final enviada =
          buildInvoice(status: InvoiceStatus.enviada, owner: emisor);
      expect(enviada.canBeEditedBy(contador), isFalse);
      expect(enviada.canBeReviewedBy(contador), isTrue);
    });

    test('no se revisa una factura que sigue en borrador', () {
      final borrador = buildInvoice(owner: emisor);
      expect(borrador.canBeReviewedBy(contador), isFalse);
    });

    test('una factura aprobada ya no es editable', () {
      final aprobada =
          buildInvoice(status: InvoiceStatus.aprobada, owner: emisor);
      expect(aprobada.canBeEditedBy(emisor), isFalse);
      expect(aprobada.status.isFinal, isTrue);
    });
  });

  group('Transiciones de estado', () {
    final momento = DateTime(2026, 8, 26, 10, 30);

    test('enviar deja la factura en revisión y registra el evento', () {
      final invoice = buildInvoice(owner: emisor).submitted(emisor, momento);

      expect(invoice.status, InvoiceStatus.enviada);
      expect(invoice.updatedAt, momento);
      expect(invoice.history.last.description, 'Enviada a revisión');
      expect(invoice.history.last.actorId, emisor.id);
    });

    test('aprobar guarda el comentario del contador', () {
      final invoice = buildInvoice(status: InvoiceStatus.enviada)
          .approved(contador, momento, comment: 'Todo en orden');

      expect(invoice.status, InvoiceStatus.aprobada);
      expect(invoice.history.last.comment, 'Todo en orden');
      expect(invoice.rejectionReason, isNull);
    });

    test('rechazar guarda el motivo y lo deja visible', () {
      final invoice = buildInvoice(status: InvoiceStatus.enviada)
          .rejected(contador, momento, reason: 'Falta el soporte');

      expect(invoice.status, InvoiceStatus.rechazada);
      expect(invoice.rejectionReason, 'Falta el soporte');
      expect(invoice.history.last.comment, 'Falta el soporte');
    });

    test('reenviar tras un rechazo limpia el motivo anterior', () {
      final rechazada = buildInvoice(status: InvoiceStatus.enviada)
          .rejected(contador, momento, reason: 'Falta el soporte');
      final reenviada = rechazada
          .reopened(emisor, momento)
          .submitted(emisor, momento.add(const Duration(minutes: 5)));

      expect(reenviada.status, InvoiceStatus.enviada);
      expect(reenviada.rejectionReason, isNull);
      expect(reenviada.history, hasLength(rechazada.history.length + 2));
    });

    test('el historial conserva el orden cronológico', () {
      final invoice = buildInvoice(owner: emisor)
          .submitted(emisor, momento)
          .approved(contador, momento.add(const Duration(hours: 1)));

      final fechas = invoice.history.map((event) => event.at).toList();
      for (var i = 1; i < fechas.length; i++) {
        expect(fechas[i].isBefore(fechas[i - 1]), isFalse);
      }
    });
  });

  group('Serialización', () {
    test('ida y vuelta por JSON conserva los datos', () {
      final original = buildInvoice(status: InvoiceStatus.enviada)
          .rejected(contador, DateTime(2026, 8, 26), reason: 'Motivo');
      final copia = Invoice.fromJson(original.toJson());

      expect(copia.id, original.id);
      expect(copia.number, original.number);
      expect(copia.status, original.status);
      expect(copia.totalCents, original.totalCents);
      expect(copia.rejectionReason, original.rejectionReason);
      expect(copia.history, hasLength(original.history.length));
    });
  });
}
