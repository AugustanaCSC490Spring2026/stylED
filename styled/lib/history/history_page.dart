import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:styled/auth/login_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  int _totalItems = 0;
  int _wornItems = 0;
  List<Map<String, dynamic>> _mostWornItems = [];

  List<FlSpot> _addedPerMonth = [];
  List<String> _addedDateLabels = [];

  // summary data for clothes type
  Map<String, int> _categoryBreakdown = {};

  final List<String> _filters = ['All', 'Casual', 'Formal', 'Athletic'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final userId = UserHolder.id;
      try {
        final response = await Supabase.instance.client
            .from('clothes')
            .select()
            .eq('profile_id', userId.toString());

        final items = response as List;

        // for (var item in items) {
        //   print('Item: ${item['name']} | createdAt: ${item['createdAt'
        //   ]}');
        // }

        final worn = items.where((item) => item['dateLastWorn'] != null).toList();

        // Sort by times worn or just show items with names
        final wornWithCount = worn.take(4).map((item) {
          return {
            'name': item['name'] ?? 'Unknown',
            'count': (item['times_worn'] ?? 1) as int,
          };
        }).toList();

        // count of number of clothes type in each category
        final Map<String, int> breakdown = {};
        
        for (Map<String, dynamic> item in items) {
          String category;

          if (item['category'] != null && item['category'] is String) {
            category = item['category'];
          } else {
            category = 'Other';
          }

          if (breakdown.containsKey(category)) {
            breakdown[category] = breakdown[category]! + 1;
          } else {
            breakdown[category] = 1;
          }
        }

        // added by month
        final Map<String, int> addedByMonth = {};
        
        // loop through all items
        for (Map<String, dynamic> item in items) {
          final month = item['created_at']?.toString();
          if (month != null) {
            // get only the year and month
            final monthKey = month.substring(0, 7);

            if (addedByMonth.containsKey(monthKey)) {
              addedByMonth[monthKey] = addedByMonth[monthKey]! + 1;
            } else {
              addedByMonth[monthKey] = 1;
            }
            //addedByMonth[monthKey] = (addedByMonth[monthKey] ?? 0) + 1;
          }
        }

        // sorts the months in chronological order
        final sortedMonths = addedByMonth.keys.toList()..sort();

        final spots = sortedMonths.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), addedByMonth[e.value]!.toDouble());
        }).toList();

        setState(() {
          _totalItems = items.length;
          _wornItems = worn.length;
          _mostWornItems = wornWithCount;
          _categoryBreakdown = breakdown;
          _addedPerMonth = spots;
          _addedDateLabels = sortedMonths;
        });
      } catch (e) {
        // ignore
      }
    } 
  }

  int get _notWornPercent {
    if (_totalItems == 0) return 0;
    return ((_totalItems - _wornItems) / _totalItems * 100).round();
  }

  int get _wornPercent {
    if (_totalItems == 0) return 0;
    return ((_wornItems / _totalItems) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title
            Center(
              child: Text(
                'History',
                style: GoogleFonts.rockSalt(
                  fontStyle: FontStyle.italic,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ),
            Center(
              child: const Text(
                'Your outfit & wear history',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2d3561)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2d3561)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Most Worn Items - bar chart
            Row(
              children: [
                const Icon(Icons.trending_up,
                    color: Color(0xFF2d3561), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Most Worn Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _mostWornItems.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No wear history yet.\nStart adding items to your closet!',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _BarChart(items: _mostWornItems),
            ),

            const SizedBox(height: 20),

            // Closet Analytics
            const Text(
              'Closet Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              // if no categories have been loaded yet, then show place holder text, else show the chart
              child: _categoryBreakdown.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Add items to see your analytics!',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  : _CategoryPieChart(categoryData: _categoryBreakdown),
                ),

            const SizedBox(height: 16),

            const Text(
              'Items Added Over Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),                
              ),
            ),
            
            const SizedBox(height: 12),

            _LineChart(
              dataSpot: _addedPerMonth,
              dateLabels: _addedDateLabels,
            ),

            // Insight Card
            if (_totalItems > 0 && _notWornPercent > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF9F27)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Color(0xFF854F0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_notWornPercent% of your closet hasn\'t been worn in 60 days.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF633806),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _BarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty
        ? 1
        : items
            .map((e) => e['count'] as int)
            .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          final count = item['count'] as int;
          final height = (count / maxCount) * 80;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: height.clamp(10.0, 80.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d3561),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 50,
                child: Text(
                  item['name'] as String,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Pie chart of clothing categories
class _CategoryPieChart extends StatefulWidget {
  final Map<String, int> categoryData;

  const _CategoryPieChart({required this.categoryData});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
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
                    title: '$percent%',
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

// line chart

class _LineChart extends StatelessWidget{
  final List<FlSpot> dataSpot;
  final List<String> dateLabels;

  const _LineChart({
    required this.dataSpot,
    required this.dateLabels,
    });

  @override
  Widget build(BuildContext context) {
    if (dataSpot.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No clothes added yet. \nStart adding items to your closet!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
    return SizedBox(
      height: 200,
      child: Center(
        child: Text('Hello'),
      ),
    );
  }
}