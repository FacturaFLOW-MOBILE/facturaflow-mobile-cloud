import 'user_role.dart';

/// Usuario autenticado en la sesión actual.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        role: UserRole.fromId(json['role'] as String),
      );

  final String id;
  final String fullName;
  final String email;
  final UserRole role;

  /// Iniciales para el avatar: `Ana Torres` -> `AT`.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role.id,
      };

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.fullName == fullName &&
      other.email == email &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, fullName, email, role);

  @override
  String toString() => 'AppUser($id, $email, ${role.id})';
}
