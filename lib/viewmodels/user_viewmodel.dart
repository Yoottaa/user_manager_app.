import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class UserViewModel extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  
  // Керування темою
  ThemeMode _themeMode = ThemeMode.light;

  // Геттери для доступу до даних
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;

  UserViewModel() {
    loadUsers(); // Завантажуємо список користувачів відразу при створенні
  }

  // Завантаження користувачів з бази даних (Shared Preferences)
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

  // Додавання нового користувача
  Future<void> addUser(User user) async {
    await DatabaseHelper.instance.create(user);
    await loadUsers(); // Оновлюємо список після додавання
  }

  // Видалення користувача
  Future<void> deleteUser(int id) async {
    await DatabaseHelper.instance.delete(id);
    await loadUsers(); // Оновлюємо список після видалення
  }

  // Оновлення існуючого користувача (Редагування)
  Future<void> updateUser(User user) async {
    await DatabaseHelper.instance.update(user);
    await loadUsers(); // Оновлюємо список після редагування
  }

  // Перевірка, чи існує вже користувач з такою поштою або телефоном
  bool isUserExists(String email, String phone) {
    return _users.any((u) => u.email == email || u.phone == phone);
  }

  // ПЕРЕМИКАЧ ТЕМИ
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Повідомляємо MaterialApp, що треба перемалювати інтерфейс
  }
}