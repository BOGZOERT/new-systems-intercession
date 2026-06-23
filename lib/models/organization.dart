class Organization {
  final String id;
  final String name;
  final String password; // пароль для входа в организацию

  const Organization({
    required this.id,
    required this.name,
    required this.password,
  });

  factory Organization.fromFirestore(String id, Map<String, dynamic> data) {
    return Organization(
      id: id,
      name: data['name'] as String? ?? '',
      password: data['password'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'password': password,
    };
  }
}