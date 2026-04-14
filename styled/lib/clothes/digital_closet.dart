// UI
import 'package:flutter/material.dart';
import 'package:styled/auth/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_page.dart';
import 'package:google_fonts/google_fonts.dart';
//import '../clothes/digital_closet.dart';

class DigitalCloset extends StatefulWidget {
  const DigitalCloset({super.key});

  @override
  State<DigitalCloset> createState() => _DigitalClosetState();
}

class _DigitalClosetState extends State<DigitalCloset> {
  final searchController = TextEditingController();
  String searchQuery = '';
  String? selectedFilter;
  int closetTab = 0; // 0 = my closet, 1 = saved outfits
  List<Map<String, dynamic>> savedOutfits = [];
  bool isLoadingOutfits = false;

  final List<String> filters = ['Season', 'Occasion', 'Color', 'Type'];

  List<Map<String, dynamic>> allItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchSavedOutfits();
  }

  Future<void> fetchSavedOutfits() async {
    setState(() => isLoadingOutfits = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => isLoadingOutfits = false);
        return;
      }
      final data = await Supabase.instance.client
          .from('outfits')
          .select()
          .eq('profile_id', userId);
      setState(() {
        savedOutfits = List<Map<String, dynamic>>.from(data);
        isLoadingOutfits = false;
      });
    } catch (e) {
      debugPrint('Error fetching outfits: $e');
      setState(() => isLoadingOutfits = false);
    }
  }
  void _showOutfitDetails(Map<String, dynamic> outfit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    outfit['name'] ?? 'Unnamed Outfit',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Supabase.instance.client
                          .from('outfits')
                          .delete()
                          .eq('outfitid', outfit['outfitid']);
                      fetchSavedOutfits();
                    },
                  ),
                ],
              ),
              Text(
                outfit['created_at'] != null
                    ? 'Saved on ${outfit['created_at'].toString().substring(0, 10)}'
                    : '',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    if (outfit['accessory_id'] != null) _outfitItemRow('Accessory', outfit['accessory_id'].toString()),
                    if (outfit['top_id'] != null) _outfitItemRow('Top', outfit['top_id'].toString()),
                    if (outfit['bottom_id'] != null) _outfitItemRow('Bottom', outfit['bottom_id'].toString()),
                    if (outfit['shoes_id'] != null) _outfitItemRow('Shoes', outfit['shoes_id'].toString()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _outfitItemRow(String label, String itemId) {
  final item = allItems.firstWhere(
    (i) => i['itemId'].toString() == itemId,
    orElse: () => {'name': 'Item #$itemId', 'category': label},
  );
  return Column(
    children: [
      Container(
        width: 160,
        height: label == 'Shoes' ? 100 : label == 'Accessory' ? 80 : 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: item['image_url'] != null
            ? Image.network(item['image_url'], fit: BoxFit.cover, width: double.infinity)
            : const Center(child: Icon(Icons.checkroom, color: Color(0xFF2d3561), size: 40)),
      ),
      Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Text(
          item['name'] ?? 'Unknown',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}
  Future<void> fetchItems() async {
  setState(() => isLoading = true);
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }
    final data = await Supabase.instance.client
        .from('clothes')
        .select()
        .eq('profile_id', userId);
    setState(() {
      allItems = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  } catch (e) {
    debugPrint('Error: $e');
    setState(() => isLoading = false);
  }
}

  Future<void> deleteItem(int itemId) async {
    try {
      await Supabase.instance.client.from('clothes').delete().eq('itemId', itemId);

      fetchItems();
    } catch (e) {
      print(e);
    }
  }

  List<Map<String, dynamic>> get filteredItems { //filters in gallery
    return allItems.where((item) {

      //this is the text search filter
      final matchesSearch = item['name']
              ?.toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ??
          true;

      //this is the seasons filter

      final matchesSeason = selectedSeason == null ||
      item['season'] == selectedSeason;

      //this the occasion filter 

      final matchesOccasion = selectedOccasion == null ||
      item['occasion'] == selectedOccasion;

      //this the color filter

      final matchesColor = selectedColorNames.isEmpty ||
      selectedColorNames.any((color) =>
      (item['color'] as String? ?? '').split(', ').contains(color)); //split the stored screen where colors are separated by a comma and checks if any of the filter colors are in that list


      //this is the item type filter

      final matchesType = selectedType == null ||
      item['category'] == selectedType;

      return matchesSearch && matchesSeason && matchesOccasion && matchesColor && matchesType;
    }).toList();
  }

   void openBottomSheet(String filter){ //filters' options 
    showModalBottomSheet(
      context: context, 
      builder: (BuildContext context) {
        switch (filter){ //open a different bottomsheet based on the selected filter button
          case 'Season': 
          return seasonSheet();

          case 'Occasion':
          return occasionSheet();

          case 'Color':
          return colorSheet();

          case 'Type':
          return typeSheet();

          default: //if none of the four filter options is selected an empty space will be returned
          return const SizedBox();


        }
        
      },
       ).then((submitted) { //addition of the confirmation if filter selection was submitted
        if(submitted == true){
          setState(() {
            
          }); //only saves filter selection if the button "submit" was pressed
        }
      setState(() => selectedFilter = null); //when the sheet closes, the filter chip category is also deselected
    });
  }

  final List<String> seasons = ['Winter','Summer','Fall','Spring',];
  String ? selectedSeason; //null means allSeasons

  Widget seasonSheet(){ //code for individual bottom sheet based on filter option

  //tempSeason need to be outside of builder so a selection isn't undone immediately
  String ? tempSeason = selectedSeason; //current filter selection are copied into this this temporary saver, not validate or saved as real value until submit button is used
  return StatefulBuilder(
      builder: (context, setSheetState) { //sheet has its own setState
      
    return SizedBox(
          height: 400,
          width: double.infinity, //full width
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet 
            
              child: Row( //padding only accepts one child, so a row allows for multiple buttons to be held side by side
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
              
              //Close button will discard pop the buttomSheet and discard any temporary selection made without Submit button
              ElevatedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context, false), //it's false because it's not the submit button
              ),
            ElevatedButton(
              child: const Text('Clear'),
              onPressed: () => setSheetState((){ //clearly clears the selected season saved in the sheet
                tempSeason = null;
    }),
              
            ),

    ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                setState(() => selectedSeason = tempSeason //actually validate temp season as real
                );
                Navigator.pop(context, true); //it's because this is the "submit" button

              },

    ),

              ],
            
            ),
              ),

             Column( //have each chip stacked on top of eachother
          crossAxisAlignment: CrossAxisAlignment.stretch, //makes the chips bigger and centers them
                children: seasons.map((season) {
                  final isSelected = tempSeason == season; //clearly saves all filter selections under tempSeason intially
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempSeason = season),
                    child: Container(
                      margin: const EdgeInsets.symmetric( //space out each chip 
                        horizontal: 16, 
                        vertical: 6
                        ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2d3561)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        season,
                        textAlign: TextAlign.center, //text in each chip is now cented as opposed to being on the left
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1a1a2e),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),

        
                ]
          ),
    );
  }
        );
  }

