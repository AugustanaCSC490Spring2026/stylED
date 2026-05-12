import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:styled/auth/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:styled/history/category_pie_chart.dart';

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
      final userId = user.id;
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

        // fetch outfits to calculate most worn items
        final outfitResponse = await Supabase.instance.client
            .from('outfits')
            .select()
            .eq('profile_id', userId.toString());

        final Map<String, int> itemCount = {};
        for (final outfit in outfitResponse as List) {
          for (final key in ['top_id', 'bottom_id', 'shoes_id', 'accessory_id']) {
            final id = outfit[key]?.toString();
            if (id != null) itemCount[id] = (itemCount[id] ?? 0) + 1;
          }
        }

        final sortedIds = itemCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final wornWithCount = sortedIds.take(5).map((entry) {
          final item = items.firstWhere(
            (i) => i['itemId'].toString() == entry.key,
            orElse: () => {'name': 'Unknown', 'image_url': null},
          );
          return {
            'name': item['name'] ?? 'Unknown',
            'image_url': item['image_url'],
            'count': entry.value,
          };
        }).toList();

        final worn = wornWithCount;


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
          _wornItems = wornWithCount.length;
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

            const Text(
              'Items Added Over Time',
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
              child: _LineChart(
              dataSpot: _addedPerMonth,
              dateLabels: _addedDateLabels,
            ),
          ),
            

            // Insight Card
            if (_totalItems > 0 && _notWornPercent > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
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
        : items.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          final count = item['count'] as int;
          final height = (count / maxCount) * 80;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('$count', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              if (item['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['image_url'], width: 44, height: 44, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checkroom, color: Color(0xFF2d3561), size: 20),
                ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: height.clamp(10.0, 80.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d3561),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 52,
                child: Text(
                  item['name'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),

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
          padding: EdgeInsets.symmetric(vertical: 24),
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          // x-axis: months
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dateLabels.length) {
                  return const SizedBox();
                }
                // convert numerical dates to Month names
                final parts = dateLabels[index].split('-');
                final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                final label = months[int.parse(parts[1])];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ); 
              },
            ),
          ),
          // y-axis: counts
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          // hide top and right labels
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false)
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false)
          ),
        ),
        lineBarsData: [
            LineChartBarData(
              spots: dataSpot,
              isCurved: true,
              color: const Color(0xFF2d3561),
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF2d3561).withOpacity(0.1),
              )
            )
          ]
      ),
      ),
    );
  }
}