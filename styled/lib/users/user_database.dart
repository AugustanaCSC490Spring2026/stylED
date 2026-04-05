import 'package:styled/users/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide UserData;

class UserDatabase {
  final database = Supabase.instance.client.from('profiles');

  // CRUD

  // Create a new user in the database
  Future createUser(UserData newUser) async{
    await database.insert(newUser.toMap());
  }

  // Read all users from the database
  final stream = Supabase.instance.client.from('profiles').stream(primaryKey: ['userId'],).map((data) => data.map((userMap) => UserData.fromMap(userMap)).toList());

  // Update a user's information in the database
  Future updateName(UserData oldName, String newName) async {
    await database.update({'name': newName}).eq('userId', oldName.userId!);
  }
  
  Future updateUsername(UserData oldUsername, String newUsername) async {
    await database.update({'username': newUsername}).eq('userId', oldUsername.userId!);
  }

  Future updateEmail(UserData oldEmail, String newEmail) async {
    await database.update({'email': newEmail}).eq('userId', oldEmail.userId!);
  } 

  // Delete a user from the database
  Future deleteUser(UserData user) async {
    await database.delete().eq('userId', user.userId!);
  }
}