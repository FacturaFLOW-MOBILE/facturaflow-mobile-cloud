import '../../core/failure.dart';
import '../../core/result.dart';
import '../models/app_user.dart';
import '../models/invoice.dart';
import '../repositories/auth_repository.dart';
import '../repositories/invoice_repository.dart';
import 'api_client.dart';

/// Implementaciones para el modo servidor
/// (`--dart-define=DEMO_MODE=false`).
///
/// Hablan con la API a través de [ApiClient], que es quien traduce los
/// errores de red y los estados HTTP a [Failure]. Endpoints usados:
///
///   POST   /auth/login
///   POST   /auth/logout
///   GET    /auth/me
///   GET    /invoices
///   GET    /invoices/{id}
///   POST   /invoices
///   PATCH  /invoices/{id}
///   POST   /invoices/{id}/submit | /approve | /reject | /reopen
///   DELETE /invoices/{id}
class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this._api);

  final ApiClient _api;

  /// Fuera del modo demostración no se ofrecen cuentas de prueba.
  @override
  List<DemoAccount> get demoAccounts => const [];

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _api.post<_Session>(
      '/auth/login',
      payload: {'email': email.trim(), 'password': password},
      parse: (body) => _Session.fromJson(asJsonMap(body)),
    );
    switch (result) {
      case Ok(:final value):
        // A partir de aquí el cliente firma todas las peticiones, incluidas
        // las del repositorio de facturas.
        _api.setAuthToken(value.token);
        return Ok(value.user);
      case Err(:final failure):
        return Err(failure);
    }
  }

  @override
  Future<Result<void>> signOut() async {
    // Se avisa al servidor, pero la sesión local se cierra en cualquier caso:
    // dejar al usuario dentro porque el logout remoto falló sería peor.
    if (_api.hasSession) {
      await _api.post<void>('/auth/logout', parse: (_) {});
      _api.setAuthToken(null);
    }
    return const Ok(null);
  }

  @override
  Future<Result<AppUser?>> restoreSession() async {
    if (!_api.hasSession) return const Ok(null);
    final result = await _api.get<AppUser>(
      '/auth/me',
      parse: (body) => AppUser.fromJson(asJsonMap(body)),
    );
    switch (result) {
      case Ok(:final value):
        return Ok(value);
      case Err(:final failure):
        if (failure is AuthFailure) {
          // El token caducó: no hay sesión que restaurar, pero tampoco es un
          // error que mostrarle al usuario al abrir la app.
          _api.setAuthToken(null);
          return const Ok(null);
        }
        return Err(failure);
    }
  }
}

/// Respuesta de `POST /auth/login`.
class _Session {
  const _Session({required this.token, required this.user});

  factory _Session.fromJson(Map<String, dynamic> json) => _Session(
        token: json['token'] as String,
        user: AppUser.fromJson(asJsonMap(json['user'])),
      );

  final String token;
  final AppUser user;
}

/// Contraparte de [RemoteAuthRepository] para facturas.
class RemoteInvoiceRepository implements InvoiceRepository {
  const RemoteInvoiceRepository(this._api);

  final ApiClient _api;

  /// El alcance por rol lo decide el servidor a partir del token, así que
  /// [user] no viaja en la petición.
  @override
  Future<Result<List<Invoice>>> fetchAll(AppUser user) => _api.get(
        '/invoices',
        parse: (body) =>
            asJsonList(body).map(Invoice.fromJson).toList(growable: false),
      );

  @override
  Future<Result<Invoice>> getById(String id) => _api.get(
        '/invoices/${_segment(id)}',
        parse: _invoice,
      );

  @override
  Future<Result<Invoice>> create(InvoiceDraft draft, AppUser actor) => _api.post(
        '/invoices',
        payload: _draftPayload(draft),
        parse: _invoice,
      );

  @override
  Future<Result<Invoice>> update(
    String id,
    InvoiceDraft draft,
    AppUser actor,
  ) =>
      _api.patch(
        '/invoices/${_segment(id)}',
        payload: _draftPayload(draft),
        parse: _invoice,
      );

  @override
  Future<Result<Invoice>> submit(String id, AppUser actor) => _api.post(
        '/invoices/${_segment(id)}/submit',
        parse: _invoice,
      );

  @override
  Future<Result<Invoice>> approve(
    String id,
    AppUser actor, {
    String? comment,
  }) =>
      _api.post(
        '/invoices/${_segment(id)}/approve',
        payload: {'comment': ?comment},
        parse: _invoice,
      );

  @override
  Future<Result<Invoice>> reject(
    String id,
    AppUser actor, {
    required String reason,
  }) async {
    // Misma regla que el resto de la app (ver [Invoice.rejectionReasonError]),
    // aplicada antes de salir a la red: un rechazo sin justificar no es una
    // petición que valga la pena hacer.
    final problem = Invoice.rejectionReasonError(reason);
    if (problem != null) {
      return Err(ValidationFailure(problem));
    }
    return _api.post(
      '/invoices/${_segment(id)}/reject',
      payload: {'reason': reason.trim()},
      parse: _invoice,
    );
  }

  @override
  Future<Result<Invoice>> reopen(String id, AppUser actor) => _api.post(
        '/invoices/${_segment(id)}/reopen',
        parse: _invoice,
      );

  @override
  Future<Result<void>> delete(String id, AppUser actor) => _api.delete<void>(
        '/invoices/${_segment(id)}',
        parse: (_) {},
      );

  static Invoice _invoice(Object? body) => Invoice.fromJson(asJsonMap(body));

  static String _segment(String id) => Uri.encodeComponent(id);

  static Map<String, dynamic> _draftPayload(InvoiceDraft draft) => {
        'number': draft.number.trim(),
        'supplierName': draft.supplierName.trim(),
        'supplierTaxId': draft.supplierTaxId.trim(),
        'issueDate': draft.issueDate.toIso8601String(),
        'items': draft.items.map((item) => item.toJson()).toList(),
        'notes': draft.notes.trim(),
      };
}
