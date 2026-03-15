import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final List<String> _filters = ['All', 'Casual', 'Formal', 'Athletic'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('clothes')
            .select()
            .eq('user_id', user.id);

        final items = response as List;
        final worn = items.where((item) => item['date_last_worn'] != null).toList();

        // Sort by times worn or just show items with names
        final wornWithCount = worn.take(4).map((item) {
          return {
            'name': item['name'] ?? 'Unknown',
            'count': (item['times_worn'] ?? 1) as int,
          };
        }).toList();

        setState(() {
          _totalItems = items.length;
          _wornItems = worn.length;
          _mostWornItems = wornWithCount;
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
            const Text(
              'History',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            const Text(
              'Your outfit & wear history',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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

            // Most Worn Items
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
              child: _totalItems == 0
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Add items to see your analytics!',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Donut chart
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CustomPaint(
                            painter: _DonutChartPainter(
                              wornPercent: _wornPercent / 100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2d3561),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Worn  $_wornPercent%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1a1a2e),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Not Worn  $_notWornPercent%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1a1a2e),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

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

class _DonutChartPainter extends CustomPainter {
  final double wornPercent;

  _DonutChartPainter({required this.wornPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = const Color(0xFF2d3561)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    const startAngle = -1.5708;
    final sweepAngle = 2 * 3.14159 * wornPercent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 