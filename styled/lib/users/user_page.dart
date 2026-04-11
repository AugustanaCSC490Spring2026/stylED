import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _email = '';
  String _displayName = '';
  int _totalItems = 0;
  int _daysActive = 0;
  int _totalOutfits = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final userId = UserHolder.id;
      final email = user.email ?? '';
      final namePart = email.split('@').first;
      final parts = namePart.split('.');
      String displayName = parts.isNotEmpty
          ? parts.map((p) => p[0].toUpperCase() + p.substring(1)).join(' ')
          : namePart;

      final createdAt = user.createdAt;
      final days = DateTime.now().difference(DateTime.parse(createdAt)).inDays;

      try {
        final response = await Supabase.instance.client
            .from('clothes')
            .select()
            .eq('profile_id', userId.toString());
        final outfitResponse = await Supabase.instance.client
            .from('outfits')
            .select()
            .eq('owner_id', userId.toString());
        setState(() {
          _totalItems = (response as List).length;
          _totalOutfits = (outfitResponse as List).length;
          _email = email;
          _displayName = displayName;
          _daysActive = days;
        });
      } catch (e) {
        // ignore
      }

     /* setState(() {
        _email = email;
        _displayName = displayName;
        _daysActive = days;
      }); */
    }
  }

  String _getInitials() {
    if (_displayName.isEmpty) return '?';
    final parts = _displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title
            Text(
              'Profile',
              style: GoogleFonts.rockSalt(
                fontStyle: FontStyle.italic,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            const Text(
              'Manage your account',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // User Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2d3561),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName.isEmpty ? 'Loading...' : _displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                          Text(
                            _email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Connected with Email',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _ProfileStatCard(
                    value: '$_totalItems',
                    label: 'Items',
                  ),
                ),
                const SizedBox(width: 10),
                 Expanded(
                  child: _ProfileStatCard(
                    value: '$_totalOutfits',
                    label: 'Outfits',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileStatCard(
                    value: '$_daysActive',
                    label: 'Days Active',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Privacy & Security Section
            const Text(
              'PRIVACY & SECURITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            _ProfileMenuItem(
              icon: Icons.lock_outline,
              title: 'Privacy Settings',
              subtitle: 'Manage your data',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.download_outlined,
              title: 'Export Data',
              subtitle: 'Download your closet',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // Private closet banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your closet is private',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          'All your data is encrypted and secure.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
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

class _ProfileStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2d3561), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
} 