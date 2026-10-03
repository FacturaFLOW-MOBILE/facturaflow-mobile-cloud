import '../core/failure.dart';
import '../core/result.dart';
import '../data/models/app_user.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import 'base_view_model.dart';

/// Formulario de creación y edición de facturas.
///
/// Mantiene el borrador en memoria; la vista solo enlaza controladores y
/// muestra los mensajes que produce este ViewModel.
class InvoiceFormViewModel extends BaseViewModel {
  InvoiceFormViewModel({
    required this._repository,
    required this._user,
    Invoice? existing,
    DateTime Function()? clock,
  }) : _existing = existing,
       _number = existing?.number ?? '',
       _supplierName = existing?.supplierName ?? '',
       _supplierTaxId = existing?.supplierTaxId ?? '',
       _notes = existing?.notes ?? '',
       _issueDate = existing?.issueDate ?? (clock ?? DateTime.now)(),
       _items = List<InvoiceItem>.from(existing?.items ?? const []);

  final InvoiceRepository _repository;
  final AppUser _user;
  final Invoice? _existing;

  String _number;
  String _supplierName;
  String _supplierTaxId;
  String _notes;
  DateTime _issueDate;
  final List<InvoiceItem> _items;

  bool get isEditing => _existing != null;
  Invoice? get existing => _existing;

  String get number => _number;
  String get supplierName => _supplierName;
  String get supplierTaxId => _supplierTaxId;
  String get notes => _notes;
  DateTime get issueDate => _issueDate;
  List<InvoiceItem> get items => List.unmodifiable(_items);

  String get title => isEditing ? 'Editar factura' : 'Nueva factura';

  // --- Totales en vivo -----------------------------------------------------

  int get subtotalCents =>
      _items.fold(0, (total, item) => total + item.subtotalCents);
  int get taxCents => _items.fold(0, (total, item) => total + item.taxCents);
  int get totalCents => subtotalCents + taxCents;

  // --- Edición de campos ---------------------------------------------------

  void setNumber(String value) {
    _number = value;
    clearError();
  }

  void setSupplierName(String value) {
    _supplierName = value;
    clearError();
  }

  void setSupplierTaxId(String value) {
    _supplierTaxId = value;
    clearError();
  }

  void setNotes(String value) {
    _notes = value;
  }

  void setIssueDate(DateTime value) {
    _issueDate = value;
    notifyListeners();
  }

  void addItem(InvoiceItem item) {
    _items.add(item);
    clearError();
    notifyListeners();
  }

  void replaceItem(int index, InvoiceItem item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  // --- Validación ----------------------------------------------------------

  String? validateNumber(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'El número de factura es obligatorio.';
    if (text.length < 3) return 'Usa al menos 3 caracteres.';
    return null;
  }

  String? validateSupplierName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'El nombre del proveedor es obligatorio.';
    return null;
  }

  String? validateSupplierTaxId(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'El NIT del proveedor es obligatorio.';
    // Acepta NIT sin DV o con DV separado por guion; puntos solo por miles.
    final match = RegExp(r'^(\d{5,15}|\d{1,3}(?:\.\d{3}){1,4})(?:-(\d))?$')
        .firstMatch(text);
    if (match == null) {
      return 'Usa un NIT numérico y, si incluyes el DV, sepáralo con guion.';
    }
    final digits = match.group(1)!.replaceAll('.', '');
    if (digits.length < 5 ||
        digits.length > 15 ||
        RegExp(r'^0+$').hasMatch(digits)) {
      return 'El NIT debe tener entre 5 y 15 dígitos y no puede ser cero.';
    }
    final suppliedDv = match.group(2);
    if (suppliedDv != null) {
      // Pesos de derecha a izquierda del algoritmo módulo 11 de la DIAN.
      const weights = [
        3,
        7,
        13,
        17,
        19,
        23,
        29,
        37,
        41,
        43,
        47,
        53,
        59,
        67,
        71,
      ];
      var sum = 0;
      for (var i = 0; i < digits.length; i++) {
        sum += int.parse(digits[digits.length - 1 - i]) * weights[i];
      }
      final remainder = sum % 11;
      final expectedDv = remainder > 1 ? 11 - remainder : remainder;
      if (int.parse(suppliedDv) != expectedDv) {
        return 'El dígito de verificación del NIT no es válido.';
      }
    }
    return null;
  }

  /// Error de las reglas que no pertenecen a un campo concreto.
  String? get itemsError =>
      _items.isEmpty ? 'Agrega al menos un ítem a la factura.' : null;

  bool get canSubmitForReview => itemsError == null && _formIsValid;

  bool get _formIsValid =>
      validateNumber(_number) == null &&
      validateSupplierName(_supplierName) == null &&
      validateSupplierTaxId(_supplierTaxId) == null;

  // --- Acciones ------------------------------------------------------------

  /// Guarda como borrador (crea o actualiza).
  Future<Result<Invoice>> save() async {
    final blocking = _firstValidationError();
    if (blocking != null) {
      setError(blocking);
      return Err(ValidationFailure(blocking));
    }
    final draft = _buildDraft();
    return runGuarded(
      () => isEditing
          ? _repository.update(_existing!.id, draft, _user)
          : _repository.create(draft, _user),
    );
  }

  /// Guarda y envía a revisión en una sola acción.
  Future<Result<Invoice>> saveAndSubmit() async {
    final itemsProblem = itemsError;
    if (itemsProblem != null) {
      setError(itemsProblem);
      return Err(ValidationFailure(itemsProblem));
    }
    final saved = await save();
    if (saved case Err<Invoice>()) return saved;
    final invoice = saved.valueOrNull!;
    return runGuarded(() => _repository.submit(invoice.id, _user));
  }

  String? _firstValidationError() =>
      validateNumber(_number) ??
      validateSupplierName(_supplierName) ??
      validateSupplierTaxId(_supplierTaxId);

  InvoiceDraft _buildDraft() => InvoiceDraft(
    number: _number,
    supplierName: _supplierName,
    supplierTaxId: _supplierTaxId,
    issueDate: _issueDate,
    items: List<InvoiceItem>.unmodifiable(_items),
    notes: _notes,
  );
}
