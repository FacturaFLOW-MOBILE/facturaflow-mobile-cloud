import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/invoice.dart';
import '../views/home_view.dart';
import '../views/invoice_detail_view.dart';
import '../views/invoice_form_view.dart';
import '../views/login_view.dart';
import '../views/root_view.dart';

/// Rutas de la aplicación.
///
/// Cada destino declara su nombre y su patrón de URL en un solo sitio: las
/// vistas navegan por la extensión [AppNavigation] y nunca escriben una ruta
/// a mano.
enum AppRoute {
  root('root', '/'),
  login('login', '/login'),
  home('home', '/home'),

  /// El formulario se declara con una ruta propia, sin parámetro, para que no
  /// compita con el patrón del detalle.
  invoiceForm('invoice-form', '/invoices/form'),
  invoiceDetail('invoice-detail', '/invoices/detail/:$invoiceIdParam');

  const AppRoute(this.routeName, this.path);

  /// Nombre del parámetro de ruta que identifica la factura.
  static const String invoiceIdParam = 'id';

  /// Nombre con el que `go_router` resuelve el destino.
  final String routeName;

  /// Patrón de URL del destino.
  final String path;
}

/// Construye el enrutador de la aplicación.
///
/// La tabla es declarativa: agregar un destino es agregar un [GoRoute], no
/// extender una cadena de `case`.
class AppRouter {
  const AppRouter._();

  static GoRouter create() => GoRouter(
        initialLocation: AppRoute.root.path,
        routes: [
          GoRoute(
            name: AppRoute.root.routeName,
            path: AppRoute.root.path,
            builder: (_, _) => const RootView(),
          ),
          GoRoute(
            name: AppRoute.login.routeName,
            path: AppRoute.login.path,
            builder: (_, _) => const LoginView(),
          ),
          GoRoute(
            name: AppRoute.home.routeName,
            path: AppRoute.home.path,
            builder: (_, _) => const HomeView(),
          ),
          GoRoute(
            name: AppRoute.invoiceForm.routeName,
            path: AppRoute.invoiceForm.path,
            // `extra` trae la factura a editar; si es null, se crea una nueva.
            builder: (_, state) =>
                InvoiceFormView(existing: state.extra as Invoice?),
          ),
          GoRoute(
            name: AppRoute.invoiceDetail.routeName,
            path: AppRoute.invoiceDetail.path,
            builder: (_, state) => InvoiceDetailView(
              invoiceId: state.pathParameters[AppRoute.invoiceIdParam]!,
              // La lista ya tiene la factura cargada: se pasa para pintar el
              // detalle sin esperar a la recarga.
              initial: state.extra as Invoice?,
            ),
          ),
        ],
        errorBuilder: (_, state) => RouteErrorView(
          message: 'La ruta ${state.uri} no existe.',
        ),
      );
}

/// Navegación tipada.
///
/// Las vistas llaman a estos métodos en vez de componer rutas con cadenas y
/// castear `arguments`: el destino y el tipo del resultado quedan fijados aquí.
extension AppNavigation on BuildContext {
  /// Abre el detalle de [invoice]. Devuelve `true` si la factura cambió.
  Future<bool> pushInvoiceDetail(Invoice invoice) async {
    final changed = await GoRouter.of(this).pushNamed<Object?>(
      AppRoute.invoiceDetail.routeName,
      pathParameters: {AppRoute.invoiceIdParam: invoice.id},
      extra: invoice,
    );
    return changed == true;
  }

  /// Abre el formulario de facturas.
  ///
  /// Con [existing] edita esa factura; sin él crea una nueva. Devuelve la
  /// factura guardada, o `null` si se canceló.
  Future<Invoice?> pushInvoiceForm({Invoice? existing}) =>
      GoRouter.of(this).pushNamed<Invoice?>(
        AppRoute.invoiceForm.routeName,
        extra: existing,
      );

  /// Vuelve a la raíz descartando la pila actual.
  void goToRoot() => GoRouter.of(this).goNamed(AppRoute.root.routeName);
}

/// Pantalla mostrada cuando una ruta es desconocida.
class RouteErrorView extends StatelessWidget {
  const RouteErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navegación')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wrong_location_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: context.goToRoot,
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
