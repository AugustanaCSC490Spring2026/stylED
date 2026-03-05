import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:styled/clothes/clothes.dart';

class ClothesDatabase {
  final database = Supabase.instance.client.from('clothes');

  // CRUD 

  // Create a new clothes item in the database
  Future createClothes(Clothes newClothes) async {
    await database.insert(newClothes.toMap());
  } 

  final stream = Supabase.instance.client.from('clothes').stream(primaryKey: ['itemId'],).map((data) => data.map((clothesMap) => Clothes.fromMap(clothesMap)).toList());

  // Update
  Future updateName(Clothes oldName, String newName) async {
    await database.update({'name': newName}).eq('itemId', oldName.itemId!);
  }

  Future updateCategory(Clothes oldCategory, String newCategory) async {
    await database.update({'category': newCategory}).eq('itemId', oldCategory.itemId!);
  }

  Future updateColor(Clothes oldColor, String newColor) async {
    await database.update({'color': newColor}).eq('itemId', oldColor.itemId!);
  }

  Future updateSeason(Clothes oldSeason, String newSeason) async {
    await database.update({'season': newSeason}).eq('itemId', oldSeason.itemId!);
  }

  Future updateTimesWorn(Clothes oldTimesWorn, int newTimesWorn) async {
    await database.update({'timesworn': newTimesWorn}).eq('itemId', oldTimesWorn.itemId!);
  }

  Future updateDateLastWorn(Clothes oldDateLastWorn, DateTime newDateLastWorn) async {
    await database.update({'datelastworn': newDateLastWorn.toIso8601String()}).eq('itemId', oldDateLastWorn.itemId!);
  }

  // Delete a clothes item from the database
  Future deleteClothes(Clothes clothes) async {
    await database.delete().eq('itemId', clothes.itemId!);
  }
}