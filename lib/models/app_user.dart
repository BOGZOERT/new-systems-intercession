enum AppRole { user, admin, developer }

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final AppRole role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    final roleStr = data['role'] as String? ?? 'user';
    AppRole role;
    switch (roleStr) {
      case 'admin':
        role = AppRole.admin;
        break;
      case 'developer':
        role = AppRole.developer;
        break;
      default:
        role = AppRole.user;
    }
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      fullName: data['full_name'] as String? ?? '',
      role: role,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'full_name': fullName,
      'role': role.name,
    };
  }
}