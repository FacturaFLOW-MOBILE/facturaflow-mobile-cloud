import '../../core/result.dart';
import '../models/app_user.dart';
import '../models/invoice.dart';

/// Datos necesarios para crear o actualizar una factura.
class InvoiceDraft {
  const InvoiceDraft({
    required this.number,
    required this.supplierName,
    required this.supplierTaxId,
    required this.issueDate,
    required this.items,
    this.notes = '',
  });

  final String number;
  final String supplierName;
  final String supplierTaxId;
  final DateTime issueDate;
  final List<InvoiceItem> items;
  final String notes;
}

/// Contrato de acceso a facturas.
///
/// Todas las operaciones validan permisos según el rol del `actor` y
/// devuelven [Result] en vez de lanzar excepciones.
abstract class InvoiceRepository {
  /// Facturas visibles para [user]: el emisor solo ve las propias.
  Future<Result<List<Invoice>>> fetchAll(AppUser user);

  /// Una factura por id.
  Future<Result<Invoice>> getById(String id);

  /// Crea una factura en estado borrador.
  Future<Result<Invoice>> create(InvoiceDraft draft, AppUser actor);

  /// Actualiza el contenido de una factura editable.
  Future<Result<Invoice>> update(String id, InvoiceDraft draft, AppUser actor);

  /// Envía la factura a revisión del contador.
  Future<Result<Invoice>> submit(String id, AppUser actor);

  /// Aprueba una factura en revisión.
  Future<Result<Invoice>> approve(String id, AppUser actor, {String? comment});

  /// Rechaza una factura en revisión indicando el motivo.
  Future<Result<Invoice>> reject(
    String id,
    AppUser actor, {
    required String reason,
  });

  /// Devuelve una factura rechazada a borrador para corregirla.
  Future<Result<Invoice>> reopen(String id, AppUser actor);

  /// Elimina un borrador propio.
  Future<Result<void>> delete(String id, AppUser actor);
}
