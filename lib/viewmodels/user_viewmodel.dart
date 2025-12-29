import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class UserViewModel extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  

  ThemeMode _themeMode = ThemeMode.light;


  List<User> get users => _users;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;

  UserViewModel() {
    loadUsers(); 
  }

 
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await DatabaseHelper.instance.readAllUsers();
    } catch (e) {
      debugPrint("Помилка завантаження користувачів: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> addUser(User user) async {
    await DatabaseHelper.instance.create(user);
    await loadUsers(); 
  }

  
  Future<void> deleteUser(int id) async {
    await DatabaseHelper.instance.delete(id);
    await loadUsers(); 
  }

  
  Future<void> updateUser(User user) async {
    await DatabaseHelper.instance.update(user);
    await loadUsers();
  }


  bool isUserExists(String email, String phone) {
    return _users.any((u) => u.email == email || u.phone == phone);
  }

 
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); 
  }
}
