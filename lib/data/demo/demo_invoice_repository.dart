import '../../app/app_config.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../models/app_user.dart';
import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';
import 'demo_seed.dart';

/// Repositorio de facturas en memoria para el modo demostración.
///
/// Reproduce el comportamiento esperado del backend: valida permisos por rol,
/// aplica las transiciones de estado y mantiene el historial de auditoría.
class DemoInvoiceRepository implements InvoiceRepository {
  DemoInvoiceRepository({
    AppConfig? config,
    DateTime Function()? clock,
    List<Invoice>? initialInvoices,
  })  : _config = config ?? AppConfig.fromEnvironment(),
        _clock = clock ?? DateTime.now {
    final now = _clock();
    _invoices.addAll(initialInvoices ?? DemoSeed.invoices(now));
    _sequence = _invoices.length + 1000;
  }

  final AppConfig _config;
  final DateTime Function() _clock;
  final List<Invoice> _invoices = [];

  int _sequence = 1000;

  /// Copia inmutable del estado actual, útil en pruebas.
  List<Invoice> get snapshot => List.unmodifiable(_invoices);

  @override
  Future<Result<List<Invoice>>> fetchAll(AppUser user) async {
    await _delay();
    final visible = user.role.canSeeAllInvoices
        ? List<Invoice>.from(_invoices)
        : _invoices.where((invoice) => invoice.isOwnedBy(user)).toList();
    visible.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Ok(visible);
  }

  @override
  Future<Result<Invoice>> getById(String id) async {
    await _delay();
    final index = _indexOf(id);
    if (index == -1) return const Err(NotFoundFailure('La factura no existe.'));
    return Ok(_invoices[index]);
  }

  @override
  Future<Result<Invoice>> create(InvoiceDraft draft, AppUser actor) async {
    await _delay();
    if (!actor.role.canCreateInvoices) {
      return const Err(
        PermissionFailure('Tu rol no permite crear facturas.'),
      );
    }
    final now = _clock();
    _sequence++;
    final invoice = Invoice(
      id: 'inv-$_sequence',
      number: draft.number.trim(),
      supplierName: draft.supplierName.trim(),
      supplierTaxId: draft.supplierTaxId.trim(),
      issueDate: draft.issueDate,
      items: List.unmodifiable(draft.items),
      status: InvoiceStatus.borrador,
      createdById: actor.id,
      createdByName: actor.fullName,
      createdAt: now,
      updatedAt: now,
      notes: draft.notes.trim(),
      history: [
        InvoiceEvent(
          at: now,
          actorId: actor.id,
          actorName: actor.fullName,
          status: InvoiceStatus.borrador,
          description: 'Factura creada',
        ),
      ],
    );
    if (_invoices.any((existing) => existing.number == invoice.number)) {
      return Err(
        ValidationFailure('Ya existe una factura con el número ${invoice.number}.'),
      );
    }
    _invoices.add(invoice);
    return Ok(invoice);
  }

