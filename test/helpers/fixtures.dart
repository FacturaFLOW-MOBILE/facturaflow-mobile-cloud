import 'package:factura_flow_mobile/data/demo/demo_seed.dart';
import 'package:factura_flow_mobile/data/models/app_user.dart';
import 'package:factura_flow_mobile/data/models/invoice.dart';

/// Usuarios reutilizados por las pruebas.
const AppUser emisor = DemoSeed.emisor;
const AppUser contador = DemoSeed.contador;
const AppUser administrador = DemoSeed.administrador;

/// Fecha fija para que las pruebas no dependan del reloj real.
final DateTime fechaFija = DateTime(2026, 8, 20, 9);

/// Reloj determinista para inyectar en repositorios y ViewModels.
DateTime testClock() => fechaFija;

/// Construye una factura válida por defecto, ajustable por parámetro.
Invoice buildInvoice({
  String id = 'inv-test',
  String number = 'FE-9001',
  String supplierName = 'Proveedor de Prueba',
  String supplierTaxId = '900000000-1',
  InvoiceStatus status = InvoiceStatus.borrador,
  AppUser? owner,
  List<InvoiceItem>? items,
  String notes = '',
  String? rejectionReason,
}) {
  final user = owner ?? emisor;
  return Invoice(
    id: id,
    number: number,
    supplierName: supplierName,
    supplierTaxId: supplierTaxId,
    issueDate: fechaFija,
    items: items ??
        const [
          InvoiceItem(
            description: 'Servicio de prueba',
            quantity: 1,
            unitPriceCents: 100000,
          ),
        ],
    status: status,
    createdById: user.id,
    createdByName: user.fullName,
    createdAt: fechaFija,
    updatedAt: fechaFija,
    notes: notes,
    rejectionReason: rejectionReason,
    history: [
      InvoiceEvent(
        at: fechaFija,
        actorId: user.id,
        actorName: user.fullName,
        status: InvoiceStatus.borrador,
        description: 'Factura creada',
      ),
    ],
  );
}
