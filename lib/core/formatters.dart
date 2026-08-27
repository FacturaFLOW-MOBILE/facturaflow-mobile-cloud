/// Utilidades de formato sin dependencias externas (evita `intl`).
class Formatters {
  const Formatters._();

  /// Formatea un monto guardado en centavos: `123456789` -> `$ 1.234.567,89`.
  static String money(int cents, {String symbol = r'$'}) {
    final negative = cents < 0;
    final absolute = cents.abs();
    final units = absolute ~/ 100;
    final decimals = (absolute % 100).toString().padLeft(2, '0');
    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    buffer
      ..write(symbol)
      ..write(' ')
      ..write(_thousands(units))
      ..write(',')
      ..write(decimals);
    return buffer.toString();
  }

  /// `1234567` -> `1.234.567`.
  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// `2026-08-26` en formato local corto: `26/08/2026`.
  static String date(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    return '$d/$m/${value.year}';
  }

  /// Fecha y hora corta: `26/08/2026 14:05`.
  static String dateTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '${date(value)} $h:$min';
  }

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
