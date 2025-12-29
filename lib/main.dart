import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'viewmodels/user_viewmodel.dart';
import 'views/add_user_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
 
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
  
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("Firebase не налаштовано: $e");
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserViewModel>(context);
    const Color bordeauxColor = Color(0xFF800020);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: vm.themeMode,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: bordeauxColor,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bordeauxColor,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        cardTheme: const CardThemeData(color: Color(0xFF121212)),
      ),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _locationMessage = "Визначаємо локацію...";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupPushNotifications(); /
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
     
      String? token = await messaging.getToken();
      debugPrint("Firebase Token: $token");

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${message.notification!.title}: ${message.notification!.body}"),
              backgroundColor: const Color(0xFF800020),
            ),
          );
        }
      });
    }
  }

  
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = "GPS вимкнено");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = "Доступ заборонено");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      setState(() {
        _locationMessage = "Lat: ${position.latitude.toStringAsFixed(3)}, Local: ${position.longitude.toStringAsFixed(3)}";
      });
    } catch (e) {
      setState(() => _locationMessage = "Помилка GPS");
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserViewModel>(context);
    const Color bordeauxColor = Color(0xFF800020);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Список користувачів",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
        ),
        centerTitle: true,
        elevation: 10,
        shadowColor: bordeauxColor.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF800020), Color(0xFF4A000A)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              vm.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => vm.toggleTheme(vm.themeMode == ThemeMode.light),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: bordeauxColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: bordeauxColor),
                const SizedBox(width: 8),
                Text(
                  _locationMessage,
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : bordeauxColor
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16, color: bordeauxColor),
                  onPressed: _getCurrentLocation,
                )
              ],
            ),
          ),
          Expanded(
            child: vm.isLoading 
                ? const Center(child: CircularProgressIndicator(color: bordeauxColor))
                : vm.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[600]),
                            const SizedBox(height: 10),
                            const Text("Список порожній", style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: vm.users.length,
                        itemBuilder: (context, index) {
                          final user = vm.users[index];
                          ImageProvider? userImage;
                          if (user.imagePath != null && user.imagePath!.isNotEmpty) {
                            userImage = kIsWeb 
                              ? MemoryImage(base64Decode(user.imagePath!)) 
                              : FileImage(File(user.imagePath!)) as ImageProvider;
                          }

                          return Dismissible(
                            key: Key(user.id.toString()),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: isDark ? Colors.black : Colors.white,
                                    title: const Text("Видалення"),
                                    content: Text("Ви точно хочете видалити користувача ${user.name}?"),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(color: bordeauxColor.withValues(alpha: 0.3)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text("Скасувати", style: TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text("Видалити", style: TextStyle(color: bordeauxColor, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              vm.deleteUser(user.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${user.name} видалено"), backgroundColor: bordeauxColor),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: bordeauxColor.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white, size: 30),
                            ),
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: userImage,
                                  backgroundColor: bordeauxColor.withValues(alpha: 0.2),
                                  child: userImage == null ? const Icon(Icons.person, size: 30, color: bordeauxColor) : null,
                                ),
                                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(user.phone),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.email, size: 14, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(user.email, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: bordeauxColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: bordeauxColor),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddUserScreen(user: user)));
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())),
        label: const Text("Додати", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: bordeauxColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
