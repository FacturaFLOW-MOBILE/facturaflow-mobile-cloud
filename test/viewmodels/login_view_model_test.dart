import 'package:factura_flow_mobile/app/app_config.dart';
import 'package:factura_flow_mobile/data/demo/demo_auth_repository.dart';
import 'package:factura_flow_mobile/data/demo/demo_seed.dart';
import 'package:factura_flow_mobile/viewmodels/login_view_model.dart';
import 'package:factura_flow_mobile/viewmodels/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionViewModel session;
  late LoginViewModel viewModel;

  setUp(() {
    session = SessionViewModel(DemoAuthRepository(config: AppConfig.test()));
    viewModel = LoginViewModel(session);
  });

  tearDown(() {
    viewModel.dispose();
    session.dispose();
  });

  group('Validación', () {
    test('exige un correo con formato válido', () {
      expect(viewModel.validateEmail(''), isNotNull);
      expect(viewModel.validateEmail('sin-arroba'), isNotNull);
      expect(viewModel.validateEmail('ana@facturaflow.demo'), isNull);
    });

    test('exige una contraseña de al menos 6 caracteres', () {
      expect(viewModel.validatePassword(''), isNotNull);
      expect(viewModel.validatePassword('123'), isNotNull);
      expect(viewModel.validatePassword('demo1234'), isNull);
    });
  });

  group('submit', () {
    test('no llama al repositorio si el formulario es inválido', () async {
      viewModel.setEmail('correo-malo');
      viewModel.setPassword('123');

      final result = await viewModel.submit();

      expect(result.isErr, isTrue);
      expect(session.isAuthenticated, isFalse);
      expect(viewModel.hasError, isTrue);
    });

    test('inicia sesión con una cuenta demo y llena la sesión', () async {
      viewModel.useDemoAccount(DemoSeed.emisor.email, DemoSeed.password);

      final result = await viewModel.submit();

      expect(result.isOk, isTrue);
      expect(session.user, DemoSeed.emisor);
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.hasError, isFalse);
    });

    test('muestra error con credenciales incorrectas', () async {
      viewModel.setEmail(DemoSeed.emisor.email);
      viewModel.setPassword('contraseña-incorrecta');

      final result = await viewModel.submit();

      expect(result.isErr, isTrue);
      expect(viewModel.errorMessage, contains('incorrectos'));
      expect(session.isAuthenticated, isFalse);
    });

    test('cerrar sesión limpia el usuario actual', () async {
      viewModel.useDemoAccount(DemoSeed.contador.email, DemoSeed.password);
      await viewModel.submit();
      expect(session.isAuthenticated, isTrue);

      await session.signOut();

      expect(session.isAuthenticated, isFalse);
      expect(session.user, isNull);
    });
  });
}
