/// Línea de detalle de una factura.
///
/// Los montos se guardan en centavos (`int`) para evitar los errores de
/// redondeo de `double` en cálculos de dinero.
class InvoiceItem {
  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPriceCents,
    this.taxRate = 0.19,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: json['description'] as String,
        quantity: json['quantity'] as int,
        unitPriceCents: json['unitPriceCents'] as int,
        taxRate: (json['taxRate'] as num).toDouble(),
      );

  final String description;
  final int quantity;
  final int unitPriceCents;

  /// Tasa de IVA aplicada a la línea (0.19 = 19%).
  final double taxRate;

  /// Base gravable de la línea, en centavos.
  int get subtotalCents => quantity * unitPriceCents;

  /// Impuesto de la línea, en centavos.
  int get taxCents => (subtotalCents * taxRate).round();

  /// Total de la línea con impuesto, en centavos.
  int get totalCents => subtotalCents + taxCents;

  InvoiceItem copyWith({
    String? description,
    int? quantity,
    int? unitPriceCents,
    double? taxRate,
  }) =>
      InvoiceItem(
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unitPriceCents: unitPriceCents ?? this.unitPriceCents,
        taxRate: taxRate ?? this.taxRate,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPriceCents': unitPriceCents,
        'taxRate': taxRate,
      };

  @override
  bool operator ==(Object other) =>
      other is InvoiceItem &&
      other.description == description &&
      other.quantity == quantity &&
      other.unitPriceCents == unitPriceCents &&
      other.taxRate == taxRate;

  @override
  int get hashCode =>
      Object.hash(description, quantity, unitPriceCents, taxRate);
}
