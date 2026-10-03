// Tokens de diseño de la aplicación.
//
// Reúnen los valores de espaciado, radios y rellenos que antes aparecían como
// números sueltos dentro de los widgets. Tenerlos en un solo lugar permite
// ajustar la densidad de la interfaz sin recorrer cada pantalla, y deja
// explícito qué medida corresponde a cada situación.
//
// Los colores y las tipografías no viven aquí: salen del `ThemeData` que
// construye `AppTheme`.

import 'package:flutter/widgets.dart';

/// Escala de espaciado, en múltiplos de 4.
class AppSpacing {
  const AppSpacing._();

  /// 4 — separación mínima, por ejemplo entre un valor y su etiqueta.
  static const double xxs = 4;

  /// 8 — separación entre elementos muy relacionados.
  static const double xs = 8;

  /// 12 — separación entre controles de una misma fila o grupo.
  static const double sm = 12;

  /// 16 — separación estándar entre campos y margen lateral de las pantallas.
  static const double md = 16;

  /// 20 — antes del botón principal de una hoja.
  static const double lg = 20;

  /// 24 — separación entre secciones de un formulario.
  static const double xl = 24;

  /// 32 — respiro al final de una pantalla desplazable.
  static const double xxl = 32;
}

/// Radios de borde de los contenedores de la interfaz.
class AppRadius {
  const AppRadius._();

  /// 12 — campos de texto, tarjetas y contenedores de aviso.
  static const double md = 12;
}

/// Rellenos compuestos reutilizados por las pantallas.
class AppInsets {
  const AppInsets._();

  /// Relleno de un formulario desplazable: margen lateral estándar y un
  /// respiro mayor abajo para que el último botón no quede contra el borde.
  static const EdgeInsets formPage = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.xxl,
  );

  /// Relleno interior de una tarjeta o contenedor con contenido propio.
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.md);

  /// Separación vertical entre las filas de un bloque de totales.
  static const EdgeInsets totalsRow = EdgeInsets.symmetric(
    vertical: AppSpacing.xxs,
  );

  /// Separación entre las tarjetas sucesivas de una lista.
  static const EdgeInsets listCardGap = EdgeInsets.only(bottom: AppSpacing.xs);

  /// Relleno de una hoja inferior, sumando el alto que ocupa el teclado.
  static EdgeInsets sheet(double keyboardInset) => EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: keyboardInset + AppSpacing.md,
      );
}
