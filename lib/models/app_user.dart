enum AppRole { user, admin, developer, boss }

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final AppRole role;
  final int category;
  final List<int> categories;
  final String photoUrl;
  final String organizationId;
  final DateTime? lastActive;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.category = 4,
    this.categories = const [4],
    this.photoUrl = '',
    this.organizationId = '',
    this.lastActive,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    AppRole? role,
    int? category,
    List<int>? categories,
    String? photoUrl,
    String? organizationId,
    DateTime? lastActive,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      photoUrl: photoUrl ?? this.photoUrl,
      organizationId: organizationId ?? this.organizationId,
      lastActive: lastActive ?? this.lastActive,
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
      case 'boss':
        role = AppRole.boss;
        break;
      default:
        role = AppRole.user;
    }

    List<int> cats;
    if (data['categories'] != null) {
      cats = List<int>.from(data['categories']);
    } else if (data['category'] != null) {
      cats = [(data['category'] as num).toInt()];
    } else {
      cats = [4];
    }

    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      fullName: data['full_name'] as String? ?? '',
      role: role,
      category: (data['category'] as num?)?.toInt() ?? cats.first,
      categories: cats,
      photoUrl: data['photo_url'] as String? ?? '',
      organizationId: data['organization_id'] as String? ?? '',
      lastActive: (data['last_active'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'category': category,
      'categories': categories,
      'photo_url': photoUrl,
      'organization_id': organizationId,
      'last_active': lastActive,
    };
  }
}