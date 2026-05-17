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
        itemExtent: MediaQuery.of(context).size.width * 0.85, //item cards occupy 85% of screen
        shrinkExtent: MediaQuery.of(context).size.width * 0.5, //item cards shrink around to half of their original width as they slide away
        itemSnapping: true,
        children: allItems.map((item) =>
        ClipRRect( //wrap images to create a rounded rectangle shape
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,//layer 1: image, stretcher to fit the entire item card from edge to edge
            children: [

            item['image_url'] != null
          ? Image.network(item['image_url'], fit: BoxFit.cover, //image is able to properly fill out an entire item card
          width: double.infinity, height: double.infinity)
          : Container(
            color: const Color(0xFFEEF0FF),
          
            child :Center(child: Text(item['name'] ?? 'Item')),

          ),
        Positioned( //tags are pinned at the bottom left of an image as they were meant to occupy the whole card
        //this is basically layer 2, which is why it's sitting on top of layer 1: the image
          bottom: 12,
          left: 12,
          child: Row(
            children: [
              if(item['occasion'] != null) _tag(item['occasion']),
              const SizedBox(width: 6),
              if (item['season'] != null) _tag(item['season']),
            ],
          ),
        ),

            ],
          )
            


          
        ),
        ).toList(),
      
          ),
        
      );
    
  }

  Widget _tag(String label){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FF2F5),
        borderRadius: BorderRadius.circular(20)
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF1a1a2e)),
      ),
    );
  }



}