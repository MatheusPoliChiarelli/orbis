import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime month;
  final int selectedDay;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;

    return SizedBox(
      height: 62,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: daysInMonth,
          separatorBuilder: (_, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final day = index + 1;
            final date = DateTime(month.year, month.month, day);
            final isPast = isCurrentMonth && day < today.day;
            final isToday = isCurrentMonth && day == today.day;

            return _DayCell(
              day: day,
              weekday: weekdayShort[date.weekday - 1],
              selected: day == selectedDay,
              past: isPast,
              today: isToday,
              onTap: () => onSelect(day),
            );
          },
        ),
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.day,
    required this.weekday,
    required this.selected,
    required this.past,
    required this.today,
    required this.onTap,
  });

  final int day;
  final String weekday;
  final bool selected;
  final bool past;
  final bool today;
  final VoidCallback onTap;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    final background = selected
        ? AppColors.accentSoft
        : (_hover
            ? AppColors.surfaceRaised
            : (widget.past ? AppColors.surface : Colors.transparent));

    final numberColor = selected
        ? AppColors.accent
        : (widget.past ? AppColors.textSecondary : AppColors.textMuted);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 52,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: selected
                  ? AppColors.borderAccent
                  : (widget.past ? AppColors.border : Colors.transparent),
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.weekday,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${widget.day}',
                style: AppText.money(
                  size: 15,
                  color: numberColor,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.today ? AppColors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}