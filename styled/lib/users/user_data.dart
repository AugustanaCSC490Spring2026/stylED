class UserData {
  String? userId;
  String username;
  String email;
  String name;  
  
  UserData({  
    this.userId,
    required this.name,
    required this.username,
    required this.email,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      userId: map['userId'] as String?,
      name: map['name'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
    };
  }
}