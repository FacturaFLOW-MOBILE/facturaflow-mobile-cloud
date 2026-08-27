import '../core/result.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import 'base_view_model.dart';

/// Sesión activa de la aplicación.
///
/// Es el único ViewModel de alcance global: la navegación raíz decide entre
/// login y home observando [isAuthenticated].
class SessionViewModel extends BaseViewModel {
  SessionViewModel(this._authRepository);

  final AuthRepository _authRepository;

  AppUser? _user;
  bool _bootstrapped = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  /// `true` cuando ya se intentó restaurar la sesión previa.
  bool get isBootstrapped => _bootstrapped;

  /// Cuentas de prueba disponibles (vacío fuera del modo demostración).
  List<DemoAccount> get demoAccounts => _authRepository.demoAccounts;

  /// Restaura la sesión guardada al abrir la app.
  Future<void> bootstrap() async {
    final result = await runGuarded(_authRepository.restoreSession);
    _user = result.valueOrNull;
    _bootstrapped = true;
    notifyListeners();
  }

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await runGuarded(
      () => _authRepository.signIn(email: email, password: password),
    );
    if (result case Ok(:final value)) {
      _user = value;
      notifyListeners();
    }
    return result;
  }

  Future<void> signOut() async {
    await runGuarded(_authRepository.signOut);
    _user = null;
    notifyListeners();
  }
}
