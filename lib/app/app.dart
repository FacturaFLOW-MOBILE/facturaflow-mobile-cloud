import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../viewmodels/session_view_model.dart';
import 'app_config.dart';
import 'dependencies.dart';
import 'routes.dart';
import 'theme.dart';

/// Raíz de la aplicación: instala las dependencias, la sesión y el router.
class FacturaFlowApp extends StatefulWidget {
  const FacturaFlowApp({required this.dependencies, super.key});

  final Dependencies dependencies;

  @override
  State<FacturaFlowApp> createState() => _FacturaFlowAppState();
}

class _FacturaFlowAppState extends State<FacturaFlowApp> {
  /// El enrutador conserva la pila de navegación, así que se crea una sola
  /// vez y no en cada `build`.
  late final GoRouter _router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: dependencies.config),
        Provider<AuthRepository>.value(value: dependencies.authRepository),
        Provider<InvoiceRepository>.value(
          value: dependencies.invoiceRepository,
        ),
        ChangeNotifierProvider<SessionViewModel>(
          create: (_) => SessionViewModel(dependencies.authRepository)
            ..bootstrap(),
        ),
      ],
      child: MaterialApp.router(
        title: 'FacturaFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