  @override
  Future<Result<Invoice>> update(
    String id,
    InvoiceDraft draft,
    AppUser actor,
  ) async {
    await _delay();
    final index = _indexOf(id);
    if (index == -1) return const Err(NotFoundFailure('La factura no existe.'));
    final current = _invoices[index];
    if (!current.canBeEditedBy(actor)) {
      return Err(
        PermissionFailure(
          current.status.isEditable
              ? 'Solo el emisor de la factura puede editarla.'
              : 'Una factura ${current.status.label.toLowerCase()} no se puede editar.',
        ),
      );
    }
    final duplicated = _invoices.any(
      (other) => other.id != id && other.number == draft.number.trim(),
    );
    if (duplicated) {
      return Err(
        ValidationFailure('Ya existe una factura con el número ${draft.number.trim()}.'),
      );
    }
    final updated = current.copyWith(
      number: draft.number.trim(),
      supplierName: draft.supplierName.trim(),
      supplierTaxId: draft.supplierTaxId.trim(),
      issueDate: draft.issueDate,
      items: List.unmodifiable(draft.items),
      notes: draft.notes.trim(),
      updatedAt: _clock(),
    );
    _invoices[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<Invoice>> submit(String id, AppUser actor) async {
    await _delay();
    final index = _indexOf(id);
    if (index == -1) return const Err(NotFoundFailure('La factura no existe.'));
    final current = _invoices[index];
    if (!current.canBeEditedBy(actor)) {
      return const Err(
        PermissionFailure('Solo el emisor puede enviar esta factura a revisión.'),
      );
    }
    final errors = current.validationErrors();
    if (errors.isNotEmpty) {
      return Err(ValidationFailure(errors.first));
    }
    final updated = current.submitted(actor, _clock());
    _invoices[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<Invoice>> approve(
    String id,
    AppUser actor, {
    String? comment,
  }) async {
    await _delay();
    return _review(
      id,
      actor,
      (invoice, now) => invoice.approved(actor, now, comment: comment),
    );
  }

  @override
  Future<Result<Invoice>> reject(
    String id,
    AppUser actor, {
    required String reason,
  }) async {
    await _delay();
    if (reason.trim().isEmpty) {
      return const Err(
        ValidationFailure('Debes indicar el motivo del rechazo.'),
      );
    }
    return _review(
      id,
      actor,
      (invoice, now) => invoice.rejected(actor, now, reason: reason.trim()),
    );
  }

  @override
  Future<Result<Invoice>> reopen(String id, AppUser actor) async {
    await _delay();
    final index = _indexOf(id);
    if (index == -1) return const Err(NotFoundFailure('La factura no existe.'));
    final current = _invoices[index];
    if (current.status != InvoiceStatus.rechazada) {
      return const Err(
        ValidationFailure('Solo una factura rechazada se puede reabrir.'),
      );
    }
    if (!current.canBeEditedBy(actor)) {
      return const Err(
        PermissionFailure('Solo el emisor puede reabrir esta factura.'),
      );
    }
    final updated = current.reopened(actor, _clock());
    _invoices[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<void>> delete(String id, AppUser actor) async {
    await _delay();
    final index = _indexOf(id);
    if (index == -1) return const Err(NotFoundFailure('La factura no existe.'));
    final current = _invoices[index];
    if (current.status != InvoiceStatus.borrador) {
      return const Err(
        ValidationFailure('Solo se pueden eliminar facturas en borrador.'),
      );
    }
    if (!current.canBeEditedBy(actor)) {
      return const Err(
        PermissionFailure('Solo el emisor puede eliminar esta factura.'),
      );
    }
    _invoices.removeAt(index);
    return const Ok(null);
  }

  Result<Invoice> _review(
    String id,
    AppUser actor,
    Invoice Function(Invoice invoice, DateTime now) transition,
  ) {
    final index = _indexOf(id);
    if (index == -1) return const Err(NotFoundFailure('La factura no existe.'));
    final current = _invoices[index];
    if (!actor.role.canReviewInvoices) {
      return const Err(
        PermissionFailure('Solo un contador puede revisar facturas.'),
      );
    }
    if (current.status != InvoiceStatus.enviada) {
      return Err(
        ValidationFailure(
          'La factura está ${current.status.label.toLowerCase()}; no está en revisión.',
        ),
      );
    }
    if (current.isSelfReviewBy(actor)) {
      return const Err(
        PermissionFailure('No puedes revisar una factura creada por ti.'),
      );
    }
    final updated = transition(current, _clock());
    _invoices[index] = updated;
    return Ok(updated);
  }

  int _indexOf(String id) => _invoices.indexWhere((invoice) => invoice.id == id);

  Future<void> _delay() {
    if (_config.simulatedLatency == Duration.zero) return Future.value();
    return Future<void>.delayed(_config.simulatedLatency);
  }
}
