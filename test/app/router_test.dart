// Pruebas del enrutador: la tabla de rutas y la navegación tipada.
import 'package:factura_flow_mobile/app/app.dart';
import 'package:factura_flow_mobile/app/dependencies.dart';
import 'package:factura_flow_mobile/app/routes.dart';
import 'package:factura_flow_mobile/data/demo/demo_seed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tabla de rutas', () {
    test('cada destino declara un nombre y un patrón únicos', () {
      final nombres = AppRoute.values.map((route) => route.routeName).toSet();
      final patrones = AppRoute.values.map((route) => route.path).toSet();

      expect(nombres, hasLength(AppRoute.values.length));
      expect(patrones, hasLength(AppRoute.values.length));
    });

    test('el detalle construye su URL a partir del id de la factura', () {
      final router = AppRouter.create();

      expect(
        router.namedLocation(
          AppRoute.invoiceDetail.routeName,
          pathParameters: {AppRoute.invoiceIdParam: 'inv-1001'},
        ),
        '/invoices/detail/inv-1001',
      );
    });

    test('el formulario tiene una ruta propia y no choca con el detalle', () {
      final router = AppRouter.create();

      expect(
        router.namedLocation(AppRoute.invoiceForm.routeName),
        '/invoices/form',
      );
    });
  });

  group('Navegación', () {
    Future<GoRouter> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        FacturaFlowApp(dependencies: Dependencies.forTests()),
      );
      await tester.pumpAndSettle();
      return GoRouter.of(tester.element(find.byType(Scaffold).first));
    }

    Future<void> signInAs(WidgetTester tester, String fullName) async {
      await tester.tap(find.textContaining(fullName));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();
    }

    testWidgets('abrir una factura lleva a la URL de su detalle',
        (tester) async {
      final router = await pumpApp(tester);
      await signInAs(tester, DemoSeed.emisor.fullName);

      await tester.tap(find.text('FE-1001'));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        '/invoices/detail/inv-1001',
      );
    });

    testWidgets('el botón "Nueva" lleva a la URL del formulario',
        (tester) async {
      final router = await pumpApp(tester);
      await signInAs(tester, DemoSeed.emisor.fullName);

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Nueva'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/invoices/form');
      expect(find.text('Nueva factura'), findsOneWidget);
    });

    testWidgets('una ruta desconocida muestra la pantalla de error',
        (tester) async {
      final router = await pumpApp(tester);

      router.go('/ruta-que-no-existe');
      await tester.pumpAndSettle();

      expect(find.byType(RouteErrorView), findsOneWidget);

      // Desde el error se vuelve al inicio.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Volver al inicio'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), AppRoute.root.path);
      expect(find.byType(RouteErrorView), findsNothing);
    });
  });
}
