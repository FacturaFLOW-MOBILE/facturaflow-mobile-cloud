import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/app_config.dart';
import '../../core/failure.dart';
import '../../core/result.dart';

/// Cliente HTTP de la API de FacturaFlow.
///
/// Concentra lo que de otro modo se repetiría en cada repositorio remoto: la
/// URL base, la cabecera de autenticación, la serialización JSON y la
/// traducción de un error de red o de un estado HTTP a un [Failure] con un
/// mensaje presentable. Los repositorios solo describen sus endpoints.
///
/// No lanza excepciones: todas las operaciones devuelven [Result].
class ApiClient {
  ApiClient({
    required this.config,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  final AppConfig config;

  /// Tiempo máximo de espera de cada petición.
  final Duration timeout;

  final http.Client _http;

  String? _authToken;

  /// `true` cuando hay un token guardado de un inicio de sesión previo.
  bool get hasSession => _authToken != null;

  /// Guarda (o borra, con `null`) el token que acompaña a cada petición.
  ///
  /// Lo establece el repositorio de autenticación; el de facturas lo
  /// aprovecha sin conocerlo.
  void setAuthToken(String? token) => _authToken = token;

  void close() => _http.close();

  Future<Result<T>> get<T>(
    String path, {
    required T Function(Object? body) parse,
  }) =>
      _send(method: 'GET', path: path, parse: parse);

  Future<Result<T>> post<T>(
    String path, {
    required T Function(Object? body) parse,
    Object? payload,
  }) =>
      _send(method: 'POST', path: path, parse: parse, payload: payload);

  Future<Result<T>> patch<T>(
    String path, {
    required T Function(Object? body) parse,
    Object? payload,
  }) =>
      _send(method: 'PATCH', path: path, parse: parse, payload: payload);

  Future<Result<T>> delete<T>(
    String path, {
    required T Function(Object? body) parse,
  }) =>
      _send(method: 'DELETE', path: path, parse: parse);

  Future<Result<T>> _send<T>({
    required String method,
    required String path,
    required T Function(Object? body) parse,
    Object? payload,
  }) async {
    final uri = _resolve(path);
    if (uri == null) {
      return const Err(
        ConfigFailure(
          'Falta configurar API_BASE_URL. Ejecuta la app con '
          '--dart-define=DEMO_MODE=true para usar el modo demostración.',
        ),
      );
    }
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(_headers(hasPayload: payload != null));
      if (payload != null) request.body = jsonEncode(payload);

      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      final body = _decode(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Ok(parse(body));
      }
      return Err(_failureFor(response.statusCode, body));
    } on TimeoutException {
      return const Err(
        NetworkFailure('El servidor tardó demasiado en responder.'),
      );
    } on http.ClientException catch (error) {
      return Err(
        NetworkFailure('No se pudo conectar con el servidor: ${error.message}'),
      );
    } on FormatException {
      return const Err(
        NetworkFailure('El servidor devolvió una respuesta ilegible.'),
      );
    } on Object catch (error) {
      // Incluye los fallos al interpretar la respuesta con una forma
      // inesperada; mejor un mensaje claro que una excepción sin capturar.
      return Err(
        NetworkFailure('No se pudo procesar la respuesta del servidor: $error'),
      );
    }
  }

  /// Compone la URL absoluta, o `null` si falta la URL base.
  Uri? _resolve(String path) {
    if (!config.hasApiBaseUrl) return null;
    var base = config.apiBaseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.tryParse('$base$path');
  }

  Map<String, String> _headers({required bool hasPayload}) {
    final token = _authToken;
    return {
      'Accept': 'application/json',
      if (hasPayload) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Decodifica el cuerpo. Una respuesta vacía (por ejemplo un `204`) es
  /// `null`, no un error.
  Object? _decode(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  Failure _failureFor(int status, Object? body) {
    final message = _messageFrom(body);
    return switch (status) {
      400 || 422 => ValidationFailure(
          message ?? 'Los datos enviados no son válidos.',
        ),
      401 => AuthFailure(
          message ?? 'Tu sesión expiró. Vuelve a iniciar sesión.',
        ),
      403 => PermissionFailure(
          message ?? 'Tu rol no permite realizar esta acción.',
        ),
      404 => NotFoundFailure(message ?? 'No se encontró el registro.'),
      _ => NetworkFailure(
          message ?? 'El servidor respondió con un error ($status).',
        ),
    };
  }

  /// Extrae el mensaje de error que envía la API, si lo trae.
  String? _messageFrom(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    for (final key in const ['message', 'error', 'detail']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

/// Interpreta el cuerpo de una respuesta como un objeto JSON.
Map<String, dynamic> asJsonMap(Object? body) {
  if (body is Map<String, dynamic>) return body;
  throw FormatException('Se esperaba un objeto JSON, llegó: $body');
}

/// Interpreta el cuerpo de una respuesta como una lista de objetos JSON.
List<Map<String, dynamic>> asJsonList(Object? body) {
  if (body is List) {
    return body.map(asJsonMap).toList(growable: false);
  }
  throw FormatException('Se esperaba una lista JSON, llegó: $body');
}
