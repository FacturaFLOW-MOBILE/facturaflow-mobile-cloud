import 'package:factura_flow_mobile/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('money', () {
    test('agrupa miles y muestra dos decimales', () {
      expect(Formatters.money(123456789), r'$ 1.234.567,89');
      expect(Formatters.money(100), r'$ 1,00');
      expect(Formatters.money(0), r'$ 0,00');
    });

    test('conserva el signo negativo', () {
      expect(Formatters.money(-5050), r'-$ 50,50');
    });
  });

  group('centsFromInput', () {
    test('acepta formato local con punto de miles y coma decimal', () {
      expect(Formatters.centsFromInput('1.250,50'), 125050);
    });

    test('acepta formato con punto decimal', () {
      expect(Formatters.centsFromInput('1250.5'), 125050);
    });

    test('ignora espacios y símbolo de moneda', () {
      expect(Formatters.centsFromInput(r' $ 300 '), 30000);
    });

    test('devuelve null si el texto no es numérico', () {
      expect(Formatters.centsFromInput('abc'), isNull);
      expect(Formatters.centsFromInput(''), isNull);
    });

    test('acepta separadores de Colombia y Estados Unidos', () {
      for (final input in [
        '1.234.567,89',
        '1,234,567.89',
        '1234567.89',
        '1234567,89',
      ]) {
        expect(Formatters.centsFromInput(input), 123456789, reason: input);
      }
      expect(Formatters.centsFromInput('1,234'), 123400);
      expect(Formatters.centsFromInput('1.234'), 123400);
      expect(Formatters.centsFromInput('-1,250.50'), -125050);
      expect(Formatters.centsFromInput('0.01'), 1);
    });

    test('rechaza grupos mal formados y valores no finitos', () {
      for (final input in [
        '1,23,4.50',
        '1.23.4,50',
        '1,234.567',
        'NaN',
        'Infinity',
        '1e3',
        '12,',
        '1..2',
        '9223372036854775807',
      ]) {
        expect(Formatters.centsFromInput(input), isNull, reason: input);
      }
    });

    test('es la operación inversa de centsToInput', () {
      expect(
        Formatters.centsFromInput(Formatters.centsToInput(987654)),
        987654,
      );
    });
  });

  group('fechas y porcentajes', () {
    test('formatea fecha y hora en formato local', () {
      final momento = DateTime(2026, 8, 26, 14, 5);
      expect(Formatters.date(momento), '26/08/2026');
      expect(Formatters.dateTime(momento), '26/08/2026 14:05');
    });

    test('muestra el porcentaje sin decimales cuando es entero', () {
      expect(Formatters.percent(0.19), '19%');
      expect(Formatters.percent(0), '0%');
      expect(Formatters.percent(0.055), '5.50%');
    });
  });
}
