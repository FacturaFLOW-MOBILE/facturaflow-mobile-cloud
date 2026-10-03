// Pruebas del cliente HTTP: composición de la petición y traducción de
// errores de red y de estado HTTP a Failure.
import 'dart:convert';

import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/core/failure.dart';
import 'package:factura_flow_mobile/data/remote/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const config = AppConfig(
    demoMode: false,
    apiBaseUrl: 'https://api.facturaflow.test',
  );

  /// Cliente que responde siempre lo mismo y guarda la última petición.
  ({ApiClient api, List<http.Request> peticiones}) clientThatReturns(
    http.Response response, {
    AppConfig appConfig = config,
  }) {
    final peticiones = <http.Request>[];
    final api = ApiClient(
      config: appConfig,
      httpClient: MockClient((request) async {
        peticiones.add(request);
        return response;
      }),
    );
    return (api: api, peticiones: peticiones);
  }

  group('Composición de la petición', () {
    test('resuelve la URL contra la base y pide JSON', () async {
      final f = clientThatReturns(http.Response('{"ok":true}', 200));

      await f.api.get<Object?>('/invoices', parse: (body) => body);

      expect(
        f.peticiones.single.url.toString(),
        'https://api.facturaflow.test/invoices',
      );
      expect(f.peticiones.single.method, 'GET');
      expect(f.peticiones.single.headers['Accept'], 'application/json');
    });

    test('no duplica la barra si la URL base termina en "/"', () async {
      final f = clientThatReturns(
        http.Response('{}', 200),
        appConfig: const AppConfig(
          demoMode: false,
          apiBaseUrl: 'https://api.facturaflow.test/',
        ),
      );

      await f.api.get<Object?>('/invoices', parse: (body) => body);

      expect(
        f.peticiones.single.url.toString(),
        'https://api.facturaflow.test/invoices',
      );
    });

    test('envía el cuerpo como JSON y declara el Content-Type', () async {
      final f = clientThatReturns(http.Response('{}', 201));

      await f.api.post<Object?>(
        '/invoices',
        payload: {'number': 'FE-1'},
        parse: (body) => body,
      );

      final peticion = f.peticiones.single;
      expect(peticion.method, 'POST');
      expect(peticion.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(peticion.body), {'number': 'FE-1'});
    });

    test('firma la petición solo cuando hay token', () async {
      final f = clientThatReturns(http.Response('{}', 200));

      await f.api.get<Object?>('/auth/me', parse: (body) => body);
      expect(f.peticiones.last.headers.containsKey('Authorization'), isFalse);

      f.api.setAuthToken('token-123');
      await f.api.get<Object?>('/auth/me', parse: (body) => body);
      expect(f.peticiones.last.headers['Authorization'], 'Bearer token-123');

      f.api.setAuthToken(null);
      await f.api.get<Object?>('/auth/me', parse: (body) => body);
      expect(f.peticiones.last.headers.containsKey('Authorization'), isFalse);
    });

    test('una respuesta vacía se interpreta como null, no como error',
        () async {
      final f = clientThatReturns(http.Response('', 204));

      final result = await f.api.delete<Object?>(
        '/invoices/inv-1',
        parse: (body) => body,
      );

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  group('Traducción de errores', () {
    test('sin API_BASE_URL devuelve ConfigFailure y no sale a la red',
        () async {
      final f = clientThatReturns(
        http.Response('{}', 200),
        appConfig: const AppConfig(demoMode: false, apiBaseUrl: ''),
      );

      final result = await f.api.get<Object?>(
        '/invoices',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<ConfigFailure>());
      expect(f.peticiones, isEmpty);
    });

    test('400 y 422 son errores de validación', () async {
      for (final status in [400, 422]) {
        final f = clientThatReturns(
          http.Response('{"message":"El número ya existe."}', status),
        );

        final result = await f.api.post<Object?>(
          '/invoices',
          parse: (body) => body,
        );

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, 'El número ya existe.');
      }
    });

    test('401 es un fallo de autenticación', () async {
      final f = clientThatReturns(http.Response('{}', 401));

      final result = await f.api.get<Object?>(
        '/invoices',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('403 es un fallo de permisos', () async {
      final f = clientThatReturns(http.Response('{}', 403));

      final result = await f.api.get<Object?>(
        '/invoices',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('404 es un recurso inexistente', () async {
      final f = clientThatReturns(http.Response('{}', 404));

      final result = await f.api.get<Object?>(
        '/invoices/inv-zzz',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('un 500 se presenta como fallo de red', () async {
      final f = clientThatReturns(http.Response('', 500));

      final result = await f.api.get<Object?>(
        '/invoices',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull!.message, contains('500'));
    });

    test('una caída de conexión no se propaga como excepción', () async {
      final api = ApiClient(
        config: config,
        httpClient: MockClient(
          (_) async => throw http.ClientException('Connection refused'),
        ),
      );

      final result = await api.get<Object?>(
        '/invoices',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull!.message, contains('Connection refused'));
    });

    test('un cuerpo que no es JSON no rompe la app', () async {
      final f = clientThatReturns(http.Response('<html>502</html>', 200));

      final result = await f.api.get<Object?>(
        '/invoices',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('una respuesta con forma inesperada se reporta como fallo', () async {
      final f = clientThatReturns(http.Response('[1,2,3]', 200));

      final result = await f.api.get<Map<String, dynamic>>(
        '/auth/me',
        parse: asJsonMap,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('el tiempo de espera agotado se reporta como fallo de red', () async {
      final api = ApiClient(
        config: config,
        timeout: const Duration(milliseconds: 20),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 2));
          return http.Response('{}', 200);
        }),
      );

      final result = await api.get<Object?>(
        '/invoices',
        parse: (body) => body,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull!.message, contains('tardó demasiado'));
    });
  });
}
