import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:typed_data';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Uint8List? _imageBytes;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedType;
  Color selectedColor = Colors.blue;
  String selectedSeason = 'All Seasons';
  String selectedOccasion = 'Formal';
  DateTime? dateLastWorn;
  bool collectionOnly = false;
  bool isLoading = false;

  final List<String> types = ['Tops','Bottoms','Outerwear','Shoes','Accessories','Dresses',];
  final List<String> seasons = ['All Seasons','Winter','Summer','Fall','Spring',];
  final List<String> occasions = ['Formal', 'Casual', 'Athletic'];
  final List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.black,
    Colors.white,
  ];
  final List<String> colorNames = ['Blue', 'Red', 'Green', 'Black', 'White'];

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();

      setState(() {
        _imageBytes = bytes;
      });
     // setState(() => _imageFile = File(image.path));
    }
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
      String? imageUrl;

      // Upload image if selected
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

      // Save to clothes table
      await Supabase.instance.client.from('clothes').insert({
        'name': nameController.text.trim(),
        'category': selectedType,
        'color': selectedColor.value.toRadixString(16),
        'season': selectedSeason,
        'occasion': selectedOccasion,
        'description': descriptionController.text.trim(),
        'dateLastWorn': dateLastWorn?.toIso8601String().split('T')[0],
        'timesWorn': 0,
        'image_url': imageUrl,
        'collection_only': collectionOnly,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved to your closet!')),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1a1a2e)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Item',
          style: TextStyle(
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
                    onChanged: (val) => setState(() => selectedType = val),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Color
              _label('Color'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick a color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: selectedColor,
                          onColorChanged: (color) =>
                              setState(() => selectedColor = color),
                          enableAlpha: false,
                          labelTypes: const [],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Done',
                            style: TextStyle(color: Color(0xFF2d3561)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tap to pick color',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

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
                      activeColor: const Color(0xFF2d3561),
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
                      : const Text(
                          'Save Item',
                          style: TextStyle(
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
