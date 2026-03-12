import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../clothes/digital_closet.dart';

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
    const Center(child: Text('Planner - Coming Soon')),
    const Center(child: Text('History - Coming Soon')),
    const Center(child: Text('Profile - Coming Soon')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to StylED!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are now logged in.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => signOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2d3561),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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