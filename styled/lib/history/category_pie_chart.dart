import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

// Pie chart of clothing categories
class CategoryPieChart extends StatefulWidget {
  final Map<String, int> categoryData;
  
  const CategoryPieChart({required this.categoryData});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  static const List<Color> _colors = [
    Color(0xFF2d3561),
    Color(0xFFEF9F27),
    Color(0xFF9C27B0),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
  ];

  @override 
  Widget build(BuildContext context) {
    // convert map -> list
    final categories = widget.categoryData.entries.toList();

    // total items overall
    final total = categories.fold(0, (sum, e) => sum + e.value);

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          // pie chart
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || 
                      pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: categories.asMap().entries.map((e) {
                  final i = e.key;
                  final entry = e.value;
                  final isTouched = i == touchedIndex;
                  final percent = (entry.value / total * 100).round();

                  return PieChartSectionData(
                    color: _colors[i % _colors.length],
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    // tapped slices grow bigger
                    radius: isTouched ? 60.0 : 50.0,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 16.0 : 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // pie chart legend
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.asMap().entries.map((e) {
              final i = e.key;
              final entry = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width:8),
                    // category name
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1a1a2e),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}