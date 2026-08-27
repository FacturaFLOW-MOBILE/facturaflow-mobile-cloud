import 'invoice_status.dart';

/// Entrada del historial de una factura (auditoría del flujo de aprobación).
class InvoiceEvent {
  const InvoiceEvent({
    required this.at,
    required this.actorId,
    required this.actorName,
    required this.status,
    required this.description,
    this.comment,
  });

  factory InvoiceEvent.fromJson(Map<String, dynamic> json) => InvoiceEvent(
        at: DateTime.parse(json['at'] as String),
        actorId: json['actorId'] as String,
        actorName: json['actorName'] as String,
        status: InvoiceStatus.fromId(json['status'] as String),
        description: json['description'] as String,
        comment: json['comment'] as String?,
      );

  final DateTime at;
  final String actorId;
  final String actorName;

  /// Estado en el que quedó la factura tras el evento.
  final InvoiceStatus status;
  final String description;

  /// Comentario opcional (obligatorio en los rechazos).
  final String? comment;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'actorId': actorId,
        'actorName': actorName,
        'status': status.id,
        'description': description,
        'comment': comment,
      };
}
