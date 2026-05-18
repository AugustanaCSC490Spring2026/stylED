// UI
import 'package:flutter/material.dart';
import 'package:styled/auth/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'showcase_closet.dart';

class DigitalCloset extends StatefulWidget {
  const DigitalCloset({super.key});

  @override
  State<DigitalCloset> createState() => _DigitalClosetState();
}

class _DigitalClosetState extends State<DigitalCloset> {
  final searchController = TextEditingController();
  String searchQuery = '';
  String? selectedFilter;
  int closetTab = 0;
  List<Map<String, dynamic>> savedOutfits = [];
  bool isLoadingOutfits = false;
  bool isGridView = true;
  bool _searchOpen = false;

  final List<String> filters = ['Season', 'Occasion', 'Color', 'Type'];

  void clearAllFilters() {
    setState(() {
      selectedSeason = {};
      selectedOccasion = {};
      selectedColorNames.clear();
      selectedType = {};
      selectedFilter = null;
    });
  }

  bool get hasActiveFilters {
    return selectedSeason.isNotEmpty ||
        selectedOccasion.isNotEmpty ||
        selectedColorNames.isNotEmpty ||
        selectedType.isNotEmpty;
  }

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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a2e),
                    ),
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
                    if (outfit['accessory_id'] != null)
                      _outfitItemRow('Accessory', outfit['accessory_id'].toString()),
                    if (outfit['top_id'] != null)
                      _outfitItemRow('Top', outfit['top_id'].toString()),
                    if (outfit['bottom_id'] != null)
                      _outfitItemRow('Bottom', outfit['bottom_id'].toString()),
                    if (outfit['shoes_id'] != null)
                      _outfitItemRow('Shoes', outfit['shoes_id'].toString()),
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

  List<Map<String, dynamic>> get filteredItems {
    return allItems.where((item) {
      final matchesSearch = item['name']
              ?.toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ??
          true;
      final matchesSeason = selectedSeason.isEmpty || selectedSeason.contains(item['season']);
      final matchesOccasion = selectedOccasion.isEmpty || selectedOccasion.contains(item['occasion']);
      final matchesColor = selectedColorNames.isEmpty ||
          selectedColorNames.any(
              (color) => (item['color'] as String? ?? '').split(', ').contains(color));
      final matchesType = selectedType.isEmpty || selectedType.contains(item['category']);
      return matchesSearch && matchesSeason && matchesOccasion && matchesColor && matchesType;
    }).toList();
  }

  void openBottomSheet(String filter) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        switch (filter) {
          case 'Season':
            return filterSelectionSheet(seasons, selectedSeason,
                (chosenItems) => setState(() => selectedSeason = chosenItems));
          case 'Occasion':
            return filterSelectionSheet(occasions, selectedOccasion,
                (chosenItems) => setState(() => selectedOccasion = chosenItems));
          case 'Color':
            return filterSelectionSheet(
              allColorsMap.keys.toList(),
              Set.from(selectedColorNames),
              (chosenItems) => setState(() => selectedColorNames = List.from(chosenItems)),
              iconCreatorFunction: (name) => CircleAvatar(
                radius: 14,
                backgroundColor: name == 'Multicolored' ? Colors.transparent : allColorsMap[name]!,
                backgroundImage:
                    name == 'Multicolored' ? const AssetImage('assets/icons/multi.png') : null,
              ),
            );
          case 'Type':
            return filterSelectionSheet(types, selectedType,
                (chosenItems) => setState(() => selectedType = chosenItems));
          default:
            return const SizedBox();
        }
      },
    ).then((submitted) {
      if (submitted == true) setState(() {});
      setState(() => selectedFilter = null);
    });
  }

  final List<String> seasons = ['Winter', 'Summer', 'Fall', 'Spring'];
  Set<String> selectedSeason = {};

  final List<String> occasions = ['Formal', 'Casual', 'Athletic'];
  Set<String> selectedOccasion = {};

  final Map<String, Color> allColorsMap = {
    'Beige': const Color(0xFFE8D8B5),
    'Black': Colors.black,
    'Brown': Colors.brown,
    'Clear': const Color.fromARGB(255, 235, 240, 255),
    'Gold': const Color.fromARGB(255, 191, 162, 0),
    'Gray': const Color.fromARGB(255, 141, 141, 133),
    'Green': Colors.green,
    'Multicolored': const Color(0xFFF4F4DC),
    'Off-white': const Color(0xFFF2F2F2),
    'Orange': Colors.orange,
    'Pink': const Color.fromARGB(255, 255, 110, 158),
    'Purple': Colors.purple,
    'Red': Colors.red,
    'Silver': const Color.fromARGB(255, 75, 75, 62),
    'White': Colors.white,
    'Yellow': Colors.yellow,
  };
  List<String> selectedColorNames = [];

  final List<String> types = ['Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Accessories', 'Dresses'];
  Set<String> selectedType = {};

  Widget filterSelectionSheet(
    List<String> filterOptions,
    Set<String> currentlyChosenFilters,
    void Function(Set<String> newChosenFilters) onSubmit, {
    Widget Function(String optionName)? iconCreatorFunction,
  }) {
    Set<String> tempChosenOptions = Set.from(currentlyChosenFilters);
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return SizedBox(
          height: 400,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      child: const Text('Clear'),
                      onPressed: () => setSheetState(() => tempChosenOptions.clear()),
                    ),
                    ElevatedButton(
                      child: const Text('Submit'),
                      onPressed: () {
                        onSubmit(tempChosenOptions);
                        Navigator.pop(context, true);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: filterOptions.map((filterOption) {
                    final isSelected = tempChosenOptions.contains(filterOption);
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFF2D3561),
                            onChanged: (_) => setSheetState(() {
                              if (isSelected) {
                                tempChosenOptions.remove(filterOption);
                              } else {
                                tempChosenOptions.add(filterOption);
                              }
                            }),
                          ),
                          title: Text(filterOption),
                          trailing: iconCreatorFunction == null
                              ? null
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: iconCreatorFunction!(filterOption),
                                ),
                          onTap: () => setSheetState(() {
                            if (isSelected) {
                              tempChosenOptions.remove(filterOption);
                            } else {
                              tempChosenOptions.add(filterOption);
                            }
                          }),
                        ),
                        const Divider(height: 1),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar 
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: closetTab == 0 ? const Color(0xFF2d3561) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'My Closet',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.rockSalt(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: closetTab == 1 ? const Color(0xFF2d3561) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'Saved Outfits',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.rockSalt(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: closetTab == 1 ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchOpen = !_searchOpen;
                        if (!_searchOpen) {
                          searchController.clear();
                          searchQuery = '';
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _searchOpen ? const Color(0xFF2d3561) : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _searchOpen ? Icons.search_off : Icons.search,
                        color: _searchOpen ? Colors.white : const Color(0xFF1a1a2e),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => isGridView = !isGridView),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGridView ? Icons.view_list : Icons.grid_view,
                        color: const Color(0xFF1a1a2e),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              // Collapsible search bar 
              if (closetTab == 0 && _searchOpen) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                            onPressed: () => setState(() {
                              searchController.clear();
                              searchQuery = '';
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],

              // Filter chips + item count 
              if (closetTab == 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filteredItems.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length + (hasActiveFilters ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            if (hasActiveFilters && index == filters.length) {
                              return GestureDetector(
                                onTap: clearAllFilters,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final filter = filters[index];
                            final isSelected = selectedFilter == filter;
                            final bool hasValue =
                                (filter == 'Season' && selectedSeason.isNotEmpty) ||
                                (filter == 'Occasion' && selectedOccasion.isNotEmpty) ||
                                (filter == 'Color' && selectedColorNames.isNotEmpty) ||
                                (filter == 'Type' && selectedType.isNotEmpty);

                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedFilter = isSelected ? null : filter);
                                if (!isSelected) openBottomSheet(filter);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: hasValue || isSelected ? const Color(0xFF2d3561) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: hasValue || isSelected
                                        ? const Color(0xFF2d3561)
                                        : const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      filter,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: hasValue || isSelected
                                            ? Colors.white
                                            : const Color(0xFF1a1a2e),
                                      ),
                                    ),
                                    if (hasValue) ...[
                                      const SizedBox(width: 5),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              //Saved Outfits tab 
              if (closetTab == 1)
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
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1a1a2e)),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Build and save outfits in the Planner tab',
                                      style: TextStyle(color: Colors.grey)),
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
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                      color: Color(0xFF1a1a2e)),
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

              // My Closet grid/list 
              if (closetTab == 0)
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
                                  const Text('Tap + to add your first item',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : isGridView
                              ? GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: filteredItems.length,
                                  itemBuilder: (context, index) => _clothesCard(filteredItems[index]),
                                )
                              : ListView.builder(
                                  itemCount: filteredItems.length,
                                  itemBuilder: (context, index) =>
                                      _clothesListTitle(filteredItems[index]),
                                ),
                ),

              // Item Showcase button + add item
              if (closetTab == 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ShowcaseCloset()),
                            
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2d3561),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.stars, color: Colors.white),
          
                          label: Text(
                            'Showcase',
                            style: GoogleFonts.rockSalt(
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UploadPage()),
                          );
                          fetchItems();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2d3561),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: item['image_url'] != null
                  ? Image.network(item['image_url'], width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFF0F2F5),
                      child: const Center(child: Icon(Icons.checkroom, size: 48, color: Colors.grey)),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + stacked delete/edit icons 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
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
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete, size: 18, color: Colors.red),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UploadPage(existingClothingItem: item),
                              ),
                            );
                            fetchItems();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.edit, size: 18, color: Colors.grey),
                          ),
                        ),
                      ],
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

  Widget _clothesListTitle(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: item['image_url'] != null
                ? Image.network(item['image_url'], width: 100, height: 100, fit: BoxFit.cover)
                : Container(
                    width: 100,
                    height: 100,
                    color: const Color(0xFFF0F2F5),
                    child: const Center(child: Icon(Icons.checkroom, size: 48, color: Colors.grey)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1a1a2e),
                  ),
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
          Column(
            children: [
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadPage(existingClothingItem: item),
                    ),
                  );
                  fetchItems();
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit, size: 18, color: Colors.grey),
                ),
              ),
              GestureDetector(
                onTap: () {
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
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete, size: 18, color: Colors.red),
                ),
              ),
            ],
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