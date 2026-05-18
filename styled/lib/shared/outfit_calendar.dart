import 'package:flutter/material.dart';

class OutfitCalendar extends StatefulWidget {
  final Map<String, Map<String, dynamic>> outfitsByDate;
  final Map<String, Map<String, dynamic>> plannedOutfits;
  final void Function(DateTime)? onDayTapped;
  final bool futureDatePickerMode;

  const OutfitCalendar({
    super.key,
    this.outfitsByDate = const {},
    this.plannedOutfits = const {},
    this.onDayTapped,
    this.futureDatePickerMode = false,
  });

  @override
  State<OutfitCalendar> createState() => _OutfitCalendarState();
}

class _OutfitCalendarState extends State<OutfitCalendar> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Container(
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
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                }),
                child: const Icon(Icons.chevron_left, color: Color(0xFF2d3561)),
              ),
              Text(
                '${_months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1a1a2e),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                }),
                child: const Icon(Icons.chevron_right, color: Color(0xFF2d3561)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S','M','T','W','T','F','S'].map((d) =>
              SizedBox(
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
            ).toList(),
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
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final dateKey = _dateKey(date);
              final isPast = date.isBefore(today);
              final isToday = date == today;
              final isSelected = _selectedDay != null &&
                  date.year == _selectedDay!.year &&
                  date.month == _selectedDay!.month &&
                  date.day == _selectedDay!.day;
              final hasWorn = widget.outfitsByDate.containsKey(dateKey);
              final hasPlanned = widget.plannedOutfits.containsKey(dateKey);
              final isDisabled = widget.futureDatePickerMode && isPast;

              return GestureDetector(
                onTap: isDisabled ? null : () {
                  setState(() => _selectedDay = date);
                  widget.onDayTapped?.call(date);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.futureDatePickerMode
                            ? const Color(0xFFEF9F27)
                            : const Color(0xFF2d3561)
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
                              : isDisabled
                              ? Colors.grey.shade300
                              : const Color(0xFF1a1a2e),
                        ),
                      ),
                      if (!widget.futureDatePickerMode && (hasWorn || hasPlanned))
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

          // Legend — only in normal mode
          if (!widget.futureDatePickerMode) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2d3561), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Worn', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 16),
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF9F27), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Planned', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}