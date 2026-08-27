import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/session_view_model.dart';
import 'home_view.dart';
import 'login_view.dart';

/// Punto de entrada de la navegación.
///
/// Actúa como guardia de sesión: mientras se restaura la sesión muestra el
/// splash, y luego decide entre [LoginView] y [HomeView].
class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>();
    if (!session.isBootstrapped) return const _SplashView();
    return session.isAuthenticated ? const HomeView() : const LoginView();
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'FacturaFlow',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
