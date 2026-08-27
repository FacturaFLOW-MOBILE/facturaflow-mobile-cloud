import '../../core/result.dart';
import '../models/app_user.dart';

/// Credencial sugerida que la pantalla de login puede ofrecer con un toque.
/// Solo el repositorio demo devuelve valores aquí.
class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.user,
  });

  final String email;
  final String password;
  final AppUser user;
}

/// Contrato de autenticación. La UI nunca conoce la implementación concreta.
abstract class AuthRepository {
  /// Inicia sesión y devuelve el usuario autenticado.
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  /// Cierra la sesión activa.
  Future<Result<void>> signOut();

  /// Recupera la sesión previa, o `null` si no hay ninguna.
  Future<Result<AppUser?>> restoreSession();

  /// Cuentas de prueba mostradas en modo demostración.
  List<DemoAccount> get demoAccounts => const [];
}
