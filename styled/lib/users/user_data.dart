class UserData {
  String? userId;
  String username;
  String email;
  String password;
  String name;  
  
  UserData({  
    this.userId,
    required this.name,
    required this.username,
    required this.password,
    required this.email,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
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