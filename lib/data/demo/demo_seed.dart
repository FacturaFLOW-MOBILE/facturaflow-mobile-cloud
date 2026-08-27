import '../models/app_user.dart';
import '../models/invoice.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';

/// Datos ficticios que alimentan el modo demostración.
///
/// No hay red ni base de datos: todo se genera aquí y vive en memoria
/// mientras la app está abierta.
class DemoSeed {
  const DemoSeed._();

  static const String password = 'demo1234';

  static const AppUser emisor = AppUser(
    id: 'u-ana',
    fullName: 'Ana Torres',
    email: 'ana@facturaflow.demo',
    role: UserRole.emisor,
  );

  static const AppUser contador = AppUser(
    id: 'u-carlos',
    fullName: 'Carlos Ruiz',
    email: 'carlos@facturaflow.demo',
    role: UserRole.contador,
  );

  static const AppUser administrador = AppUser(
    id: 'u-lucia',
    fullName: 'Lucía Peña',
    email: 'lucia@facturaflow.demo',
    role: UserRole.administrador,
  );

  static const List<AppUser> users = [emisor, contador, administrador];

  static List<DemoAccount> get accounts => users
      .map((user) =>
          DemoAccount(email: user.email, password: password, user: user))
      .toList(growable: false);

  /// Facturas iniciales, fechadas relativamente a [now] para que la demo
  /// siempre luzca reciente.
  static List<Invoice> invoices(DateTime now) {
    Invoice build({
      required String id,
      required String number,
      required String supplierName,
      required String supplierTaxId,
      required int daysAgo,
      required List<InvoiceItem> items,
      required InvoiceStatus status,
      required AppUser owner,
      String notes = '',
      String? rejectionReason,
      List<InvoiceEvent> history = const [],
    }) {
      final created = now.subtract(Duration(days: daysAgo));
      return Invoice(
        id: id,
        number: number,
        supplierName: supplierName,
        supplierTaxId: supplierTaxId,
        issueDate: created,
        items: items,
        status: status,
        createdById: owner.id,
        createdByName: owner.fullName,
        createdAt: created,
        updatedAt: history.isEmpty ? created : history.last.at,
        notes: notes,
        rejectionReason: rejectionReason,
        history: [
          InvoiceEvent(
            at: created,
            actorId: owner.id,
            actorName: owner.fullName,
            status: InvoiceStatus.borrador,
            description: 'Factura creada',
          ),
          ...history,
        ],
      );
    }

    return [
      build(
        id: 'inv-1001',
        number: 'FE-1001',
        supplierName: 'Papelería La 45',
        supplierTaxId: '900123456-7',
        daysAgo: 2,
        status: InvoiceStatus.borrador,
        owner: emisor,
        notes: 'Pendiente de adjuntar la orden de compra.',
        items: const [
          InvoiceItem(
            description: 'Resma de papel carta',
            quantity: 12,
            unitPriceCents: 1850000,
          ),
          InvoiceItem(
            description: 'Tóner impresora láser',
            quantity: 2,
            unitPriceCents: 24500000,
          ),
        ],
      ),
      build(
        id: 'inv-1002',
        number: 'FE-1002',
        supplierName: 'Transportes Andinos S.A.S.',
        supplierTaxId: '901555222-1',
        daysAgo: 5,
        status: InvoiceStatus.enviada,
        owner: emisor,
        items: const [
          InvoiceItem(
            description: 'Flete Bogotá - Medellín',
            quantity: 1,
            unitPriceCents: 128000000,
          ),
          InvoiceItem(
            description: 'Seguro de carga',
            quantity: 1,
            unitPriceCents: 19500000,
            taxRate: 0.05,
          ),
        ],
        history: [
          InvoiceEvent(
            at: now.subtract(const Duration(days: 4)),
            actorId: emisor.id,
            actorName: emisor.fullName,
            status: InvoiceStatus.enviada,
            description: 'Enviada a revisión',
          ),
        ],
      ),
      build(
        id: 'inv-1003',
        number: 'FE-1003',
        supplierName: 'Servicios Contables Delta',
        supplierTaxId: '830998877-3',
        daysAgo: 12,
        status: InvoiceStatus.aprobada,
        owner: emisor,
        items: const [
          InvoiceItem(
            description: 'Asesoría tributaria mensual',
            quantity: 1,
            unitPriceCents: 320000000,
          ),
        ],
        history: [
          InvoiceEvent(
            at: now.subtract(const Duration(days: 11)),
            actorId: emisor.id,
            actorName: emisor.fullName,
            status: InvoiceStatus.enviada,
            description: 'Enviada a revisión',
          ),
          InvoiceEvent(
            at: now.subtract(const Duration(days: 10)),
            actorId: contador.id,
            actorName: contador.fullName,
            status: InvoiceStatus.aprobada,
            description: 'Aprobada por ${contador.fullName}',
            comment: 'Soportes completos.',
          ),
        ],
      ),
      build(
        id: 'inv-1004',
        number: 'FE-1004',
        supplierName: 'Cafetería El Roble',
        supplierTaxId: '1020304050',
        daysAgo: 8,
        status: InvoiceStatus.rechazada,
        owner: emisor,
        rejectionReason: 'El NIT del proveedor no coincide con el RUT.',
        items: const [
          InvoiceItem(
            description: 'Refrigerios capacitación',
            quantity: 40,
            unitPriceCents: 950000,
          ),
        ],
        history: [
          InvoiceEvent(
            at: now.subtract(const Duration(days: 7)),
            actorId: emisor.id,
            actorName: emisor.fullName,
            status: InvoiceStatus.enviada,
            description: 'Enviada a revisión',
          ),
          InvoiceEvent(
            at: now.subtract(const Duration(days: 6)),
            actorId: contador.id,
            actorName: contador.fullName,
            status: InvoiceStatus.rechazada,
            description: 'Rechazada por ${contador.fullName}',
            comment: 'El NIT del proveedor no coincide con el RUT.',
          ),
        ],
      ),
      build(
        id: 'inv-1005',
        number: 'FE-1005',
        supplierName: 'Tecnología Integral Ltda.',
        supplierTaxId: '860111222-9',
        daysAgo: 1,
        status: InvoiceStatus.enviada,
        owner: administrador,
        items: const [
          InvoiceItem(
            description: 'Licencia antivirus (10 equipos)',
            quantity: 10,
            unitPriceCents: 8900000,
          ),
          InvoiceItem(
            description: 'Soporte técnico remoto',
            quantity: 6,
            unitPriceCents: 12000000,
          ),
        ],
        history: [
          InvoiceEvent(
            at: now.subtract(const Duration(hours: 6)),
            actorId: administrador.id,
            actorName: administrador.fullName,
            status: InvoiceStatus.enviada,
            description: 'Enviada a revisión',
          ),
        ],
      ),
    ];
  }
}
