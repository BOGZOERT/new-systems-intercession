enum AppRole { user, admin, developer }

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final AppRole role;
  final int category;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.category = 4,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    AppRole? role,
    int? category,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      category: category ?? this.category,
    );
  }

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
      category: (data['category'] as num?)?.toInt() ?? 4,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'category': category,
    };
  }
}