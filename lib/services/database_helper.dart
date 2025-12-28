import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static const _storageKey = 'users_data';

  Future<int> create(User user) async {
    final users = await readAllUsers();
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch, 
      name: user.name,
      email: user.email,
      phone: user.phone,
      imagePath: user.imagePath,
    );
    users.add(newUser);
    await _saveToStorage(users);
    return newUser.id!;
  }

  Future<List<User>> readAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_storageKey);
    if (usersJson == null) return [];
    final List<dynamic> decoded = jsonDecode(usersJson);
    return decoded.map((item) => User.fromMap(item)).toList();
  }

  Future<void> update(User user) async {
    final users = await readAllUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      await _saveToStorage(users);
    }
  }

  Future<int> delete(int id) async {
    final users = await readAllUsers();
    users.removeWhere((user) => user.id == id);
    await _saveToStorage(users);
    return id;
  }

  Future<void> _saveToStorage(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(users.map((u) => u.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}