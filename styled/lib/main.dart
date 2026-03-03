import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize (
    url: 'https://ksztxqxsylspvicdphzh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzenR4cXhzeWxzcHZpY2RwaHpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NTcyOTYsImV4cCI6MjA4ODEzMzI5Nn0.IWntG-60ZINeOY1BoZRhw1iJhCxWlKuUw2JOoaDqezc',
  );
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
