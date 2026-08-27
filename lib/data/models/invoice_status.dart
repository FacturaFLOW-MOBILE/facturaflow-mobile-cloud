/// Estados del ciclo de vida de una factura.
///
/// Flujo:
/// `borrador` --enviar--> `enviada` --aprobar--> `aprobada`
///                              \--rechazar--> `rechazada` --corregir--> `borrador`
enum InvoiceStatus {
  borrador('borrador', 'Borrador'),
  enviada('enviada', 'En revisión'),
  aprobada('aprobada', 'Aprobada'),
  rechazada('rechazada', 'Rechazada');

  const InvoiceStatus(this.id, this.label);

  final String id;
  final String label;

  static InvoiceStatus fromId(String id) => InvoiceStatus.values.firstWhere(
        (status) => status.id == id,
        orElse: () => InvoiceStatus.borrador,
      );

  /// Estados desde los que el emisor todavía puede editar el contenido.
  bool get isEditable =>
      this == InvoiceStatus.borrador || this == InvoiceStatus.rechazada;

  /// Estado final: ya no admite transiciones.
  bool get isFinal =>
      this == InvoiceStatus.aprobada || this == InvoiceStatus.rechazada;
}