final List<String> occasions = ['Formal', 'Casual', 'Athletic'];
String ? selectedOccasion; //null means all occasions

  Widget occasionSheet(){
    //tempOccasion is defined outside of builder so to not undo a selection immediately
    String ? tempOccasion = selectedOccasion; //current filter selection are copied into this this temporary saver, not validate or saved as real value until submit button is used
    return StatefulBuilder(
      builder: (context, setSheetState) { //sheet has its own setState
      
    return SizedBox(
          height: 400,
          width: double.infinity, //fulll width
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet
            child: Row( //padding only accepts one child, so a row allows for multiple buttons to be held side by side
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
            
            ElevatedButton(
              //Close button will discard pop the buttomSheet and discard any temporary selection made without Submit button
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context,false), //it's false because it's not the submit button
            ),

            ElevatedButton(
              child: const Text('Clear'),
              onPressed: () => setSheetState((){ //clearly clears the selected occasion saved in the sheet
               tempOccasion = null;
    }),
            ),
            

    ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                setState(() => selectedOccasion = tempOccasion);
               Navigator.pop(context,true);//it's true because it's the "submit" button
              },

    ),
              ],
          ),
              ),
          Column( //have each chip stacked on top of eachother
          crossAxisAlignment: CrossAxisAlignment.stretch, //makes the chips bigger and centers them
                children: occasions.map((occasion) {
                  final isSelected = tempOccasion == occasion;
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempOccasion = occasion),
                    child: Container(
                      margin: const EdgeInsets.symmetric( //space out each chip 
                        horizontal: 16, 
                        vertical: 6
                        ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2d3561)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        occasion,
                        textAlign: TextAlign.center, //text in each chip is now cented as opposed to being on the left
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1a1a2e),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
                ],
          ),
    );
  }
    );
  }

   final List<Map<String, dynamic>> allColors = [
  {'name':'Beige', 'color': const Color(0xFFE8D8B5)},
  {'name':'Black', 'color': Colors.black},
  {'name':'Blue', 'color': Colors.blue},
  {'name':'Brown', 'color': Colors.brown},
  {'name':'Clear', 'color': const Color.fromARGB(255, 235, 240, 255)},
  {'name':'Gold', 'color': const Color.fromARGB(255, 191, 162, 0)},
  {'name':'Gray', 'color': const Color.fromARGB(255, 141, 141, 133)},
  {'name':'Green', 'color': Colors.green},
  {'name':'Multicolored', 'color': const Color(0xFFF4F4DC)},
  {'name':'Off-white', 'color': const Color(0xFFF2F2F2)},
  {'name':'Orange', 'color': Colors.orange},
  {'name':'Pink', 'color': const Color.fromARGB(255, 255, 110, 158)},
  {'name':'Purple', 'color': Colors.purple},
  {'name':'Red', 'color': Colors.red},
  {'name':'Silver', 'color': const Color.fromARGB(255, 75, 75, 62)},
  {'name':'White', 'color': Colors.white},
  {'name':'Yellow', 'color': Colors.yellow},
  ];
  List<String> selectedColorNames = [];

  Widget colorSheet(){
    //defining tempColorNames need to be done outside of builder so to not immediately deselect colors
     List<String> tempColorNames = List.from(selectedColorNames); //temporary color selection list is used until validated with submit button
    return StatefulBuilder(
    builder: (context, setSheetState) {
   
    return SizedBox(
          height: 400,
           width: double.infinity, //fulll width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start ,
            children: [
              Padding(
                padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet
            child: Row( //padding only accepts one child, so a row allows for multiple buttons to be held side by side
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[

                //three buttons to interact with filter options: close, clear, and submit
              ElevatedButton(
                //Close button will discard pop the buttomSheet and discard any temporary selection made without Submit button
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context,false), //it's false because it's not the "submit button"
            ),

            ElevatedButton(
              child: const Text('Clear'),
              onPressed: () => setSheetState((){ //clearly clear the selected colors saved in the sheet
                tempColorNames.clear();
    }),
            ),

    ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                setState(() => selectedColorNames = tempColorNames);
              Navigator.pop(context, true); //it's true because it's the "submit" button
              },
  
    ),
              ],
            ),
              

   






          ),
          Expanded( //fill everything underneath close button
          child: ListView( //like a Column() with the addition of being scrollable
          padding: const EdgeInsets.symmetric(horizontal: 18), //so that CircleAvatars  are not being cut off by screen
          children: allColors.map((item) {
                final isSelected = tempColorNames.contains(item['name']);
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox( //select color when little box is pressed on color selector
                        value: isSelected,
                        activeColor: const Color(0xFF2D3561),
                        onChanged: (_) => setSheetState(() {
                          if (isSelected){
                      tempColorNames.remove(item['name']); // if box already checked, this will unckeck it 
                    } else {
                      tempColorNames.add(item['name']); //if box if not checked, this will check it 
                    }
                        }),
                    ),
                    title: Text(item['name']),
                    trailing: Container( //color icons (CircleAvatars) black border
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2
                        
                      ),
                      ),
                      child: CircleAvatar( //multicolored icon imported jpeg
                        radius: 14,
                        backgroundColor: item['name'] == 'Multicolored' 
                        ? Colors.transparent
                        : item['color'] as Color,
                        backgroundImage: item['name'] == 'Multicolored'
                        ? const AssetImage('assets/icons/multi.png')
                        :null,
                      
                        ),
                    ),
                      

                    onTap: () => setSheetState(() { //select color when tapping anywhere on that specific row
                      if (isSelected) {
                        tempColorNames.remove(item['name']);
                      } else{
                        tempColorNames.add(item['name']);
                      }
                    }),
              
                  ),
                    
                  
                  const Divider (height: 1),
                  ],
                );
              }).toList(),
          ),
          ),
          ],
    ),
    );
  },
  );
  }

