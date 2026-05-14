import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool isGenerating = false;
  List<Map<String, dynamic>> generatedOutfit = [];
  String? outfitExplanation;

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
          (lower == 'top' &&
              (cat.contains('shirt') ||
                  cat.contains('top') ||
                  cat.contains('blouse') ||
                  cat.contains('jacket') ||
                  cat.contains('hoodie'))) ||
          (lower == 'bottom' &&
              (cat.contains('pant') ||
                  cat.contains('jean') ||
                  cat.contains('skirt') ||
                  cat.contains('shorts') ||
                  cat.contains('bottom'))) ||
          (lower == 'shoes' &&
              (cat.contains('shoe') ||
                  cat.contains('sneaker') ||
                  cat.contains('boot') ||
                  cat.contains('loafer') ||
                  cat.contains('heel'))) ||
          (lower == 'accessory' &&
              (cat.contains('access') ||
                  cat.contains('hat') ||
                  cat.contains('bag') ||
                  cat.contains('belt') ||
                  cat.contains('jewelry')));
    }).toList();
  }

  void _showItemPicker(
    String slotLabel,
    String category,
    Function(Map<String, dynamic>) onPick,
  ) {
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
                                    child: const Icon(Icons.checkroom,
                                        color: Colors.grey),
                                  ),
                            title: Text(
                              item['name'] ?? 'Unnamed',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item['category'] ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
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

  Future<void> generateOutfit() async {
    if (mode == 0 && selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item!')),
      );
      return;
    }
    if (mode == 1 && occasionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an occasion!')),
      );
      return;
    }

    setState(() {
      isGenerating = true;
      generatedOutfit = [];
      outfitExplanation = null;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      final closetDescription = closetItems
          .map((item) =>
              'itemId:${item['itemId']}, Name:${item['name']}, Category:${item['category']}, Color:${item['color']}, Season:${item['season']}, Occasion:${item['occasion']}')
          .join('\n');

      String prompt;
      if (mode == 0 && selectedItems.isNotEmpty) {
        final selected = selectedItems
            .map((item) => '${item['name']} (${item['category']})')
            .join(', ');
        prompt = '''
You are a fashion stylist. The user has selected: $selected.
From the following closet items, suggest a complete outfit that works well with the selected items.
Return ONLY a valid JSON object, no extra text, no markdown:
{
  "outfit": [1, 2, 3],
  "explanation": "Brief explanation of why this outfit works"
}
Only use itemId numbers from this list:
$closetDescription
''';
      } else {
        final occasion = occasionController.text.trim();
        prompt = '''
You are a fashion stylist. Generate a complete outfit for the occasion: $occasion.
From the following closet items, pick the best combination.
Return ONLY a valid JSON object, no extra text, no markdown:
{
  "outfit": [1, 2, 3],
  "explanation": "Brief explanation of why this outfit works"
}
Only use itemId numbers from this list:
$closetDescription
''';
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final text = responseJson['candidates'][0]['content']['parts'][0]
            ['text'] as String;

        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          final json = jsonDecode(jsonMatch.group(0)!);
          final outfitIds = List<int>.from(json['outfit']);
          final explanation = json['explanation'] as String;

          final outfitItems = closetItems
              .where((item) => outfitIds.contains(item['itemId']))
              .toList();

          setState(() {
            generatedOutfit = outfitItems;
            outfitExplanation = explanation;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('API Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => isGenerating = false);
  }

  Future<void> saveAIOutfit() async {
    if (outfitNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your outfit a name!')),
      );
      return;
    }

    if (generatedOutfit.isEmpty) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      Map<String, dynamic>? aiTop;
      Map<String, dynamic>? aiBottom;
      Map<String, dynamic>? aiShoes;
      Map<String, dynamic>? aiAccessory;

      for (final item in generatedOutfit) {
        final cat = (item['category'] ?? '').toString().toLowerCase();
        if (cat.contains('top') ||
            cat.contains('shirt') ||
            cat.contains('blouse') ||
            cat.contains('jacket') ||
            cat.contains('hoodie')) {
          aiTop = item;
        } else if (cat.contains('bottom') ||
            cat.contains('pant') ||
            cat.contains('jean') ||
            cat.contains('skirt') ||
            cat.contains('shorts')) {
          aiBottom = item;
        } else if (cat.contains('shoe') ||
            cat.contains('sneaker') ||
            cat.contains('boot') ||
            cat.contains('heel') ||
            cat.contains('loafer')) {
          aiShoes = item;
        } else if (cat.contains('access') ||
            cat.contains('hat') ||
            cat.contains('bag') ||
            cat.contains('belt') ||
            cat.contains('jewelry')) {
          aiAccessory = item;
        }
      }

      await Supabase.instance.client.from('outfits').insert({
        'profile_id': userId,
        'name': outfitNameController.text.trim(),
        'top_id': aiTop?['itemId']?.toString(),
        'bottom_id': aiBottom?['itemId']?.toString(),
        'shoes_id': aiShoes?['itemId']?.toString(),
        'accessory_id': aiAccessory?['itemId']?.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Outfit saved! 🎉'),
            backgroundColor: Color(0xFF2d3561),
          ),
        );
        setState(() {
          generatedOutfit = [];
          outfitExplanation = null;
          outfitNameController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving AI outfit: $e')),
        );
      }
    }
  }

  Future<void> saveOutfit() async {
    if (outfitNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your outfit a name!')),
      );
      return;
    }
    if (selectedTop == null &&
        selectedBottom == null &&
        selectedShoes == null &&
        selectedAccessory == null) {
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
        'top_id': selectedTop?['itemId']?.toString(),
        'bottom_id': selectedBottom?['itemId']?.toString(),
        'shoes_id': selectedShoes?['itemId']?.toString(),
        'accessory_id': selectedAccessory?['itemId']?.toString(),
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
        color: selected != null
            ? const Color(0xFFEEF0FF)
            : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected != null
              ? const Color(0xFF2d3561)
              : const Color(0xFFE0E0E0),
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
            child: selected != null && selected['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      selected['image_url'],
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  selected != null
                      ? selected['name'] ?? 'Unnamed'
                      : 'Tap to pick',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected != null
                        ? const Color(0xFF1a1a2e)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          selected != null
              ? GestureDetector(
                  onTap: onClear,
                  child:
                      const Icon(Icons.close, color: Colors.grey, size: 20),
                )
              : const Icon(Icons.add_circle_outline,
                  color: Color(0xFF2d3561), size: 22),
        ],
      ),
    );
  }

  Widget _buildModeDescription() {
    final descriptions = [
      {
        'icon': Icons.touch_app_outlined,
        'title': 'Pick Items',
        'subtitle':
            'Select one or more pieces you want to wear, the AI will build a full outfit around them.',
      },
      {
        'icon': Icons.event_outlined,
        'title': 'By Occasion',
        'subtitle':
            'Tell us where you\'re going and the AI will pick the best outfit from your closet for you.',
      },
      {
        'icon': Icons.style_outlined,
        'title': 'Build Outfit',
        'subtitle':
            'Manually pick each piece yourself; top, bottom, shoes, and accessory; then save it.',
      },
    ];

    final d = descriptions[mode];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(d['icon'] as IconData,
              color: const Color(0xFF2d3561), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              d['subtitle'] as String,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2d3561),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClosetWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.checkroom_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Your closet is empty!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add clothes to your closet first before planning an outfit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            '👉 Go to the Closet tab and tap + to add your first item.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2d3561),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = closetItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Outfit Planner',
          style: GoogleFonts.rockSalt(
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1a1a2e),
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

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _modeTab('Pick Items', 0),
                    _modeTab('By Occasion', 1),
                    _modeTab('Build Outfit', 2),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _buildModeDescription(),

              const SizedBox(height: 20),

              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (!hasItems)
                _buildEmptyClosetWarning()
              else ...[

                if (mode == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select items to build around:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                      if (selectedItems.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => selectedItems.clear()),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2d3561),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (selectedItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''} selected, tap Generate to build your outfit',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 6),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.checkroom,
                                                color: Colors.grey),
                                            Text(
                                              item['name'] ?? '',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 10),
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

                if (mode == 0 || mode == 1) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isGenerating ? null : generateOutfit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2d3561),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isGenerating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Generating...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
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
                ],

                if (generatedOutfit.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Your AI Outfit ✨',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (outfitExplanation != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        outfitExplanation!,
                        style: const TextStyle(
                            color: Color(0xFF1a1a2e), fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: generatedOutfit.length,
                    itemBuilder: (context, index) {
                      final item = generatedOutfit[index];
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
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: item['image_url'] != null
                                    ? Image.network(item['image_url'],
                                        width: double.infinity,
                                        fit: BoxFit.cover)
                                    : Container(
                                        color: const Color(0xFFF0F2F5),
                                        child: const Center(
                                            child: Icon(Icons.checkroom,
                                                size: 48,
                                                color: Colors.grey)),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1a1a2e)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: outfitNameController,
                    decoration: InputDecoration(
                      hintText: 'Give this outfit a name...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                          Icons.drive_file_rename_outline,
                          color: Color(0xFF2d3561)),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: saveAIOutfit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2d3561),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_add, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Save Outfit',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],

                if (mode == 2) ...[
                  GestureDetector(
                    onTap: () => _showItemPicker('Top', 'top',
                        (item) => setState(() => selectedTop = item)),
                    child: _buildSlot(
                        label: 'TOP',
                        emoji: '👕',
                        selected: selectedTop,
                        onClear: () => setState(() => selectedTop = null)),
                  ),
                  GestureDetector(
                    onTap: () => _showItemPicker('Bottom', 'bottom',
                        (item) => setState(() => selectedBottom = item)),
                    child: _buildSlot(
                        label: 'BOTTOM',
                        emoji: '👖',
                        selected: selectedBottom,
                        onClear: () =>
                            setState(() => selectedBottom = null)),
                  ),
                  GestureDetector(
                    onTap: () => _showItemPicker('Shoes', 'shoes',
                        (item) => setState(() => selectedShoes = item)),
                    child: _buildSlot(
                        label: 'SHOES',
                        emoji: '👟',
                        selected: selectedShoes,
                        onClear: () =>
                            setState(() => selectedShoes = null)),
                  ),
                  GestureDetector(
                    onTap: () => _showItemPicker(
                        'Accessory',
                        'accessory',
                        (item) =>
                            setState(() => selectedAccessory = item)),
                    child: _buildSlot(
                        label: 'ACCESSORY',
                        emoji: '🧢',
                        selected: selectedAccessory,
                        onClear: () =>
                            setState(() => selectedAccessory = null)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: outfitNameController,
                    decoration: InputDecoration(
                      hintText: 'Give your outfit a name...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                          Icons.drive_file_rename_outline,
                          color: Color(0xFF2d3561)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(String label, int index) {
    final isActive = mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          mode = index;
          generatedOutfit = [];
          outfitExplanation = null;
          selectedItems.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2d3561) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.rockSalt(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}