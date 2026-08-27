import '../../app/app_config.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../models/app_user.dart';
import '../models/invoice.dart';
import '../repositories/auth_repository.dart';
import '../repositories/invoice_repository.dart';

/// Implementaciones para el modo servidor (`--dart-define=DEMO_MODE=false`).
///
/// La capa HTTP todavía no está implementada: estas clases existen para que el
/// resto de la app compile contra el mismo contrato y para dejar el punto de
/// extensión evidente. Cada método devuelve un [Failure] explicando la
/// situación en vez de fallar de forma silenciosa.
///
/// TODO(backend): implementar con `package:http` contra [AppConfig.apiBaseUrl]:
///   POST   /auth/login
///   GET    /invoices
///   POST   /invoices
///   PATCH  /invoices/{id}
///   POST   /invoices/{id}/submit | /approve | /reject | /reopen
///   DELETE /invoices/{id}
class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this.config);

  final AppConfig config;

  @override
  List<DemoAccount> get demoAccounts => const [];

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async =>
      Err(_notImplemented());

  @override
  Future<Result<void>> signOut() async => const Ok(null);

  @override
  Future<Result<AppUser?>> restoreSession() async => const Ok(null);

  Failure _notImplemented() => config.hasApiBaseUrl
      ? const NetworkFailure(
          'El cliente HTTP aún no está implementado. Ejecuta la app en modo '
          'demostración (DEMO_MODE=true).',
        )
      : const ConfigFailure(
          'Falta configurar API_BASE_URL. Ejecuta la app con '
          '--dart-define=DEMO_MODE=true para usar el modo demostración.',
        );
}

/// Contraparte de [RemoteAuthRepository] para facturas.
class RemoteInvoiceRepository implements InvoiceRepository {
  const RemoteInvoiceRepository(this.config);

  final AppConfig config;

  @override
  Future<Result<List<Invoice>>> fetchAll(AppUser user) async =>
      Err(_notImplemented());

  @override
  Future<Result<Invoice>> getById(String id) async => Err(_notImplemented());

  @override
  Future<Result<Invoice>> create(InvoiceDraft draft, AppUser actor) async =>
      Err(_notImplemented());

  @override
  Future<Result<Invoice>> update(
    String id,
    InvoiceDraft draft,
    AppUser actor,
  ) async =>
      Err(_notImplemented());

  @override
  Future<Result<Invoice>> submit(String id, AppUser actor) async =>
      Err(_notImplemented());

  @override
  Future<Result<Invoice>> approve(
    String id,
    AppUser actor, {
    String? comment,
  }) async =>
      Err(_notImplemented());

  @override
  Future<Result<Invoice>> reject(
    String id,
    AppUser actor, {
    required String reason,
  }) async =>
      Err(_notImplemented());

  @override
  Future<Result<Invoice>> reopen(String id, AppUser actor) async =>
      Err(_notImplemented());

  @override
  Future<Result<void>> delete(String id, AppUser actor) async =>
      Err(_notImplemented());

  Failure _notImplemented() => config.hasApiBaseUrl
      ? const NetworkFailure(
          'El cliente HTTP aún no está implementado. Ejecuta la app en modo '
          'demostración (DEMO_MODE=true).',
        )
      : const ConfigFailure(
          'Falta configurar API_BASE_URL. Ejecuta la app con '
          '--dart-define=DEMO_MODE=true para usar el modo demostración.',
        );
}
