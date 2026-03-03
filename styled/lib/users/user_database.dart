import 'package:styled/users/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class UserDatabase {
  final database = Supabase.instance.client.from('user');

  // CRUD

  // Create a new user in the database
  Future createUser(User newUser) async{
    await database.insert(newUser.toMap());
  }

  // Read all users from the database
  final stream = Supabase.instance.client.from('user').stream(primaryKey: ['userId'],).map((data) => data.map((userMap) => User.fromMap(userMap)).toList());

  // Update a user's information in the database
  Future updateName(User oldName, String newName) async {
    await database.update({'name': newName}).eq('userId', oldName.userId!);
  }
  
  Future updateUsername(User oldUsername, String newUsername) async {
    await database.update({'username': newUsername}).eq('userId', oldUsername.userId!);
  }

  Future updatePassword(User oldPassword, String newPassword) async {
    await database.update({'password': newPassword}).eq('userId', oldPassword.userId!);
  }

  Future updateEmail(User oldEmail, String newEmail) async {
    await database.update({'email': newEmail}).eq('userId', oldEmail.userId!);
  } 

  // Delete a user from the database
  Future deleteUser(User user) async {
    await database.delete().eq('userId', user.userId!);
  }
}