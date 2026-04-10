import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/splash_screen.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: 'https://ksztxqxsylspvicdphzh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzenR4cXhzeWxzcHZpY2RwaHpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NTcyOTYsImV4cCI6MjA4ODEzMzI5Nn0.IWntG-60ZINeOY1BoZRhw1iJhCxWlKuUw2JOoaDqezc',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splashscreen',
      routes: {
         '/splashscreen': (context) => const SplashScreen (),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage (),
      },
    );
  }
}