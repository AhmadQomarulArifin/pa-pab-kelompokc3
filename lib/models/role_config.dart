enum UserRole { owner, barista, kasir }

class RoleConfig {
  final UserRole role;
  final String label;
  final List<int> allowedNavIndices;

  const RoleConfig({
    required this.role,
    required this.label,
    required this.allowedNavIndices,
  });

  static const owner = RoleConfig(
    role: UserRole.owner,
    label: 'Owner',
    allowedNavIndices: [0, 1, 2, 3, 4, 5],
  );

  static const barista = RoleConfig(
    role: UserRole.barista,
    label: 'Barista',
    allowedNavIndices: [0, 1],
  );

  static const kasir = RoleConfig(
    role: UserRole.kasir,
    label: 'Kasir',
    allowedNavIndices: [0, 1, 2],
  );

  static RoleConfig fromRoleString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return owner;
      case 'barista':
        return barista;
      case 'kasir':
        return kasir;
      default:
        return kasir;
    }
  }

  int get defaultNavIndex => allowedNavIndices.first;
}