final List<String> types = ['Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Accessories','Dresses'];
String ? selectedType; //null means all item types

    Widget typeSheet(){
      //defining tempType outside of builder is necessary so to save type selection
      String  ? tempType = selectedType;//current filter selection are copied into this this temporary saver, not validated or saved as real value until submit button is used
    return StatefulBuilder(
      builder: (context, setSheetState) { //sheet has its own setState
      
    return SizedBox(
          height: 400,
          width: double.infinity, //fulll width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet
            child: Row( //padding only accepts one child, so a row allows for multiple buttons to be held side by side
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[


//Close button will discard pop the buttomSheet and discard any temporary selection made without Submit button
            ElevatedButton(
              //Close button will discard pop the buttomSheet and discard any temporary selection made without Submit button
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context, false), //it's false as it's not the "submit" button
            ),


            ElevatedButton(
              child: const Text('Clear'),
              onPressed: () => setSheetState((){ //clearly clear the selected colors saved in the sheet
                tempType = null;
    }),
              
            ),

    ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                setState(() => selectedType = tempType);
                 Navigator.pop(context, true); //it's true as it's clearly the "submit" button
       }, 
    ),
              ],

    ),
            
          ),
          Column( //have each chip stacked on top of eachother
          crossAxisAlignment: CrossAxisAlignment.stretch, //makes the chips bigger and centers them
                children: types.map((type) {
                  final isSelected = tempType == type;
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempType = type),
                    child: Container(
                      margin: const EdgeInsets.symmetric( //space out each chip 
                        horizontal: 16, 
                        vertical: 6
                        ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2d3561)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        type,
                        textAlign: TextAlign.center, //text in each chip is now cented as opposed to being on the left
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1a1a2e),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
                ],
          ),
    );
  }
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
               // Tab selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => closetTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: closetTab == 0 ? const Color(0xFF2d3561) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'My Closet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: closetTab == 0 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => closetTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: closetTab == 1 ? const Color(0xFF2d3561) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Saved Outfits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: closetTab == 1 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (closetTab == 0) Center(
                child: Text(
                  'My Closet',
                  style: GoogleFonts.rockSalt( 

                    fontStyle: FontStyle.italic,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
              ),
             if (closetTab == 0) Text(
                '${filteredItems.length} items',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (closetTab == 0) const SizedBox(height: 16),

              // Search bar
              if (closetTab == 0) TextField(
                controller: searchController,
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2d3561)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2d3561), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2d3561), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Filters
              if (closetTab == 0) Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('Filters', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              if (closetTab == 0) const SizedBox(height: 8),
              if (closetTab == 0) SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                         setState(() {
                        selectedFilter = isSelected ? null : filter;
                      });
                      if (!isSelected) {
                        openBottomSheet(filter); //actually opens the bottom sheet of a filter chip that isn't already active
                      }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2d3561) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1a1a2e),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

            // Saved Outfits tab
              if (closetTab == 1) ...[
                Expanded(
                  child: isLoadingOutfits
                      ? const Center(child: CircularProgressIndicator())
                      : savedOutfits.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No saved outfits yet!',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Build and save outfits in the Planner tab', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: savedOutfits.length,
                              itemBuilder: (context, index) {
                                final outfit = savedOutfits[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showOutfitDetails(outfit),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF0FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.checkroom, color: Color(0xFF2d3561)),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              outfit['name'] ?? 'Unnamed Outfit',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1a1a2e)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              outfit['created_at'] != null
                                                  ? 'Saved on ${outfit['created_at'].toString().substring(0, 10)}'
                                                  : 'Saved outfit',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  ),
                                  ),
                                );
                              },
                            ),
                ),
              ],

              // Grid
              if (closetTab == 0) Expanded(
                child: isLoading
              
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.checkroom, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your closet is empty!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1a1a2e),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap + to add your first item',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return _clothesCard(item);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),

      // Add button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadPage()),
          );
          fetchItems(); // refresh after adding
        },
        backgroundColor: const Color(0xFF2d3561),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _clothesCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: item['image_url'] != null
                  ? Image.network(
                      item['image_url'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFF0F2F5),
                      child: const Center(
                        child: Icon(Icons.checkroom, size: 48, color: Colors.grey),
                      ),
                    ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded (
                      child: Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1a1a2e),
                        ),
                       ),
                     ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete, //gabage can icon
                          size: 18, 
                          color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Item'),
                            content: const Text('Are you sure you want to delete this item?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteItem(item['itemId']);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () async {
                        //wait until user comes back from the edit page
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UploadPage(existingClothingItem: item,),
                            ),
                        );
                        fetchItems(); //after return from the edit page, all item are fetched once again from Supabase to reflect any changes made

                      },
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item['occasion'] != null) _tag(item['occasion']),
                    const SizedBox(width: 6),
                    if (item['season'] != null) _tag(item['season']),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF1a1a2e)),
      ),
    );
  }
}