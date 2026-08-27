// Pruebas de widget del flujo principal: login, bandeja por rol y aprobación.
import 'package:factura_flow_mobile/app/app.dart';
import 'package:factura_flow_mobile/app/dependencies.dart';
import 'package:factura_flow_mobile/data/demo/demo_seed.dart';
import 'package:factura_flow_mobile/viewmodels/invoice_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Inicia la app con repositorios en memoria y sin latencia.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      FacturaFlowApp(dependencies: Dependencies.forTests()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signInAs(WidgetTester tester, String fullName) async {
    await tester.tap(find.textContaining(fullName));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets('arranca en el login mostrando las cuentas demo',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('FacturaFlow'), findsOneWidget);
    expect(find.text('MODO DEMOSTRACIÓN'), findsOneWidget);
    expect(find.textContaining('Ana Torres'), findsOneWidget);
    expect(find.textContaining('Carlos Ruiz'), findsOneWidget);
  });

  testWidgets('el login rechaza un correo con formato inválido',
      (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).first, 'no-es-correo');
    await tester.enterText(find.byType(TextFormField).last, 'demo1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('El correo no tiene un formato válido.'), findsOneWidget);
  });

  testWidgets('el emisor entra y ve sus facturas', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, DemoSeed.emisor.fullName);

    // Sus cuatro facturas del set de demostración, incluida la rechazada
    // (FE-1004 queda bajo el pliegue: hay que desplazar la lista).
    expect(find.text('FE-1001'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('FE-1004'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('FE-1004'), findsOneWidget);
    // La factura del administrador no es visible para el emisor.
    expect(find.text('FE-1005'), findsNothing);
    // Con un solo ámbito disponible no se muestra el selector de ámbitos.
    expect(find.byType(SegmentedButton<InvoiceScope>), findsNothing);
    // El emisor sí puede crear facturas.
    expect(find.widgetWithText(FloatingActionButton, 'Nueva'), findsOneWidget);
  });

  testWidgets('el contador entra a la cola de revisión y sin botón de crear',
      (tester) async {
    await pumpApp(tester);
    await signInAs(tester, DemoSeed.contador.fullName);

    expect(find.text('Por revisar'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Nueva'), findsNothing);
    // Las dos facturas enviadas del set de demostración.
    expect(find.text('FE-1002'), findsOneWidget);
    expect(find.text('FE-1005'), findsOneWidget);
  });

  testWidgets('el contador aprueba una factura y desaparece de su cola',
      (tester) async {
    await pumpApp(tester);
    await signInAs(tester, DemoSeed.contador.fullName);

    await tester.tap(find.text('FE-1002'));
    await tester.pumpAndSettle();

    expect(find.text('Aprobar'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Aprobar'));
    await tester.pumpAndSettle();

    // Diálogo de confirmación.
    await tester.tap(find.widgetWithText(FilledButton, 'Aprobar').last);
    await tester.pumpAndSettle();

    expect(find.text('Factura aprobada.'), findsOneWidget);

    // Al volver, la cola de revisión ya no la incluye.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('FE-1002'), findsNothing);
  });

  testWidgets('el rechazo exige un motivo antes de confirmar', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, DemoSeed.contador.fullName);

    await tester.tap(find.text('FE-1002'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rechazar'));
    await tester.pumpAndSettle();

    // Sin motivo: el diálogo no se cierra y muestra el error.
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Explica el motivo (mínimo 5 caracteres).'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).last, 'Falta el soporte');
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('Factura rechazada'), findsOneWidget);
  });

  testWidgets('cerrar sesión devuelve al login', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, DemoSeed.emisor.fullName);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('MODO DEMOSTRACIÓN'), findsOneWidget);
  });
}
