import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../viewmodels/user_viewmodel.dart';

class AddUserScreen extends StatefulWidget {
  final User? user;
  const AddUserScreen({super.key, this.user});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _imagePath;

  String _selectedCountryCode = "+380";
  final Map<String, String> _countryData = {
    "+380": "🇺🇦", "+48": "🇵🇱", "+1": "🇺🇸", "+44": "🇬🇧", "+49": "🇩🇪",
  };

  final List<String> _emailDomains = ["@gmail.com", "@ukr.net", "@icloud.com", "@outlook.com"];
  
  final Color bordeauxColor = const Color(0xFF800020);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    String phoneText = widget.user?.phone ?? '';
    for (var code in _countryData.keys) {
      if (phoneText.startsWith(code)) {
        _selectedCountryCode = code;
        phoneText = phoneText.replaceFirst(code, '');
        break;
      }
    }
    _phoneController = TextEditingController(text: phoneText);
    _imagePath = widget.user?.imagePath;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        title: const Text("Оберіть джерело"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: bordeauxColor.withValues(alpha: 0.3)),
        ),
        actions: [
          ListTile(
            leading: Icon(Icons.camera_alt, color: bordeauxColor),
            title: const Text("Зробити фото"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.image, color: bordeauxColor),
            title: const Text("Галерея"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source, maxWidth: 500);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() { _imagePath = base64Encode(bytes); });
        } else {
          setState(() { _imagePath = image.path; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(widget.user == null ? "Новий контакт" : "Редагування"),
        centerTitle: true,
        backgroundColor: bordeauxColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: bordeauxColor.withValues(alpha: 0.1),
                        backgroundImage: _imagePath != null 
                          ? (kIsWeb ? MemoryImage(base64Decode(_imagePath!)) : FileImage(File(_imagePath!)) as ImageProvider)
                          : null,
                        child: _imagePath == null 
                          ? Icon(Icons.person, size: 60, color: bordeauxColor) 
                          : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: bordeauxColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Ім'я та Прізвище",
                  labelStyle: TextStyle(color: isDark ? Colors.grey : bordeauxColor),
                  prefixIcon: Icon(Icons.person_outline, color: bordeauxColor),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: bordeauxColor, width: 2), borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Введіть ім'я" : null,
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]'))],
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: isDark ? Colors.grey : bordeauxColor),
                      prefixIcon: Icon(Icons.alternate_email, color: bordeauxColor),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: bordeauxColor, width: 2), borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => !v!.contains('@') ? "Некоректний email" : null,
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _emailDomains.map((domain) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: bordeauxColor.withValues(alpha: 0.15),
                          label: Text(domain, style: TextStyle(color: isDark ? Colors.white : bordeauxColor)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onPressed: () {
                            String currentText = _emailController.text;
                            if (currentText.contains('@')) {
                              currentText = currentText.split('@')[0];
                            }
                            setState(() {
                              _emailController.text = currentText + domain;
                              _emailController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _emailController.text.length)
                              );
                            });
                          },
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: InputDecoration(
                  labelText: "Номер телефону",
                  labelStyle: TextStyle(color: isDark ? Colors.grey : bordeauxColor),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: bordeauxColor, width: 2), borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Container(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: isDark ? Colors.black : Colors.white,
                        value: _selectedCountryCode,
                        onChanged: (String? newValue) { setState(() { _selectedCountryCode = newValue!; }); },
                        items: _countryData.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key, 
                            child: Text("${entry.value} ${entry.key}", style: TextStyle(color: isDark ? Colors.white : Colors.black))
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                validator: (v) => v!.length < 9 ? "Введіть номер" : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bordeauxColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final viewModel = context.read<UserViewModel>();
                      final String fullPhone = "$_selectedCountryCode${_phoneController.text}";
                      final String email = _emailController.text.trim();

                      // ДОДАНО: Перевірка на дублікати (плагіат даних)
                      bool isDuplicate = viewModel.users.any((u) {
                        if (widget.user != null && u.id == widget.user!.id) return false;
                        return u.email.toLowerCase() == email.toLowerCase() || u.phone == fullPhone;
                      });

                      if (isDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Користувач з такою поштою або телефоном вже існує!"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return; 
                      }

                      final newUser = User(
                        id: widget.user?.id,
                        name: _nameController.text,
                        email: email,
                        phone: fullPhone,
                        imagePath: _imagePath,
                      );

                      if (widget.user == null) {
                        viewModel.addUser(newUser);
                      } else {
                        viewModel.updateUser(newUser);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("ЗБЕРЕГТИ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}