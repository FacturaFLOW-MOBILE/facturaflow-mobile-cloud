import 'package:flutter/material.dart';

import '../data/models/invoice.dart';
import '../views/home_view.dart';
import '../views/login_view.dart';
import '../views/root_view.dart';

/// Nombres de las rutas de la aplicación.
class AppRoutes {
  const AppRoutes._();

  static const String root = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String invoiceDetail = '/invoices/detail';
  static const String invoiceForm = '/invoices/form';
}

/// Argumentos de [AppRoutes.invoiceDetail].
class InvoiceDetailArgs {
  const InvoiceDetailArgs({required this.invoiceId, this.initial});

  final String invoiceId;

  /// Factura ya cargada por la lista, para pintar el detalle sin esperar.
  final Invoice? initial;
}

/// Argumentos de [AppRoutes.invoiceForm]. `existing == null` crea una nueva.
class InvoiceFormArgs {
  const InvoiceFormArgs({this.existing});

  final Invoice? existing;
}

/// Resolución centralizada de rutas con nombre.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.root:
        return _page(const RootView(), settings);
      case AppRoutes.login:
        return _page(const LoginView(), settings);
      case AppRoutes.home:
        return _page(const HomeView(), settings);
      // TODO(flujo): registrar aquí el detalle y el formulario de factura.
      default:
        return _page(
          _RouteErrorView(message: 'La ruta ${settings.name} no existe.'),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
}

/// Pantalla mostrada cuando una ruta es desconocida o le faltan argumentos.
class _RouteErrorView extends StatelessWidget {
  const _RouteErrorView({required this.message});

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
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.root, (_) => false),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
