// Pruebas de los repositorios remotos: endpoint, método y cuerpo de cada
// operación, y el token compartido entre autenticación y facturas.
import 'dart:convert';

import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/core/failure.dart';
import 'package:factura_flow_mobile/data/models/invoice.dart';
import 'package:factura_flow_mobile/data/remote/api_client.dart';
import 'package:factura_flow_mobile/data/remote/remote_repositories.dart';
import 'package:factura_flow_mobile/data/repositories/invoice_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fixtures.dart';

void main() {
  const config = AppConfig(
    demoMode: false,
    apiBaseUrl: 'https://api.facturaflow.test',
  );

  late List<http.Request> peticiones;

  /// Construye un cliente que responde según la ruta pedida.
  ApiClient clientFor(
    http.Response Function(http.Request request) responder,
  ) {
    peticiones = [];
    return ApiClient(
      config: config,
      httpClient: MockClient((request) async {
        peticiones.add(request);
        return responder(request);
      }),
    );
  }

  /// Respuesta con la factura de prueba serializada.
  http.Response okInvoice() => http.Response(
        jsonEncode(buildInvoice(id: 'inv-1', number: 'FE-1').toJson()),
        200,
      );

  final draft = InvoiceDraft(
    number: '  FE-1  ',
    supplierName: '  Proveedor  ',
    supplierTaxId: ' 900123456-7 ',
    issueDate: fechaFija,
    items: const [
      InvoiceItem(
        description: 'Consultoría',
        quantity: 2,
        unitPriceCents: 500000,
      ),
    ],
    notes: '  Nota  ',
  );

  group('RemoteAuthRepository', () {
    test('signIn guarda el token y devuelve el usuario', () async {
      final api = clientFor(
        (_) => http.Response(
          jsonEncode({'token': 'tok-1', 'user': emisor.toJson()}),
          200,
        ),
      );
      final auth = RemoteAuthRepository(api);

      final result = await auth.signIn(
        email: ' ANA@facturaflow.demo ',
        password: 'demo1234',
      );

      expect(result.valueOrNull, emisor);
      expect(api.hasSession, isTrue);
      expect(peticiones.single.url.path, '/auth/login');
      expect(peticiones.single.method, 'POST');
      // El correo viaja sin espacios sobrantes.
      expect(
        jsonDecode(peticiones.single.body),
        {'email': 'ANA@facturaflow.demo', 'password': 'demo1234'},
      );
    });

    test('unas credenciales incorrectas no abren sesión', () async {
      final api = clientFor(
        (_) => http.Response('{"message":"Correo o contraseña"}', 401),
      );
      final auth = RemoteAuthRepository(api);

      final result = await auth.signIn(email: 'a@b.test', password: 'mala');

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(api.hasSession, isFalse);
    });

    test('el token firma también las llamadas de facturas', () async {
      final api = clientFor(
        (request) => request.url.path == '/auth/login'
            ? http.Response(
                jsonEncode({'token': 'tok-1', 'user': emisor.toJson()}),
                200,
              )
            : http.Response('[]', 200),
      );

      await RemoteAuthRepository(api)
          .signIn(email: 'ana@facturaflow.demo', password: 'demo1234');
      await RemoteInvoiceRepository(api).fetchAll(emisor);

      expect(peticiones.last.url.path, '/invoices');
      expect(peticiones.last.headers['Authorization'], 'Bearer tok-1');
    });

    test('sin sesión previa, restoreSession no sale a la red', () async {
      final api = clientFor((_) => http.Response('{}', 200));

      final result = await RemoteAuthRepository(api).restoreSession();

      expect(result.valueOrNull, isNull);
      expect(peticiones, isEmpty);
    });

    test('restoreSession recupera al usuario del token vigente', () async {
      final api = clientFor(
        (_) => http.Response(jsonEncode(contador.toJson()), 200),
      )..setAuthToken('tok-1');

      final result = await RemoteAuthRepository(api).restoreSession();

      expect(result.valueOrNull, contador);
      expect(peticiones.single.url.path, '/auth/me');
    });

    test('un token caducado se descarta sin mostrar error', () async {
      final api = clientFor((_) => http.Response('{}', 401))
        ..setAuthToken('tok-viejo');

      final result = await RemoteAuthRepository(api).restoreSession();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
      expect(api.hasSession, isFalse);
    });

    test('signOut avisa al servidor y cierra la sesión local', () async {
      final api = clientFor((_) => http.Response('', 204))
        ..setAuthToken('tok-1');

      final result = await RemoteAuthRepository(api).signOut();

      expect(result.isOk, isTrue);
      expect(api.hasSession, isFalse);
      expect(peticiones.single.url.path, '/auth/logout');
    });

    test('si el logout remoto falla, la sesión local se cierra igual',
        () async {
      final api = clientFor((_) => http.Response('', 500))
        ..setAuthToken('tok-1');

      final result = await RemoteAuthRepository(api).signOut();

      expect(result.isOk, isTrue);
      expect(api.hasSession, isFalse);
    });

    test('fuera del modo demostración no hay cuentas de prueba', () {
      final api = clientFor((_) => http.Response('{}', 200));
      expect(RemoteAuthRepository(api).demoAccounts, isEmpty);
    });
  });

  group('RemoteInvoiceRepository', () {
    test('fetchAll pide la lista y la convierte en facturas', () async {
      final api = clientFor(
        (_) => http.Response(
          jsonEncode([
            buildInvoice(id: 'inv-1', number: 'FE-1').toJson(),
            buildInvoice(id: 'inv-2', number: 'FE-2').toJson(),
          ]),
          200,
        ),
      );

      final result = await RemoteInvoiceRepository(api).fetchAll(emisor);

      expect(result.valueOrNull, hasLength(2));
      expect(result.valueOrNull!.first.number, 'FE-1');
      expect(peticiones.single.url.path, '/invoices');
      expect(peticiones.single.method, 'GET');
    });

    test('getById consulta la factura por su id', () async {
      final api = clientFor((_) => okInvoice());

      final result = await RemoteInvoiceRepository(api).getById('inv-1');

      expect(result.valueOrNull?.id, 'inv-1');
      expect(peticiones.single.url.path, '/invoices/inv-1');
    });

    test('create envía el borrador ya normalizado', () async {
      final api = clientFor((_) => okInvoice());

      await RemoteInvoiceRepository(api).create(draft, emisor);

      final enviado = jsonDecode(peticiones.single.body) as Map<String, dynamic>;
      expect(peticiones.single.method, 'POST');
      expect(peticiones.single.url.path, '/invoices');
      expect(enviado['number'], 'FE-1');
      expect(enviado['supplierTaxId'], '900123456-7');
      expect(enviado['notes'], 'Nota');
      expect(enviado['items'], hasLength(1));
    });

    test('update usa PATCH sobre la factura', () async {
      final api = clientFor((_) => okInvoice());

      await RemoteInvoiceRepository(api).update('inv-1', draft, emisor);

      expect(peticiones.single.method, 'PATCH');
      expect(peticiones.single.url.path, '/invoices/inv-1');
    });

    test('las transiciones usan su propio endpoint', () async {
      final api = clientFor((_) => okInvoice());
      final repository = RemoteInvoiceRepository(api);

      await repository.submit('inv-1', emisor);
      await repository.approve('inv-1', contador, comment: 'Todo en orden');
      await repository.reject('inv-1', contador, reason: 'Falta el soporte');
      await repository.reopen('inv-1', emisor);

      expect(
        peticiones.map((p) => '${p.method} ${p.url.path}'),
        [
          'POST /invoices/inv-1/submit',
          'POST /invoices/inv-1/approve',
          'POST /invoices/inv-1/reject',
          'POST /invoices/inv-1/reopen',
        ],
      );
      expect(jsonDecode(peticiones[1].body), {'comment': 'Todo en orden'});
      expect(jsonDecode(peticiones[2].body), {'reason': 'Falta el soporte'});
    });

    test('aprobar sin comentario no envía el campo', () async {
      final api = clientFor((_) => okInvoice());

      await RemoteInvoiceRepository(api).approve('inv-1', contador);

      expect(jsonDecode(peticiones.single.body), isEmpty);
    });

    test('un rechazo sin motivo no llega a la red', () async {
      final api = clientFor((_) => okInvoice());

      final result = await RemoteInvoiceRepository(api).reject(
        'inv-1',
        contador,
        reason: '   ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(peticiones, isEmpty);
    });

    test('el rechazo aplica la misma regla de longitud que el resto de la app',
        () async {
      final api = clientFor((_) => okInvoice());

      final result = await RemoteInvoiceRepository(api).reject(
        'inv-1',
        contador,
        reason: '.',
      );

      // La regla vive en Invoice, no duplicada aquí.
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull!.message,
        Invoice.rejectionReasonError('.'),
      );
      expect(peticiones, isEmpty);
    });

    test('delete usa DELETE y acepta una respuesta vacía', () async {
      final api = clientFor((_) => http.Response('', 204));

      final result = await RemoteInvoiceRepository(api).delete('inv-1', emisor);

      expect(result.isOk, isTrue);
      expect(peticiones.single.method, 'DELETE');
      expect(peticiones.single.url.path, '/invoices/inv-1');
    });

    test('los ids con caracteres especiales se escapan en la URL', () async {
      final api = clientFor((_) => okInvoice());

      await RemoteInvoiceRepository(api).getById('inv/1 2');

      expect(peticiones.single.url.toString(), endsWith('/invoices/inv%2F1%202'));
    });

    test('el error del servidor se propaga como Failure, no como excepción',
        () async {
      final api = clientFor(
        (_) => http.Response('{"message":"El número ya existe."}', 422),
      );

      final result = await RemoteInvoiceRepository(api).create(draft, emisor);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, 'El número ya existe.');
    });
  });
}
