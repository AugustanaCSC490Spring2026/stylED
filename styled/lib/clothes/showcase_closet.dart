import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ShowcaseCloset extends StatefulWidget {
  const ShowcaseCloset({super.key});

  @override
  State<ShowcaseCloset> createState() => _ShowcaseClosetState();
}

class _ShowcaseClosetState extends State<ShowcaseCloset> {
  late final CarouselController allItemsController;
  late final CarouselController tiesController;
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> tieCollection = [];
  bool isLoading = true; //controls what the screen show, once data arrive variable is set to false
  int showcaseTab = 0; //set at 0 which is all item, 1 means just ties

  @override
  void initState() {
    super.initState();
    allItemsController = CarouselController(initialItem: 2);
    tiesController = CarouselController(initialItem: 0);
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

      tieCollection = allItems.where((item) => item['is_tie'] == true) .toList(); //items that have their isTie condition marked as true are added
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
      : Column(
        children: [
          const SizedBox(height: 16),

          //switch tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(14), //radius:14

              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showcaseTab = 0), //all items should be the primary thing that's showcased
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: showcaseTab == 0
                          ? const Color(0xFF2d3561)
                          : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),

                        ),
                        child: Text(
                          'All Items',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rockSalt(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: showcaseTab == 0
                            ? Colors.white
                            : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showcaseTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical:  10),
                        decoration: BoxDecoration(
                          color: showcaseTab == 1
                          ? const Color(0xFF2d3561)
                          : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Ties',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rockSalt(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: showcaseTab == 1
                            ? Colors.white
                            : Colors.grey,
                          ),
                        ),
                      ),
                      
                    ),
                  ),
                ],
                ),
            ),
          ),


          const SizedBox(height: 16),

          //CarouselView for allItems
          if (showcaseTab == 0)
          allItems.isEmpty
            ? const Expanded(
              child: Center(
              child: Text('No items have been added yet',
                style: TextStyle(color: Colors.grey)),
            ),
          )

          : Expanded(
            child: CarouselView(
              controller: allItemsController,
              itemExtent: MediaQuery.of(context).size.width * 0.85, //item cards occupy 85% of screen
              shrinkExtent: MediaQuery.of(context).size.width * 0.5, //item cards shrink around to half of their original width as they slide away
              itemSnapping: true,
              children: allItems.map((item) => _carouselCard(item)).toList(),
            ),
          ),

          //Carousel View just for Ties
          if (showcaseTab == 1)
          tieCollection.isEmpty
            ? const Expanded(
              child: Center(
                child: Text('No ties have been added yet',
                style: TextStyle(color: Colors.grey)),
            ),
            )
          

          : Expanded(
            child:CarouselView(
              controller: tiesController,
              itemExtent: MediaQuery.of(context).size.width * 0.85, //item cards occupy 85% of screen
              shrinkExtent: MediaQuery.of(context).size.width * 0.5, //item cards shrink around to half of their original width as they slide away
              itemSnapping: true,
              children: tieCollection.map((item) => _carouselCard(item)).toList(),
                  ),
                ),
            ],
          ),
    );
  }

        Widget _carouselCard(Map<String,dynamic> item) {

          return ClipRRect( //wrap images to create a rounded rectangle shape
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
      ),
   ); 
  }

  Widget _tag(String label){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20)
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF1a1a2e)),
      ),
    );
  }



}