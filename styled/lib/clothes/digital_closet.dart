// UI
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_page.dart';
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

  final List<String> filters = ['Season', 'Occasion', 'Color', 'Type'];

  List<Map<String, dynamic>> allItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
  setState(() => isLoading = true);
  try {
    final data = await Supabase.instance.client
        .from('clothes')
        .select()
        .order('itemId', ascending: false);
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
      final matchesSearch = item['name']
              ?.toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ??
          true;
      return matchesSearch;

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
    ).then((_) {
      setState(() => selectedFilter = null); //when the sheet closes, th filter chip category is also deselected
    });
  }

  final List<String> seasons = ['All Seasons','Winter','Summer','Fall','Spring',];
  String selectedSeason = 'All Seasons';

  Widget seasonSheet(){
    return StatefulBuilder(
      builder: (context, setSheetState) { //sheet has its own setState
    return SizedBox(
          height: 400,
          width: double.infinity, //fulll width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet
            child: ElevatedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column( //have each chip stacked on top of eachother
          crossAxisAlignment: CrossAxisAlignment.stretch, //makes the chips bigger and centers them
                children: seasons.map((season) {
                  final isSelected = selectedSeason == season;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedSeason = season),
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
                ],
          ),
    );
  }
    );
  }

final List<String> occasions = ['Formal', 'Casual', 'Athletic'];
String selectedOccasion = 'Formal';

    Widget occasionSheet(){
    return StatefulBuilder(
      builder: (context, setSheetState) { //sheet has its own setState
    return SizedBox(
          height: 400,
          width: double.infinity, //fulll width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet
            child: ElevatedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column( //have each chip stacked on top of eachother
          crossAxisAlignment: CrossAxisAlignment.stretch, //makes the chips bigger and centers them
                children: occasions.map((occasion) {
                  final isSelected = selectedOccasion == occasion;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedOccasion = occasion),
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

  Widget colorSheet(){
    return SizedBox(
          height: 400,
          width: double.infinity, //fulll width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start ,
            children: [
              Padding(padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet
            child: ElevatedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
            ],
          ),
    );
  }

final List<String> types = ['Tops', 'Bottoms', 'Outwear', 'Shoes', 'Accessories','Dresses'];
String selectedType= 'Tops';

    Widget typeSheet(){
    return StatefulBuilder(
      builder: (context, setSheetState) { //sheet has its own setState
    return SizedBox(
          height: 400,
          width: double.infinity, //fulll width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(12), //place close button at the top left of the bottomsheet
            child: ElevatedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column( //have each chip stacked on top of eachother
          crossAxisAlignment: CrossAxisAlignment.stretch, //makes the chips bigger and centers them
                children: types.map((type) {
                  final isSelected = selectedType == type;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedType = type),
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
              const Text(
                'My Closet',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
              Text(
                '${filteredItems.length} items',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Search bar
              TextField(
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
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('Filters', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
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

              // Grid
              Expanded(
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
                          Icons.delete, 
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