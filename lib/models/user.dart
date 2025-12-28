class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String? imagePath;

  User({this.id, required this.name, required this.email, required this.phone, this.imagePath});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'imagePath': imagePath,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      imagePath: map['imagePath'],
    );
  }
}