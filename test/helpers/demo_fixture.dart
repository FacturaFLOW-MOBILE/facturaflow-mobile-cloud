import 'package:factura_flow_mobile/data/models/app_user.dart';
import 'package:factura_flow_mobile/data/models/user_role.dart';
import 'package:factura_flow_mobile/data/repositories/auth_repository.dart';

/// Datos ficticios que alimentan el modo demostración.
///
/// No hay red ni base de datos: todo se genera aquí y vive en memoria
/// mientras la app está abierta.
class DemoFixture {
  const DemoFixture._();

  static const String password = 'demo1234';

  static const AppUser emisor = AppUser(
    id: 'u-ana',
    fullName: 'Ana Torres',
    email: 'ana@facturaflow.demo',
    role: UserRole.emisor,
  );

  static const AppUser contador = AppUser(
    id: 'u-carlos',
    fullName: 'Carlos Ruiz',
    email: 'carlos@facturaflow.demo',
    role: UserRole.contador,
  );

  static const AppUser administrador = AppUser(
    id: 'u-lucia',
    fullName: 'Lucía Peña',
    email: 'lucia@facturaflow.demo',
    role: UserRole.administrador,
  );

  static const List<AppUser> users = [emisor, contador, administrador];

  static List<DemoAccount> get accounts => users
      .map(
        (user) =>
            DemoAccount(email: user.email, password: password, user: user),
      )
      .toList(growable: false);
}
