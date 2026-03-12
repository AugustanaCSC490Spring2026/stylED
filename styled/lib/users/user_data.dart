class User {
  String? userId;
  String name;
  String username;
  String email;
  String password;

  User({
    this.userId,
    required this.name,
    required this.username,
    required this.password,
    required this.email,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userid'] as String?,
      name: map['name'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      email: map['email'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'password': password,
      'email': email,
    };
  }
}