import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutfitGeneratorPage extends StatefulWidget {
  const OutfitGeneratorPage({super.key});

  @override
  State<OutfitGeneratorPage> createState() => _OutfitGeneratorPageState();
}

class _OutfitGeneratorPageState extends State<OutfitGeneratorPage> {
  final occasionController = TextEditingController();
  final outfitNameController = TextEditingController();
  List<Map<String, dynamic>> closetItems = [];
  List<Map<String, dynamic>> selectedItems = [];
  bool isLoading = false;

  // Build Outfit slots
  Map<String, dynamic>? selectedTop;
  Map<String, dynamic>? selectedBottom;
  Map<String, dynamic>? selectedShoes;
  Map<String, dynamic>? selectedAccessory;

  int mode = 0; // 0 = pick items, 1 = by occasion, 2 = build outfit

 @override
  void initState() {
    super.initState();
    fetchCloset();
  }

  List<Map<String, dynamic>> _itemsByCategory(String category) {
    final lower = category.toLowerCase();
    return closetItems.where((item) {
      final cat = (item['category'] ?? '').toString().toLowerCase();
      return cat.contains(lower) ||
          (lower == 'top' && (cat.contains('shirt') || cat.contains('top') || cat.contains('blouse') || cat.contains('jacket') || cat.contains('hoodie'))) ||
          (lower == 'bottom' && (cat.contains('pant') || cat.contains('jean') || cat.contains('skirt') || cat.contains('shorts') || cat.contains('bottom'))) ||
          (lower == 'shoes' && (cat.contains('shoe') || cat.contains('sneaker') || cat.contains('boot') || cat.contains('loafer') || cat.contains('heel'))) ||
          (lower == 'accessory' && (cat.contains('access') || cat.contains('hat') || cat.contains('bag') || cat.contains('belt') || cat.contains('jewelry')));
    }).toList();
  }

  void _showItemPicker(String slotLabel, String category, Function(Map<String, dynamic>) onPick) {
    final items = _itemsByCategory(category);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick a $slotLabel',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
              const SizedBox(height: 16),
              items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No $slotLabel items in your closet yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            leading: item['image_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['image_url'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F2F5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.checkroom, color: Colors.grey),
                                  ),
                            title: Text(
                              item['name'] ?? 'Unnamed',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item['category'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            onTap: () {
                              onPick(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }


  Future<void> saveOutfit() async {
    if (outfitNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your outfit a name!')),
      );
      return;
    }
    if (selectedTop == null && selectedBottom == null && selectedShoes == null && selectedAccessory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item!')),
      );
      return;
    }
    try { 
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('outfits').insert({
        'profile_id': userId,
        'name': outfitNameController.text.trim(),
        'top_id': selectedTop?['id'],
        'bottom_id': selectedBottom?['id'],
        'shoes_id': selectedShoes?['id'],
        'accessory_id': selectedAccessory?['id'],
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outfit saved! 🎉'),
            backgroundColor: Color(0xFF2d3561),
          ),
        );
        setState(() {
          selectedTop = null;
          selectedBottom = null;
          selectedShoes = null;
          selectedAccessory = null;
          outfitNameController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving outfit: $e')),
      );
    }
  }
  Future<void> fetchCloset() async {
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
      closetItems = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  } catch (e) {
    debugPrint('Error: $e');
    setState(() => isLoading = false);
  }
}

Widget _buildSlot({
  required String label,
  required String emoji,
  required Map<String, dynamic>? selected,
  required VoidCallback onClear,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: selected != null ? const Color(0xFFEEF0FF) : const Color(0xFFF8F8FA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected != null ? const Color(0xFF2d3561) : const Color(0xFFE0E0E0),
        width: selected != null ? 2 : 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                selected != null ? selected['name'] ?? 'Unnamed' : 'Tap to pick',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected != null ? const Color(0xFF1a1a2e) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        selected != null
            ? GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              )
            : const Icon(Icons.add_circle_outline, color: Color(0xFF2d3561), size: 22),
      ],
    ),
  );
} 


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'AI Outfit Planner',
          style: TextStyle(
            color: Color(0xFF1a1a2e),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Mode selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => mode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: mode == 0 ? const Color(0xFF2d3561) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Pick Items',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: mode == 0 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => mode = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: mode == 1 ? const Color(0xFF2d3561) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'By Occasion',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: mode == 1 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => mode = 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: mode == 2 ? const Color(0xFF2d3561) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Build Outfit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: mode == 2 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
                   

              // Mode 0: Pick items
              if (mode == 0) ...[
                const Text(
                  'Select items to build around:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                const SizedBox(height: 12),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: closetItems.length,
                        itemBuilder: (context, index) {
                          final item = closetItems[index];
                          final isSelected = selectedItems.contains(item);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedItems.remove(item);
                                } else {
                                  selectedItems.add(item);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2d3561)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    item['image_url'] != null
                                        ? Image.network(
                                            item['image_url'],
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: const Color(0xFFF0F2F5),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.checkroom, color: Colors.grey),
                                                Text(
                                                  item['name'] ?? '',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                              ],
                                            ),
                                          ),
                                    if (isSelected)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2d3561),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],

              // Mode 1: By occasion
              if (mode == 1) ...[
                const Text(
                  'What\'s the occasion?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: occasionController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Casual dinner, Job interview...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],

             if (mode == 0 || mode == 1) const SizedBox(height: 24),

              // Generate button (only for mode 0 and 1)
              if (mode == 0 || mode == 1)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2d3561),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Generate Outfit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
               
              if (mode == 2) const SizedBox(height: 0),

              // Mode 2: Build Outfit placeholder
              if (mode == 2) ...[
                const Text(
                  'Build your outfit:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1a1a2e)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap each slot to pick from your closet',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Top slot
          GestureDetector(
                  onTap: () => _showItemPicker('Top', 'top', (item) => setState(() => selectedTop = item)),
                  child: _buildSlot(label: 'TOP', emoji: '👕', selected: selectedTop, onClear: () => setState(() => selectedTop = null)),
                ),
                GestureDetector(
                  onTap: () => _showItemPicker('Bottom', 'bottom', (item) => setState(() => selectedBottom = item)),
                  child: _buildSlot(label: 'BOTTOM', emoji: '👖', selected: selectedBottom, onClear: () => setState(() => selectedBottom = null)),
                ),
                GestureDetector(
                  onTap: () => _showItemPicker('Shoes', 'shoes', (item) => setState(() => selectedShoes = item)),
                  child: _buildSlot(label: 'SHOES', emoji: '👟', selected: selectedShoes, onClear: () => setState(() => selectedShoes = null)),
                ),
                GestureDetector(
                  onTap: () => _showItemPicker('Accessory', 'accessory', (item) => setState(() => selectedAccessory = item)),
                  child: _buildSlot(label: 'ACCESSORY', emoji: '🧢', selected: selectedAccessory, onClear: () => setState(() => selectedAccessory = null)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: outfitNameController,
                  decoration: InputDecoration(
                    hintText: 'Give your outfit a name...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.drive_file_rename_outline, color: Color(0xFF2d3561)),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: saveOutfit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2d3561),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save Outfit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
           
            ],
          ),
        ),
      ),
    );
  }
}