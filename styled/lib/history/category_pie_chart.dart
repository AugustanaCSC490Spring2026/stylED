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

  String display_mode = 'Number';

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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: display_mode,
                  underline: Container(),
                  items: ['Number', 'Percentage']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      display_mode = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // pie chart
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
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
                          String title;
                          if (display_mode == 'Number') {
                            title = '${entry.value}';
                          } else {
                            title = '$percent%';
                          }

                          return PieChartSectionData(
                            color: _colors[i % _colors.length],
                            value: entry.value.toDouble(),
                            title: title,
                            // tapped slices grow bigger
                            radius: isTouched ? 60.0 : 50.0,
                            titleStyle: TextStyle(
                              fontSize: isTouched ? 16.0 : 12.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 2),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // pie chart legend
                  Expanded(
                    flex: 0,
                    child: Column(
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
                              const SizedBox(width: 10),
                              // category name
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a1a2e),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

DropdownMenuItem<String> buildMenuItem(String item) => DropdownMenuItem(
  value: item,
  child: Text(
    item,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
  ),
);
