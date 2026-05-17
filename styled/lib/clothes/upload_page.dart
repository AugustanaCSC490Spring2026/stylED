import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class UploadPage extends StatefulWidget {
  final Map<String, dynamic>? existingClothingItem; // for edit mode

  const UploadPage({super.key, this.existingClothingItem});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Uint8List? _imageBytes;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedType;
  Color selectedColor = Colors.blue;
  Set<String> selectedColorNames = {};
  String selectedSeason = 'All Seasons';
  String selectedOccasion = 'Formal';
  DateTime? dateLastWorn;
  bool collectionOnly = false;
  bool isLoading = false;
  bool? isTie; // null = not asked yet, true/false = user answered

  final List<String> types = [
    'Tops',
    'Bottoms',
    'Outerwear',
    'Shoes',
    'Accessories',
    'Dresses',
  ];
  final List<String> seasons = [
    'All Seasons',
    'Winter',
    'Summer',
    'Fall',
    'Spring',
  ];
  final List<String> occasions = ['Formal', 'Casual', 'Athletic'];

  final List<Map<String, dynamic>> allColors = [
    {'name': 'Beige', 'color': const Color(0xFFE8D8B5)}, 
    {'name': 'Black', 'color': Colors.black},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Brown', 'color': Colors.brown},
    {'name': 'Clear', 'color': const Color.fromARGB(255, 235, 240, 255),},
    {'name': 'Gold', 'color': const Color.fromARGB(255, 191, 162, 0)},
    {'name': 'Gray', 'color': const Color.fromARGB(255, 141, 141, 133)},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Multicolored', 'color': const Color(0xFFF4F4DC)},
    {'name': 'Off-white', 'color': const Color(0xFFF2F2F2)},
    {'name': 'Orange', 'color': Colors.orange},
    {'name': 'Pink', 'color': Colors.pink},
    {'name': 'Purple', 'color': Colors.purple},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Silver', 'color': const Color.fromARGB(255, 75, 75, 62)},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Yellow', 'color': Colors.yellow},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if we're in edit mode
    final item = widget.existingClothingItem;
   

    if (item != null) {
      nameController.text = item['name'] ?? '';
      descriptionController.text = item['description'] ?? '';
      selectedType = item['category'];
      selectedSeason = item['season'] ?? 'All Seasons';
      selectedOccasion = item['occasion'] ?? 'Formal';
      collectionOnly = item['collection_only'] ?? false;
      isTie = item['is_tie'] as bool?; //tie identification isn't lost when coming back to edit an item
      if (item['color'] != null) {
        selectedColorNames = Set.from(
          (item['color'] as String).split(', ').where((c) => c.isNotEmpty),
        );
      }
      if (item['dateLastWorn'] != null) {
        dateLastWorn = DateTime.tryParse(item['dateLastWorn']);
      }
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() => _imageBytes = bytes);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 32,
                            color: Color(0xFF2d3561),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() => _imageBytes = bytes);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 32,
                            color: Color(0xFF2d3561),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> saveItem() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Keep existing image by default in edit mode
      String? imageUrl = widget.existingClothingItem?['image_url'];

      // Upload new image if one was picked
      if (_imageBytes != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final path = 'upload/$fileName.jpg';
        await Supabase.instance.client.storage
            .from('images')
            .uploadBinary(path, _imageBytes!);
        imageUrl = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(path);
      }

      final data = {
        'name': nameController.text.trim(),
        'category': selectedType,
        'is_tie': isTie ?? false, //assumes that an item is usually not a tie, ties have to be declared separately
        'color': selectedColorNames.join(', '),
        'season': selectedSeason,
        'occasion': selectedOccasion,
        'description': descriptionController.text.trim(),
        'dateLastWorn': dateLastWorn?.toIso8601String().split('T')[0],
        'image_url': imageUrl,
        'collection_only': collectionOnly,
        'profile_id': Supabase.instance.client.auth.currentUser?.id, // ADD THIS
      };

      if (widget.existingClothingItem != null) {
        // Edit mode — update existing row
        await Supabase.instance.client
            .from('clothes')
            .update(data)
            .eq('itemId', widget.existingClothingItem!['itemId']);
      } else {
        // Add mode — insert new row
        await Supabase.instance.client.from('clothes').insert({
          ...data,
          'timesWorn': 0,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingClothingItem != null
                  ? 'Item updated!'
                  : 'Item saved to your closet!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingClothingItem != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1a1a2e)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Edit Item' : 'Add New Item',
          style: const TextStyle(
            color: Color(0xFF1a1a2e),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload box
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFCCCCCC),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : isEditMode &&
                            widget.existingClothingItem!['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.existingClothingItem!['image_url'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Upload Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1a1a2e),
                              ),
                            ),
                            Text(
                              'Tap to add image',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Item Name
              _label('Item Name'),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Blue Oxford Shirt',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Type dropdown
              _label('Type'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedType,
                    hint: const Text(
                      'Select type...',
                      style: TextStyle(color: Colors.grey),
                    ),
                    items: types
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedType = val);
                      if (val == 'Accessories') {
                        tieQuestionPopUp();
                        }

                    }, 
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Color
              _label('Color'),
              const SizedBox(height: 8),
              ...allColors.map((item) {
                final isSelected = selectedColorNames.contains(item['name']);
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF2D3561),
                        onChanged: (_) => setState(() {
                          if (isSelected) {
                            selectedColorNames.remove(item['name']);
                          } else {
                            selectedColorNames.add(item['name']);
                          }
                        }),
                      ),
                      title: Text(item['name']),
                      trailing: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundColor: item['name'] == 'Multicolored'
                              ? Colors.transparent
                              : item['color'] as Color,
                          backgroundImage: item['name'] == 'Multicolored'
                              ? const AssetImage('assets/icons/multi.png')
                              : null,
                          radius: 14,
                        ),
                      ),
                      onTap: () => setState(() {
                        if (isSelected) {
                          selectedColorNames.remove(item['name']);
                        } else {
                          selectedColorNames.add(item['name']);
                        }
                      }),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),

              // Season
              _label('Season'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: seasons.map((season) {
                  final isSelected = selectedSeason == season;
                  return GestureDetector(
                    onTap: () => setState(() => selectedSeason = season),
                    child: Container(
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
                        season,
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
              const SizedBox(height: 20),

              // Occasion
              _label('Occasion'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: occasions.map((occasion) {
                  final isSelected = selectedOccasion == occasion;
                  return GestureDetector(
                    onTap: () => setState(() => selectedOccasion = occasion),
                    child: Container(
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
                        occasion,
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
              const SizedBox(height: 20),

              // Description
              _label('Description (Optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add notes about fit, brand, etc.',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Last Worn
              _label('Date Last Worn'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => dateLastWorn = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateLastWorn == null
                            ? 'mm/dd/yyyy'
                            : '${dateLastWorn!.month}/${dateLastWorn!.day}/${dateLastWorn!.year}',
                        style: TextStyle(
                          color: dateLastWorn == null
                              ? Colors.grey
                              : const Color(0xFF1a1a2e),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Collection Only toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection Only',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a1a2e),
                          ),
                        ),
                        Text(
                          "Don't include in outfit suggestions",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Switch(
                      value: collectionOnly,
                      onChanged: (val) => setState(() => collectionOnly = val),
                      activeThumbColor: const Color(0xFF2d3561),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2d3561),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Save Changes' : 'Save Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

   void tieQuestionPopUp() {
    showDialog(
    context: context,
    barrierDismissible: true, // if you tap outside of popup you can dismiss it 
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Is this a tie?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1a1a2e),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () {
            setState(() => isTie = false); //assumes that the accessory is not a tie, meaning that ties have to be declared to be considered such
            Navigator.pop(context);
          },
          child: const Text('No', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() => isTie = true);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2d3561),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Yes', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  }


  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF1a1a2e),
      ),
    );
  }
}
