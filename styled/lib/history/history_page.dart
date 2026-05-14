import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
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
  Map<String, int> _categoryBreakdown = {};
  final List<String> _filters = ['All', 'Casual', 'Formal', 'Athletic'];

  // Calendar state
  bool _calendarOpen = false;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  // outfit worn per date: key = 'yyyy-MM-dd', value = outfit map
  Map<String, Map<String, dynamic>> _outfitsByDate = {};

  // planned outfits: key = 'yyyy-MM-dd', value = outfit map
  Map<String, Map<String, dynamic>> _plannedOutfits = {};

  // all saved outfits for planning
  List<Map<String, dynamic>> _savedOutfits = [];

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
            .eq('profile_id', userId);
        final items = response as List;

        final outfitResponse = await Supabase.instance.client
            .from('outfits')
            .select()
            .eq('profile_id', userId);

        // build outfits by date map
        final Map<String, Map<String, dynamic>> outfitsByDate = {};
        for (final outfit in outfitResponse as List) {
          final createdAt = outfit['created_at']?.toString();
          if (createdAt != null) {
            final dateKey = createdAt.substring(0, 10);
            outfitsByDate[dateKey] = Map<String, dynamic>.from(outfit);
          }
        }

        final Map<String, int> itemCount = {};
        for (final outfit in outfitResponse) {
          for (final key in [
            'top_id',
            'bottom_id',
            'shoes_id',
            'accessory_id',
          ]) {
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

        final Map<String, int> breakdown = {};
        for (Map<String, dynamic> item in items) {
          final category = (item['category'] is String)
              ? item['category']
              : 'Other';
          breakdown[category] = (breakdown[category] ?? 0) + 1;
        }

        // fetch planned outfits from a planned_outfits table if it exists
        // for now we keep planned outfits in memory
        setState(() {
          _totalItems = items.length;
          _wornItems = wornWithCount.length;
          _mostWornItems = wornWithCount;
          _categoryBreakdown = breakdown;
          _outfitsByDate = outfitsByDate;
          _savedOutfits = List<Map<String, dynamic>>.from(outfitResponse);
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

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _onDayTapped(DateTime day) {
    final tappedDay = DateTime(day.year, day.month, day.day);
    final key = _dateKey(tappedDay);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = tappedDay.isBefore(today);
    final isToday = tappedDay == today;

    setState(() => _selectedDay = tappedDay);

    if (isPast || isToday) {
      final outfit = _outfitsByDate[key];
      _showDayBottomSheet(tappedDay, outfit, isPast: true);
    } else {
      final planned = _plannedOutfits[key];
      _showDayBottomSheet(tappedDay, planned, isPast: false);
    }
  }

  void _showDayBottomSheet(
    DateTime day,
    Map<String, dynamic>? outfit, {
    required bool isPast,
  }) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dateLabel = '${months[day.month - 1]} ${day.day}, ${day.year}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPast
                              ? const Color(0xFFF0F2F5)
                              : const Color(0xFFEEF0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPast ? 'Worn' : 'Planned',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPast
                                ? Colors.grey
                                : const Color(0xFF2d3561),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (outfit != null) ...[
                    // show outfit name
                    Text(
                      outfit['name'] ?? 'Outfit',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Items in this outfit:',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (outfit['top_id'] != null)
                          _outfitChip('Top', outfit['top_id'].toString()),
                        if (outfit['bottom_id'] != null)
                          _outfitChip('Bottom', outfit['bottom_id'].toString()),
                        if (outfit['shoes_id'] != null)
                          _outfitChip('Shoes', outfit['shoes_id'].toString()),
                        if (outfit['accessory_id'] != null)
                          _outfitChip(
                            'Accessory',
                            outfit['accessory_id'].toString(),
                          ),
                      ],
                    ),
                    if (!isPast) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showPlanPicker(day);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2d3561)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Change Outfit',
                            style: TextStyle(color: Color(0xFF2d3561)),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    if (isPast)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No outfit recorded for this day.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      )
                    else ...[
                      const Text(
                        'No outfit planned yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showPlanPicker(day);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2d3561),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Plan an Outfit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => _selectedDay = null);
    });
  }

  void _showPlanPicker(DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pick a saved outfit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _savedOutfits.isEmpty
                      ? const Center(
                          child: Text(
                            'No saved outfits yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _savedOutfits.length,
                            itemBuilder: (context, index) {
                              final outfit = _savedOutfits[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _plannedOutfits[_dateKey(day)] =
                                        Map<String, dynamic>.from(outfit);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${outfit['name'] ?? 'Outfit'} planned!',
                                      ),
                                      backgroundColor: const Color(0xFF2d3561),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF0FF),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.checkroom,
                                          color: Color(0xFF2d3561),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        outfit['name'] ?? 'Unnamed Outfit',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF1a1a2e),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _outfitChip(String label, String itemId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF1a1a2e)),
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                }),
                child: const Icon(Icons.chevron_left, color: Color(0xFF2d3561)),
              ),
              Text(
                '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1a1a2e),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                }),
                child: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF2d3561),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();

              final day = index - startWeekday + 1;
              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                day,
              );
              final dateKey = _dateKey(date);

              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isSelected =
                  _selectedDay != null &&
                  date.year == _selectedDay!.year &&
                  date.month == _selectedDay!.month &&
                  date.day == _selectedDay!.day;
              final hasWorn = _outfitsByDate.containsKey(dateKey);
              final hasPlanned = _plannedOutfits.containsKey(dateKey);

              return GestureDetector(
                onTap: () => _onDayTapped(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2d3561)
                        : isToday
                        ? const Color(0xFFEEF0FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1a1a2e),
                        ),
                      ),
                      if (hasWorn || hasPlanned)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : hasWorn
                                ? const Color(0xFF2d3561)
                                : const Color(0xFFEF9F27),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Legend
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2d3561),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Worn',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF9F27),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Planned',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row + calendar icon ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'History',
                  style: GoogleFonts.rockSalt(
                    fontStyle: FontStyle.italic,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a2e),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _calendarOpen = !_calendarOpen),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _calendarOpen
                          ? const Color(0xFF2d3561)
                          : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: _calendarOpen
                          ? Colors.white
                          : const Color(0xFF1a1a2e),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const Center(
              child: Text(
                'Your outfit & wear history',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),

            // ── Calendar (collapsible) ────────────────────────────────
            if (_calendarOpen) _buildCalendar(),

            // ── Filter Tabs ───────────────────────────────────────────
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
                        horizontal: 16,
                        vertical: 8,
                      ),
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

            // ── Most Worn Items ───────────────────────────────────────
            Row(
              children: const [
                Icon(Icons.trending_up, color: Color(0xFF2d3561), size: 18),
                SizedBox(width: 8),
                Text(
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

            // ── Insight Card ──────────────────────────────────────────
            if (_totalItems > 0 && _notWornPercent > 0) ...[
              const SizedBox(height: 20),
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
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF854F0B),
                      size: 18,
                    ),
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
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

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
              Text(
                '$count',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              if (item['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image_url'],
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.checkroom,
                    color: Color(0xFF2d3561),
                    size: 20,
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: height.clamp(10.0, 80.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF2d3561),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
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