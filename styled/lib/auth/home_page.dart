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

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeContent(onNavigate: _navigateTo),
      const DigitalCloset(),
      const OutfitGeneratorPage(),
      const HistoryPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: pages[_currentIndex],
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
            BottomNavigationBarItem(
                icon: Icon(Icons.checkroom), label: 'Closet'),
            BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome), label: 'Planner'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final void Function(int index) onNavigate;

  const _HomeContent({required this.onNavigate});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _userName = '';
  int _totalItems = 0;
  int _totalOutfits = 0;
  Map<String, dynamic>? _mostWornItem;
  Map<String, int> _categoryBreakdown = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final userId = user.id;

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      final userName = profileResponse?['name'] ?? 'there';

      if (!mounted) return;
      setState(() {
        _userName = userName;
      });

      try {
        final clothesResponse = await Supabase.instance.client
            .from('clothes')
            .select()
            .eq('profile_id', userId);

        final outfitResponse = await Supabase.instance.client
            .from('outfits')
            .select()
            .eq('profile_id', userId)
            .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
            );

        // count wear frequency
        final Map<String, int> itemCount = {};
        for (final outfit in outfitResponse as List) {
          for (final key in [
            'top_id',
            'bottom_id',
            'shoes_id',
            'accessory_id'
          ]) {
            final id = outfit[key]?.toString();
            if (id != null) itemCount[id] = (itemCount[id] ?? 0) + 1;
          }
        }

        Map<String, dynamic>? mostWorn;
        if (itemCount.isNotEmpty) {
          final topId = itemCount.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          final clothes =
              List<Map<String, dynamic>>.from(clothesResponse as List);
          mostWorn = clothes.firstWhere(
            (item) => item['itemId'].toString() == topId,
            orElse: () => {},
          );
          if (mostWorn!.isEmpty) mostWorn = null;
        }

        // real category breakdown
        final Map<String, int> breakdown = {};
        for (final item in clothesResponse as List) {
          final category =
              (item['category'] is String) ? item['category'] : 'Other';
          breakdown[category] = (breakdown[category] ?? 0) + 1;
        }

        if (!mounted) return;
        setState(() {
          _totalItems = (clothesResponse as List).length;
          _totalOutfits = (outfitResponse as List).length;
          _mostWornItem = mostWorn;
          _categoryBreakdown = breakdown;
        });
      } catch (e) {
        // ignore
      }
    }
     
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getShortName() {
    if (_userName.isEmpty) return 'there';
    final parts = _userName.split('.');
    if (parts.isNotEmpty) {
      final first = parts[0];
      if (first.isEmpty) return 'there';
      return first[0].toUpperCase() + first.substring(1);
    }
    return _userName.length > 10 ? _userName.substring(0, 10) : _userName;
  }

  // color palette for breakdown bars
  final List<Color> _breakdownColors = [
    const Color(0xFF2d3561),
    const Color(0xFF4a5490),
    const Color(0xFF8b93c9),
    const Color(0xFFc5c9e4),
    const Color(0xFFEF9F27),
    const Color(0xFF4CAF50),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    final isNewUser = _totalItems == 0 && _categoryBreakdown.isEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Greeting ──────────────────────────────────────────────
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1a1a2e),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedDate(),
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Get Started Banner (only for new users) ───────────────
            if (isNewUser) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2d3561), Color(0xFF4a5490)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👗 Welcome to StylED!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start by adding your first clothing item to your closet. Then you can plan outfits and track what you wear.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => widget.onNavigate(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '+ Add your first item',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3561),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Quick Actions ─────────────────────────────────────────
            if (!isNewUser) ...[
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.checkroom,
                      label: 'My Closet',
                      subtitle: '$_totalItems items',
                      onTap: () => widget.onNavigate(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.auto_awesome,
                      label: 'Plan Outfit',
                      subtitle: 'AI powered',
                      onTap: () => widget.onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.history,
                      label: 'History',
                      subtitle: '$_totalOutfits this month',
                      onTap: () => widget.onNavigate(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Stats Row ─────────────────────────────────────────────
            if (!isNewUser) ...[
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
            ],

            // ── Most Worn Item ────────────────────────────────────────
            if (!isNewUser) ...[
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
                    const Icon(Icons.trending_up,
                        color: Color(0xFF2d3561), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Most Worn Item',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          _mostWornItem == null
                              ? const Text(
                                  'Start planning outfits to see this!',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1a1a2e)),
                                )
                              : Row(
                                  children: [
                                    if (_mostWornItem!['image_url'] != null)
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1a1a2e)),
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
            ],

            // ── Closet Breakdown (real data) ──────────────────────────
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
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          children: _categoryBreakdown.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((e) {
                            final index = e.key;
                            final entry = e.value;
                            final percent =
                                (_totalItems > 0)
                                    ? (entry.value / _totalItems * 100)
                                        .round()
                                    : 0;
                            return _BreakdownRow(
                              label: entry.key,
                              percent: percent,
                              color: _breakdownColors[
                                  index % _breakdownColors.length],
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Open Outfit Planner Button 
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => widget.onNavigate(2),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  'Open Outfit Planner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2d3561),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

// ── Quick Action Card ─────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF2d3561), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

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

// ── Breakdown Row ─────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF1a1a2e))),
              ),
              Text('$percent%',
                  style:
                      const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}