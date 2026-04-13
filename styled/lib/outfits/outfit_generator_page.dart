import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

class OutfitGeneratorPage extends StatefulWidget {
  const OutfitGeneratorPage({super.key});

  @override
  State<OutfitGeneratorPage> createState() => _OutfitGeneratorPageState();
}

class _OutfitGeneratorPageState extends State<OutfitGeneratorPage> {
  final occasionController = TextEditingController();
  List<Map<String, dynamic>> closetItems = [];
  List<Map<String, dynamic>> selectedItems = [];
  List<Map<String, dynamic>> generatedOutfit = [];
  String? outfitExplanation;
  bool isLoading = false;
  bool isGenerating = false;
  int mode = 0; // 0 = pick items, 1 = by occasion, 2 = build outfit

  // Build Outfit slots
  Map<String, dynamic>? selectedTop;
  Map<String, dynamic>? selectedBottom;
  Map<String, dynamic>? selectedShoes;
  Map<String, dynamic>? selectedAccessory;

  @override
  void initState() {
    super.initState();
    fetchCloset();
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

      final closetDescription = closetItems.map((item) =>
        'itemId:${item['itemId']}, Name:${item['name']}, Category:${item['category']}, Color:${item['color']}, Season:${item['season']}, Occasion:${item['occasion']}'
      ).join('\n');

      String prompt;
      if (mode == 0 && selectedItems.isNotEmpty) {
        final selected = selectedItems.map((item) =>
          '${item['name']} (${item['category']})'
        ).join(', ');
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

      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final text = responseJson['candidates'][0]['content']['parts'][0]['text'] as String;

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

  Future<void> saveOutfit() async {
    if (generatedOutfit.isEmpty) return;
    try {
      final itemIds = generatedOutfit.map((item) => item['itemId'] as int).toList();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('outfits').insert({
        'name': occasionController.text.isNotEmpty
            ? '${occasionController.text} Outfit'
            : 'AI Generated Outfit',
        'occasion': occasionController.text,
        'items': itemIds,
        'owner_id': userId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit saved! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Widget _buildSlot({
    required String label,
    required String emoji,
    required Map<String, dynamic>? selected,
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
          const Icon(Icons.add_circle_outline, color: Color(0xFF2d3561), size: 22),
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
        title: Text(
          'AI Outfit Planner',
          style: GoogleFonts.rockSalt(
            fontStyle: FontStyle.italic,
            color: Color(0xFF1a1a2e),
            fontWeight: FontWeight.bold,
            fontSize: 28,
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
                _buildSlot(label: 'TOP', emoji: '👕', selected: selectedTop),
                _buildSlot(label: 'BOTTOM', emoji: '👖', selected: selectedBottom),
                _buildSlot(label: 'SHOES', emoji: '👟', selected: selectedShoes),
                _buildSlot(label: 'ACCESSORY', emoji: '🧢', selected: selectedAccessory),
              ],

              const SizedBox(height: 24),

              // Generate button (only for mode 0 and 1)
              if (mode == 0 || mode == 1)
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
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(width: 12),
                              Text('Generating...', style: TextStyle(color: Colors.white)),
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

              // Generated outfit result
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
                      style: const TextStyle(color: Color(0xFF1a1a2e), fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: item['image_url'] != null
                                  ? Image.network(
                                      item['image_url'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFFF0F2F5),
                                      child: const Center(
                                        child: Icon(Icons.checkroom,
                                            size: 48, color: Colors.grey),
                                      ),
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
                                color: Color(0xFF1a1a2e),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Save outfit button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: saveOutfit,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFF2d3561)),
                    ),
                    child: const Text(
                      'Save Outfit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3561),
                      ),
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