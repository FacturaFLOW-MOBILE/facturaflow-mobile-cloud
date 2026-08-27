/// Roles disponibles en la aplicación.
///
/// - [emisor]: crea y envía facturas propias.
/// - [contador]: revisa la cola de facturas enviadas, aprueba o rechaza.
/// - [administrador]: puede hacer ambas cosas y ver todas las facturas.
enum UserRole {
  emisor('emisor', 'Usuario emisor'),
  contador('contador', 'Contador'),
  administrador('administrador', 'Administrador');

  const UserRole(this.id, this.label);

  /// Identificador estable usado en JSON y almacenamiento.
  final String id;

  /// Nombre mostrado en la interfaz.
  final String label;

  static UserRole fromId(String id) => UserRole.values.firstWhere(
        (role) => role.id == id,
        orElse: () => UserRole.emisor,
      );

  /// Puede crear y editar facturas en borrador.
  bool get canCreateInvoices =>
      this == UserRole.emisor || this == UserRole.administrador;

  /// Puede aprobar o rechazar facturas enviadas a revisión.
  bool get canReviewInvoices =>
      this == UserRole.contador || this == UserRole.administrador;

  /// Ve todas las facturas de la organización, no solo las propias.
  bool get canSeeAllInvoices => this != UserRole.emisor;
}
