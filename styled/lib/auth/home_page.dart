import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../clothes/digital_closet.dart';
import '../users/user_page.dart'; 
import '../history/history_page.dart';
import 'login_page.dart';
import '../outfits/outfit_generator_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const DigitalCloset(),
    const OutfitGeneratorPage(),
    const HistoryPage(),
    const ProfilePage(), 
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2d3561),
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Closet'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Planner'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _userName = '';
  int _totalItems = 0;
  int _totalOutfits = 0;
  Map<String, dynamic>? _mostWornItem;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
        final userId = user.id;
        final email = user.email ?? '';
      final response = await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .maybeSingle();
      final userName = response?['name'] ?? 'there';

      setState(() {
        //_userName = email.split('@').first;
        _userName = userName;
      });

      try {
        final response = await Supabase.instance.client
            .from('clothes')
            .select()
            .eq('profile_id', userId);

        final outfitResponse = await Supabase.instance.client
            .from('outfits')
            .select()
            .eq('profile_id', userId)
            .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

        // count how many times each itemId appears across all outfits
        final Map<String, int> itemCount = {};
        for (final outfit in outfitResponse as List) {
          for (final key in ['top_id', 'bottom_id', 'shoes_id', 'accessory_id']) {
            final id = outfit[key]?.toString();
            if (id != null) itemCount[id] = (itemCount[id] ?? 0) + 1;
          }
        }

        Map<String, dynamic>? mostWorn;
        if (itemCount.isNotEmpty) {
          final topId = itemCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          final clothes = List<Map<String, dynamic>>.from(response as List);
          mostWorn = clothes.firstWhere(
            (item) => item['itemId'].toString() == topId,
            orElse: () => {},
          );
          if (mostWorn!.isEmpty) mostWorn = null;
        }

        setState(() {
          _totalItems = (response as List).length;
          _totalOutfits = (outfitResponse as List).length;
          _mostWornItem = mostWorn;
        });

      } catch (e) {
        // ignore error
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getShortName() {
    if (_userName.isEmpty) return 'there';
    final parts = _userName.split('.');
    if (parts.isNotEmpty) {
      final first = parts[0];
      return first[0].toUpperCase() + first.substring(1);
    }
    return _userName.length > 10 ? _userName.substring(0, 10) : _userName;
  }

  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Greeting + Sign Out
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, ${_getShortName()}.',
                        style: GoogleFonts.rockSalt(
                          fontStyle: FontStyle.italic,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedDate(),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => signOut(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 13, color: Color(0xFF2d3561)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '$_totalItems',
                    label: 'Total Items',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: '$_totalOutfits',
                    label: 'Outfits This Month',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Most Worn Item Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Color(0xFF2d3561), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Most Worn Item',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        _mostWornItem == null
                            ? const Text(
                                'Add items to your closet!',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1a1a2e)),
                              )
                            : Row(
                                children: [
                                  if (_mostWornItem!['image_url'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _mostWornItem!['image_url'],
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _mostWornItem!['name'] ?? 'Unknown',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1a1a2e)),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Closet Breakdown Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Closet Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _totalItems == 0
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No items yet. Add clothes to see your breakdown!',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            _BreakdownRow(label: 'Tops', percent: 35, color: const Color(0xFF2d3561)),
                            _BreakdownRow(label: 'Bottoms', percent: 25, color: const Color(0xFF4a5490)),
                            _BreakdownRow(label: 'Accessories', percent: 20, color: const Color(0xFF8b93c9)),
                            _BreakdownRow(label: 'Outerwear', percent: 20, color: const Color(0xFFc5c9e4)),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Open Outfit Planner Button
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
                child: const Text(
                  'Open Outfit Planner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Private closet note
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 13, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Your closet is private',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1a1a2e))),
          ),
          Text('$percent%', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}