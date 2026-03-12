import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
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
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: SafeArea(
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
      ),


//Modern Buttons to Navigate App
      bottomNavigationBar: Container( //wrapped in a container
       color: Colors.black,
        child: Padding( //Wrapped in Padding
        padding: const EdgeInsets.all(8),
        child: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.white,
        
        onTap: (index){ //Navigating across the different tabs
          print(index);
        },
        type: BottomNavigationBarType.fixed, //Needed for background color to be applied to whole bottom bar and for all items being visibile 
        items: const [ 
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home',),
         BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Closet',),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Planner',),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Fit History',),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile',),
        ],
      ),
      )
      )
      );
  }
}