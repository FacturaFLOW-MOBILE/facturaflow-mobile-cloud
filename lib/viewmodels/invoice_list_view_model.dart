import '../core/result.dart';
import '../data/models/app_user.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import 'base_view_model.dart';

/// Ámbito de la lista de facturas.
enum InvoiceScope {
  /// Facturas creadas por el usuario actual.
  propias('Mis facturas'),

  /// Facturas enviadas pendientes de revisión (solo contadores).
  revision('Por revisar'),

  /// Todas las facturas visibles para el rol.
  todas('Todas');

  const InvoiceScope(this.label);

  final String label;
}

/// Lista de facturas con filtros por estado, ámbito y texto.
class InvoiceListViewModel extends BaseViewModel {
  InvoiceListViewModel({required this._repository, required this._user}) {
    // El contador entra directo a su cola de revisión.
    _scope = _user.role.canReviewInvoices
        ? InvoiceScope.revision
        : InvoiceScope.propias;
  }

  final InvoiceRepository _repository;
  final AppUser _user;

  List<Invoice> _all = const [];
  late InvoiceScope _scope;
  InvoiceStatus? _statusFilter;
  String _query = '';

  AppUser get user => _user;
  InvoiceScope get scope => _scope;
  InvoiceStatus? get statusFilter => _statusFilter;
  String get query => _query;

  /// Ámbitos disponibles según el rol.
  List<InvoiceScope> get availableScopes => [
        if (_user.role.canCreateInvoices) InvoiceScope.propias,
        if (_user.role.canReviewInvoices) InvoiceScope.revision,
        if (_user.role.canSeeAllInvoices) InvoiceScope.todas,
      ];

  /// Todas las facturas traídas del repositorio, sin filtrar.
  List<Invoice> get all => List.unmodifiable(_all);

  /// Facturas que cumplen ámbito + estado + búsqueda.
  List<Invoice> get visible {
    final query = _query.trim().toLowerCase();
    return _all.where((invoice) {
      if (!_matchesScope(invoice)) return false;
      if (_statusFilter != null && invoice.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      return invoice.number.toLowerCase().contains(query) ||
          invoice.supplierName.toLowerCase().contains(query) ||
          invoice.supplierTaxId.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  bool get isEmpty => visible.isEmpty;

  /// Cantidad de facturas por estado dentro del ámbito actual.
  Map<InvoiceStatus, int> get countsByStatus {
    final counts = {for (final status in InvoiceStatus.values) status: 0};
    for (final invoice in _all) {
      if (!_matchesScope(invoice)) continue;
      counts[invoice.status] = (counts[invoice.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Total aprobado del ámbito actual, en centavos.
  int get approvedTotalCents => _all
      .where((invoice) =>
          _matchesScope(invoice) && invoice.status == InvoiceStatus.aprobada)
      .fold(0, (total, invoice) => total + invoice.totalCents);

  /// Facturas pendientes de revisión (badge del contador).
  int get pendingReviewCount => _all
      .where((invoice) => invoice.status == InvoiceStatus.enviada)
      .length;

  Future<void> load() async {
    final result = await runGuarded(() => _repository.fetchAll(_user));
    if (result case Ok(:final value)) {
      _all = value;
      notifyListeners();
    }
  }

  /// Recarga sin mostrar el spinner de pantalla completa (pull to refresh).
  Future<void> refresh() async {
    final result = await _repository.fetchAll(_user);
    if (isDisposed) return;
    switch (result) {
      case Ok(:final value):
        _all = value;
        clearError();
        notifyListeners();
      case Err(:final failure):
        setError(failure.message);
    }
  }

  void setScope(InvoiceScope scope) {
    if (_scope == scope) return;
    _scope = scope;
    notifyListeners();
  }

  void setStatusFilter(InvoiceStatus? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _query = '';
    notifyListeners();
  }

  bool _matchesScope(Invoice invoice) => switch (_scope) {
        InvoiceScope.propias => invoice.isOwnedBy(_user),
        InvoiceScope.revision =>
          invoice.status == InvoiceStatus.enviada && !invoice.isOwnedBy(_user),
        InvoiceScope.todas => true,
      };
}
