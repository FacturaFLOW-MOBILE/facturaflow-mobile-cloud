import '../core/failure.dart';
import '../core/result.dart';
import '../data/models/app_user.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import 'base_view_model.dart';

/// Detalle de una factura y las acciones del flujo de aprobación.
class InvoiceDetailViewModel extends BaseViewModel {
  InvoiceDetailViewModel({
    required this._repository,
    required this._user,
    required this._invoiceId,
    Invoice? initial,
  }) : _invoice = initial;

  final InvoiceRepository _repository;
  final AppUser _user;
  final String _invoiceId;

  Invoice? _invoice;

  /// `true` si alguna acción modificó la factura (la lista debe recargarse).
  bool _changed = false;

  AppUser get user => _user;
  Invoice? get invoice => _invoice;
  bool get hasInvoice => _invoice != null;
  bool get hasChanges => _changed;

  // --- Permisos para la UI -------------------------------------------------

  bool get canEdit => _invoice?.canBeEditedBy(_user) ?? false;

  bool get canSubmit {
    final invoice = _invoice;
    if (invoice == null) return false;
    return invoice.status.isEditable && invoice.canBeEditedBy(_user);
  }

  bool get canReview {
    final invoice = _invoice;
    if (invoice == null) return false;
    return invoice.canBeReviewedBy(_user) && !invoice.isSelfReviewBy(_user);
  }

  bool get canReopen {
    final invoice = _invoice;
    if (invoice == null) return false;
    return invoice.status == InvoiceStatus.rechazada &&
        invoice.canBeEditedBy(_user);
  }

  bool get canDelete {
    final invoice = _invoice;
    if (invoice == null) return false;
    return invoice.status == InvoiceStatus.borrador &&
        invoice.canBeEditedBy(_user);
  }

  /// Explica por qué no hay acciones disponibles (se muestra como aviso).
  String? get blockedReason {
    final invoice = _invoice;
    if (invoice == null) return null;
    if (invoice.status == InvoiceStatus.enviada &&
        _user.role.canReviewInvoices &&
        invoice.isSelfReviewBy(_user)) {
      return 'No puedes revisar una factura creada por ti.';
    }
    if (invoice.status == InvoiceStatus.enviada && !_user.role.canReviewInvoices) {
      return 'La factura está en revisión del contador.';
    }
    return null;
  }

  // --- Acciones ------------------------------------------------------------

  Future<void> load() async {
    final result = await runGuarded(() => _repository.getById(_invoiceId));
    if (result case Ok(:final value)) {
      _invoice = value;
      notifyListeners();
    }
  }

  Future<Result<Invoice>> submit() =>
      _act(() => _repository.submit(_invoiceId, _user));

  Future<Result<Invoice>> approve({String? comment}) =>
      _act(() => _repository.approve(_invoiceId, _user, comment: comment));

  Future<Result<Invoice>> reject(String reason) {
    if (reason.trim().isEmpty) {
      const message = 'Debes indicar el motivo del rechazo.';
      setError(message);
      return Future.value(const Err(ValidationFailure(message)));
    }
    return _act(() => _repository.reject(_invoiceId, _user, reason: reason));
  }

  Future<Result<Invoice>> reopen() =>
      _act(() => _repository.reopen(_invoiceId, _user));

  Future<Result<void>> delete() async {
    final result = await runGuarded(() => _repository.delete(_invoiceId, _user));
    if (result.isOk) _changed = true;
    return result;
  }

  /// Refresca el detalle con la factura devuelta por otra pantalla (edición).
  void applyUpdated(Invoice invoice) {
    _invoice = invoice;
    _changed = true;
    notifyListeners();
  }

  Future<Result<Invoice>> _act(Future<Result<Invoice>> Function() action) async {
    final result = await runGuarded(action);
    if (result case Ok(:final value)) {
      _invoice = value;
      _changed = true;
      notifyListeners();
    }
    return result;
  }
}
