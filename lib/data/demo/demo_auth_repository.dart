import '../../app/app_config.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'demo_seed.dart';

/// Autenticación en memoria para el modo demostración.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({AppConfig? config})
      : _config = config ?? AppConfig.fromEnvironment();

  final AppConfig _config;

  AppUser? _currentUser;

  @override
  List<DemoAccount> get demoAccounts => DemoSeed.accounts;

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    await _delay();
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return const Err(ValidationFailure('Ingresa tu correo y contraseña.'));
    }
    for (final account in DemoSeed.accounts) {
      if (account.email.toLowerCase() != normalized) continue;
      if (account.password != password) break;
      _currentUser = account.user;
      return Ok(account.user);
    }
    return const Err(AuthFailure());
  }

  @override
  Future<Result<void>> signOut() async {
    await _delay();
    _currentUser = null;
    return const Ok(null);
  }

  @override
  Future<Result<AppUser?>> restoreSession() async {
    await _delay();
    return Ok(_currentUser);
  }

  Future<void> _delay() {
    if (_config.simulatedLatency == Duration.zero) return Future.value();
    return Future<void>.delayed(_config.simulatedLatency);
  }
}
