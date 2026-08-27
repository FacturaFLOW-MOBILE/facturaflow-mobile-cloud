import 'app_user.dart';
import 'invoice_event.dart';
import 'invoice_item.dart';
import 'invoice_status.dart';

export 'invoice_event.dart';
export 'invoice_item.dart';
export 'invoice_status.dart';

/// Factura y sus reglas de negocio.
///
/// El modelo es inmutable: cada transición devuelve una copia nueva con el
/// evento correspondiente agregado al historial.
class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.supplierName,
    required this.supplierTaxId,
    required this.issueDate,
    required this.items,
    required this.status,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.rejectionReason,
    this.history = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        number: json['number'] as String,
        supplierName: json['supplierName'] as String,
        supplierTaxId: json['supplierTaxId'] as String,
        issueDate: DateTime.parse(json['issueDate'] as String),
        items: (json['items'] as List<dynamic>)
            .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        status: InvoiceStatus.fromId(json['status'] as String),
        createdById: json['createdById'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        notes: json['notes'] as String? ?? '',
        rejectionReason: json['rejectionReason'] as String?,
        history: (json['history'] as List<dynamic>? ?? const [])
            .map((e) => InvoiceEvent.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String id;
  final String number;
  final String supplierName;

  /// NIT o documento del proveedor.
  final String supplierTaxId;
  final DateTime issueDate;
  final List<InvoiceItem> items;
  final InvoiceStatus status;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;

  /// Motivo del último rechazo, si lo hubo.
  final String? rejectionReason;
  final List<InvoiceEvent> history;

  // --- Totales -------------------------------------------------------------

  /// Suma de las bases gravables, en centavos.
  int get subtotalCents =>
      items.fold(0, (total, item) => total + item.subtotalCents);

  /// Suma de los impuestos, en centavos.
  int get taxCents => items.fold(0, (total, item) => total + item.taxCents);

  /// Total a pagar, en centavos.
  int get totalCents => subtotalCents + taxCents;

  // --- Permisos ------------------------------------------------------------

  bool isOwnedBy(AppUser user) => createdById == user.id;

  /// Solo el emisor dueño (o un administrador) edita borradores y rechazadas.
  bool canBeEditedBy(AppUser user) =>
      status.isEditable &&
      user.role.canCreateInvoices &&
      (isOwnedBy(user) || user.role.canSeeAllInvoices);

  /// Enviar a revisión requiere contenido válido y estado editable.
  bool canBeSubmittedBy(AppUser user) =>
      canBeEditedBy(user) && validationErrors().isEmpty;

  /// Aprobar o rechazar solo aplica a facturas en revisión y para contadores.
  bool canBeReviewedBy(AppUser user) =>
      status == InvoiceStatus.enviada && user.role.canReviewInvoices;

  /// Un contador no debería aprobar su propia factura.
  bool isSelfReviewBy(AppUser user) => isOwnedBy(user);

  // --- Validación ----------------------------------------------------------

  /// Errores de negocio que impiden enviar la factura a revisión.
  List<String> validationErrors() {
    final errors = <String>[];
    if (number.trim().isEmpty) {
      errors.add('El número de factura es obligatorio.');
    }
    if (supplierName.trim().isEmpty) {
      errors.add('El nombre del proveedor es obligatorio.');
    }
    if (supplierTaxId.trim().isEmpty) {
      errors.add('El NIT del proveedor es obligatorio.');
    }
    if (items.isEmpty) {
      errors.add('Agrega al menos un ítem a la factura.');
    }
    if (items.any((item) => item.quantity <= 0)) {
      errors.add('Las cantidades deben ser mayores que cero.');
    }
    if (items.any((item) => item.unitPriceCents <= 0)) {
      errors.add('Los precios unitarios deben ser mayores que cero.');
    }
    if (items.any((item) => item.description.trim().isEmpty)) {
      errors.add('Cada ítem necesita una descripción.');
    }
    return errors;
  }

  // --- Transiciones --------------------------------------------------------

  /// Marca la factura como enviada a revisión.
  Invoice submitted(AppUser actor, DateTime at) => _transition(
        actor: actor,
        at: at,
        status: InvoiceStatus.enviada,
        description: 'Enviada a revisión',
        clearRejection: true,
      );

  /// Aprueba la factura.
  Invoice approved(AppUser actor, DateTime at, {String? comment}) =>
      _transition(
        actor: actor,
        at: at,
        status: InvoiceStatus.aprobada,
        description: 'Aprobada por ${actor.fullName}',
        comment: comment,
        clearRejection: true,
      );

  /// Rechaza la factura dejando registrado el motivo.
  Invoice rejected(AppUser actor, DateTime at, {required String reason}) =>
      _transition(
        actor: actor,
        at: at,
        status: InvoiceStatus.rechazada,
        description: 'Rechazada por ${actor.fullName}',
        comment: reason,
        rejectionReason: reason,
      );

  /// Devuelve una factura rechazada a borrador para corregirla.
  Invoice reopened(AppUser actor, DateTime at) => _transition(
        actor: actor,
        at: at,
        status: InvoiceStatus.borrador,
        description: 'Reabierta para corrección',
      );

  Invoice _transition({
    required AppUser actor,
    required DateTime at,
    required InvoiceStatus status,
    required String description,
    String? comment,
    String? rejectionReason,
    bool clearRejection = false,
  }) {
    final event = InvoiceEvent(
      at: at,
      actorId: actor.id,
      actorName: actor.fullName,
      status: status,
      description: description,
      comment: comment,
    );
    return copyWith(
      status: status,
      updatedAt: at,
      rejectionReason: rejectionReason,
      clearRejectionReason: clearRejection && rejectionReason == null,
      history: [...history, event],
    );
  }

  Invoice copyWith({
    String? id,
    String? number,
    String? supplierName,
    String? supplierTaxId,
    DateTime? issueDate,
    List<InvoiceItem>? items,
    InvoiceStatus? status,
    String? createdById,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? rejectionReason,
    bool clearRejectionReason = false,
    List<InvoiceEvent>? history,
  }) =>
      Invoice(
        id: id ?? this.id,
        number: number ?? this.number,
        supplierName: supplierName ?? this.supplierName,
        supplierTaxId: supplierTaxId ?? this.supplierTaxId,
        issueDate: issueDate ?? this.issueDate,
        items: items ?? this.items,
        status: status ?? this.status,
        createdById: createdById ?? this.createdById,
        createdByName: createdByName ?? this.createdByName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes ?? this.notes,
        rejectionReason: clearRejectionReason
            ? null
            : (rejectionReason ?? this.rejectionReason),
        history: history ?? this.history,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'supplierName': supplierName,
        'supplierTaxId': supplierTaxId,
        'issueDate': issueDate.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'status': status.id,
        'createdById': createdById,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'notes': notes,
        'rejectionReason': rejectionReason,
        'history': history.map((event) => event.toJson()).toList(),
      };

  @override
  String toString() => 'Invoice($number, ${status.id}, $totalCents)';
}
