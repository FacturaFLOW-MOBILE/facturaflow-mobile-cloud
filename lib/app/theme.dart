import 'package:flutter/material.dart';

import '../data/models/invoice_status.dart';

/// Tema de la aplicación (Material 3) y colores del flujo de facturas.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF1B5E9B);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }

  /// Colores de fondo/texto para el chip de estado.
  static (Color background, Color foreground) statusColors(
    BuildContext context,
    InvoiceStatus status,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      InvoiceStatus.borrador => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
      InvoiceStatus.enviada => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      InvoiceStatus.aprobada => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      InvoiceStatus.rechazada => (
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
    };
  }

  static IconData statusIcon(InvoiceStatus status) => switch (status) {
        InvoiceStatus.borrador => Icons.edit_note,
        InvoiceStatus.enviada => Icons.hourglass_top,
        InvoiceStatus.aprobada => Icons.check_circle,
        InvoiceStatus.rechazada => Icons.cancel,
      };
}
