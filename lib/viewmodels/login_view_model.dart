import '../core/failure.dart';
import '../core/result.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import 'base_view_model.dart';
import 'session_view_model.dart';

/// Estado del formulario de inicio de sesión.
class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._session);

  final SessionViewModel _session;

  String _email = '';
  String _password = '';
  bool _obscurePassword = true;

  String get email => _email;
  String get password => _password;
  bool get obscurePassword => _obscurePassword;

  /// Cuentas sugeridas del modo demostración.
  List<DemoAccount> get demoAccounts => _session.demoAccounts;

  void setEmail(String value) {
    _email = value;
    clearError();
  }

  void setPassword(String value) {
    _password = value;
    clearError();
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Rellena el formulario con una cuenta de prueba.
  void useDemoAccount(String email, String password) {
    _email = email;
    _password = password;
    clearError();
    notifyListeners();
  }

  /// Mensaje de error del campo correo, o `null` si es válido.
  String? validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Ingresa tu correo.';
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(text)) return 'El correo no tiene un formato válido.';
    return null;
  }

  /// Mensaje de error del campo contraseña, o `null` si es válido.
  String? validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresa tu contraseña.';
    if (text.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  bool get isValid =>
      validateEmail(_email) == null && validatePassword(_password) == null;

  /// Intenta iniciar sesión. La vista navega solo si el resultado es [Ok].
  Future<Result<AppUser>> submit() async {
    final emailError = validateEmail(_email);
    final passwordError = validatePassword(_password);
    final firstError = emailError ?? passwordError;
    if (firstError != null) {
      setError(firstError);
      return Err(ValidationFailure(firstError));
    }
    setBusy();
    final result = await _session.signIn(email: _email, password: _password);
    if (isDisposed) return result;
    switch (result) {
      case Ok<AppUser>():
        setIdle();
      case Err<AppUser>(:final failure):
        setError(failure.message);
    }
    return result;
  }
}
