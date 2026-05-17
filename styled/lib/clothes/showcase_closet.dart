import 'package:flutter/material.dart';

class ShowcaseCloset extends StatefulWidget {
  const ShowcaseCloset({super.key});

  @override
  State<ShowcaseCloset> createState() => _ShowcaseClosetState();
}

class _ShowcaseClosetState extends State<ShowcaseCloset> {
  late final CarouselController controller;

  @override
  void initState() {
    super.initState();
    controller = CarouselController(initialItem: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d3561),
        foregroundColor: Colors.white,
        title: const Text('Item Showcase'),
        centerTitle: true,
        elevation: 0,
      ),
      body: CarouselView(
        controller: controller,
        itemExtent: 200.0,
        children: List.generate(
          5,
          (index) => Container(
            color: const Color(0xFFEEF0FF),
            child: Center(
              child: Text('Item $index'),
            ),
          ),
        ),
      ),
    );
  }
}