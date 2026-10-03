import 'package:intl/intl.dart';

/// Utilidades de formato con locale colombiano explícito.
class Formatters {
  const Formatters._();

  /// Formatea centavos con separadores colombianos y dos decimales.
  static String money(int cents, {String symbol = r'$'}) {
    final format = NumberFormat.currency(
      locale: 'es_CO',
      symbol: symbol,
      decimalDigits: 2,
    );
    // Conserva el contrato visual: signo, símbolo, espacio y valor.
    final amount = format
        .format(cents.abs() / 100)
        .replaceFirst(symbol, '')
        .trim();
    return '${cents < 0 ? '-' : ''}$symbol $amount';
  }

  // Patrones numéricos fijos: en_US viene inicializado en intl y no necesita
  // descargar símbolos locales; el orden día/mes/año lo fija el patrón.
  static String date(DateTime value) =>
      DateFormat('dd/MM/yyyy', 'en_US').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('dd/MM/yyyy HH:mm', 'en_US').format(value);

  /// Convierte texto escrito por el usuario (`1.250,50` o `1250.5`) a centavos.
  ///
  /// Devuelve `null` si el texto no es un número válido.
  static int? centsFromInput(String raw) {
    var text = raw.trim().replaceAll(RegExp(r'[\s$]'), '');
    if (text.isEmpty) return null;
    final hasComma = text.contains(',');
    final hasDot = text.contains('.');
    if (hasComma && hasDot) {
      // Formato es-CO: el punto es separador de miles.
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      text = text.replaceAll(',', '.');
    }
    final value = double.tryParse(text);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return (value * 100).round();
  }

  /// Representación editable de un monto en centavos: `1234550` -> `12345,50`.
  static String centsToInput(int cents) {
    final units = cents ~/ 100;
    final decimals = (cents % 100).toString().padLeft(2, '0');
    return '$units,$decimals';
  }

  /// Porcentaje legible: `0.19` -> `19%`.
  static String percent(double rate) {
    final value = rate * 100;
    final rounded = value.roundToDouble();
    final text = (value - rounded).abs() < 0.005
        ? rounded.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$text%';
  }
}
