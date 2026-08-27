/// Errores de dominio con mensajes listos para mostrar al usuario.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// El recurso solicitado no existe.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No se encontró el registro.']);
}

/// Credenciales inválidas o sesión expirada.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Correo o contraseña incorrectos.']);
}

/// El usuario no tiene permiso para ejecutar la acción.
final class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Tu rol no permite realizar esta acción.',
  ]);
}

/// Los datos enviados no cumplen las reglas de negocio.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Fallo de red o del servidor.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No se pudo conectar con el servidor. Revisa tu conexión.',
  ]);
}

/// Configuración incompleta (por ejemplo, backend sin URL en modo real).
final class ConfigFailure extends Failure {
  const ConfigFailure(super.message);
}
