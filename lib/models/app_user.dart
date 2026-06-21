enum AppRole { user, admin, developer }

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final AppRole role;
  final int category;
  final List<int> categories;
  final String photoUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.category = 4,
    this.categories = const [4],
    this.photoUrl = '',
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    AppRole? role,
    int? category,
    List<int>? categories,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      photoUrl: photoUrl ?? this.photoUrl,
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
    };
  }
}