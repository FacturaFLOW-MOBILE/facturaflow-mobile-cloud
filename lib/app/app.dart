import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../viewmodels/session_view_model.dart';
import 'app_config.dart';
import 'dependencies.dart';
import 'routes.dart';
import 'theme.dart';

/// Raíz de la aplicación: instala las dependencias, la sesión y el router.
class FacturaFlowApp extends StatelessWidget {
  const FacturaFlowApp({required this.dependencies, super.key});

  final Dependencies dependencies;

  @override
  Widget build(BuildContext context) {
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
      child: MaterialApp(
        title: 'FacturaFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: AppRoutes.root,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
