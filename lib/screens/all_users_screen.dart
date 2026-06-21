import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/user_avatar.dar.dart';
import 'user_profile_screen.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  String _sortBy = 'category';
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final allUsers = context.watch<UsersProvider>().users;
    final currentUser = context.watch<AuthProvider>().appUser;

    final sortedUsers = List<AppUser>.from(allUsers);
    switch (_sortBy) {
      case 'name':
        sortedUsers.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'role':
        sortedUsers.sort((a, b) => a.role.name.compareTo(b.role.name));
        break;
      case 'category':
      default:
        sortedUsers.sort((a, b) => a.category.compareTo(b.category));
        break;
    }
    if (!_ascending) {
      sortedUsers.reversed.toList();
    }

    final grouped = <int, List<AppUser>>{};
    if (_sortBy == 'category') {
      for (var user in sortedUsers) {
        grouped.putIfAbsent(user.category, () => []).add(user);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Все сотрудники'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = value;
                  _ascending = true;
                }
              });
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'category',
                checked: _sortBy == 'category',
                child: Text('По категории ${_ascending && _sortBy == 'category' ? '↑' : '↓'}'),
              ),
              CheckedPopupMenuItem(
                value: 'name',
                checked: _sortBy == 'name',
                child: Text('По имени ${_ascending && _sortBy == 'name' ? '↑' : '↓'}'),
              ),
              CheckedPopupMenuItem(
                value: 'role',
                checked: _sortBy == 'role',
                child: Text('По роли ${_ascending && _sortBy == 'role' ? '↑' : '↓'}'),
              ),
            ],
          ),
          Text('${allUsers.length} чел.', style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 16),
        ],
      ),
      body: allUsers.isEmpty
          ? const Center(child: Text('Нет сотрудников', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : _sortBy == 'category'
          ? ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: grouped.keys.length,
        itemBuilder: (context, index) {
          final categories = grouped.keys.toList()..sort();
          final category = categories[index];
          final usersInCategory = grouped[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$category',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$category категория',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getCategoryColor(category)),
                    ),
                    const Spacer(),
                    Text('${usersInCategory.length} чел.', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              ...usersInCategory.map((user) => _buildUserCard(user, currentUser)),
              const SizedBox(height: 16),
            ],
          );
        },
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedUsers.length,
        itemBuilder: (context, index) => _buildUserCard(sortedUsers[index], currentUser),
      ),
    );
  }

  Widget _buildUserCard(AppUser user, AppUser? currentUser) {
    final isMe = currentUser != null && currentUser.uid == user.uid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: ListTile(
        leading: UserAvatar(
          user: user,
          radius: 20,
          defaultColor: _getCategoryColor(user.category),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName : user.email,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (isMe)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Я', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: _getCategoryColor(user.category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${user.category} кат.',
                style: TextStyle(fontSize: 11, color: _getCategoryColor(user.category), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            if (user.categories.length > 1)
              Text(
                'Все: ${user.categories.join(", ")}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(user.role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRoleTitle(user.role),
            style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onTap: () {
          // Открываем профиль пользователя
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(int category) {
    switch (category) {
      case 3: return Colors.teal;
      case 4: return Colors.blue;
      case 5: return Colors.green;
      case 6: return Colors.orange;
      case 7: return Colors.purple;
      case 8: return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin: return Colors.orange;
      case AppRole.developer: return Colors.red;
      case AppRole.user: return Colors.blue;
    }
  }

  String _getRoleTitle(AppRole role) {
    switch (role) {
      case AppRole.user: return 'Пользователь';
      case AppRole.admin: return 'Администратор';
      case AppRole.developer: return 'Разработчик';
    }
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }
}