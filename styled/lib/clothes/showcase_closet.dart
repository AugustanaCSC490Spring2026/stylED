import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ShowcaseCloset extends StatefulWidget {
  const ShowcaseCloset({super.key});

  @override
  State<ShowcaseCloset> createState() => _ShowcaseClosetState();
}

class _ShowcaseClosetState extends State<ShowcaseCloset> {
  late final CarouselController controller;
  List<Map<String,dynamic>> allItems = []; //
  bool isLoading = true; //controls what the screen show, once data arrive variable is set to false

  @override
  void initState() {
    super.initState();
    controller = CarouselController(initialItem: 2);
    fetchItems();
  }

  Future<void> fetchItems() async{
    setState(() => isLoading = true);
    try{
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
      allItems = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    }); 

    }catch(e) {
      debugPrint('Error $e');
      setState(() => isLoading = false);
    }
      
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d3561), 
        foregroundColor: Colors.white,
        title: Text(
          'My Closet',
          style: GoogleFonts.rockSalt(
            color: Colors.white,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,                
            fontSize: 16,
            
          )),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
      ? const Center(child: CircularProgressIndicator())
      :CarouselView(
        controller: controller,
        itemExtent: 200.0,
        children: allItems.map((item) =>
        Container(
          color: const Color(0xFFEEF0FF),
          child: item['image_url'] != null
          ? Image.network(item['image_url'], fit: BoxFit.cover)
          :Center(child: Text(item['name'] ?? 'Item')),
        ),
        ).toList(),
      
          ),
        
      );
    
  }
}