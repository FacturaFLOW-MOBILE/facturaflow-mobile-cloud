import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_config.dart';
import '../app/routes.dart';
import '../core/result.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../viewmodels/login_view_model.dart';
import '../viewmodels/session_view_model.dart';

/// Pantalla de inicio de sesión con acceso rápido a las cuentas de prueba.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(context.read<SessionViewModel>()),
      child: const _LoginForm(),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await viewModel.submit();
    if (!mounted) return;
    if (result case Ok<AppUser>()) {
      // Si el login se abrió como ruta con nombre, se reemplaza por la raíz;
      // cuando lo muestra RootView, este ya reacciona al cambio de sesión.
      final routeName = ModalRoute.of(context)?.settings.name;
      if (routeName == AppRoutes.login) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.root, (route) => false);
      }
    }
  }

  void _useDemoAccount(LoginViewModel viewModel, DemoAccount account) {
    _emailController.text = account.email;
    _passwordController.text = account.password;
    viewModel.useDemoAccount(account.email, account.password);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final config = context.read<AppConfig>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'FacturaFlow',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestión y aprobación de facturas',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: viewModel.validateEmail,
                      onChanged: viewModel.setEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: viewModel.obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: viewModel.toggleObscurePassword,
                          icon: Icon(
                            viewModel.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: viewModel.obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                        ),
                      ),
                      validator: viewModel.validatePassword,
                      onChanged: viewModel.setPassword,
                      onFieldSubmitted: (_) => _submit(viewModel),
                    ),
                    if (viewModel.hasError) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: viewModel.errorMessage!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed:
                          viewModel.isBusy ? null : () => _submit(viewModel),
                      child: viewModel.isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    if (config.demoMode && viewModel.demoAccounts.isNotEmpty)
                      _DemoAccounts(
                        accounts: viewModel.demoAccounts,
                        onSelected: (account) =>
                            _useDemoAccount(viewModel, account),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.accounts, required this.onSelected});

  final List<DemoAccount> accounts;
  final ValueChanged<DemoAccount> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'MODO DEMOSTRACIÓN',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sin servidor: toca una cuenta para entrar.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ...accounts.map(
          (account) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => onSelected(account),
              icon: const Icon(Icons.person_outline),
              label: Text('${account.user.fullName} · ${account.user.role.label}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
