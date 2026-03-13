class Clothes{
  int? itemId;
  String name;
  String category;
  String color;
  String season;
  int timesWorn;
  DateTime? dateLastWorn;


  Clothes({this.itemId,
          required this.name,
          required this.category,
          required this.color,
          required this.season,
          required this.timesWorn,
          this.dateLastWorn
   });

  factory Clothes.fromMap(Map<String, dynamic> map){
    return Clothes(
      itemId: map['itemId'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      color: map['color'] as String,
      season: map['season'] as String,
      timesWorn: map['timesWorn'] as int,
      dateLastWorn: map['dateLastWorn'] != null
        ? DateTime.parse(map['dateLastWorn']) : null, 
    );
  }
  Map<String, dynamic> toMap(){
    return {
      'name': name,
      'category': category,
      'color': color,
      'season': season,
      'timesWorn': timesWorn,
      'dateLastWorn': dateLastWorn?.toIso8601String().split('T')[0],
    };
  }
}
