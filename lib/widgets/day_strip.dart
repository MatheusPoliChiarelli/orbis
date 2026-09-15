import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

const _gap = 5.0;
const _cellHeight = 52.0;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - _gap * (daysInMonth - 1)) / daysInMonth;

        return SizedBox(
          height: _cellHeight,
          child: Row(
            children: [
              for (var day = 1; day <= daysInMonth; day++)
                Padding(
                  padding: EdgeInsets.only(right: day == daysInMonth ? 0 : _gap),
                  child: _DayCell(
                    day: day,
                    width: width,
                    weekday: weekdayShort[
                        DateTime(month.year, month.month, day).weekday - 1],
                    selected: day == selectedDay,
                    past: isCurrentMonth && day < today.day,
                    today: isCurrentMonth && day == today.day,
                    onTap: () => onSelect(day),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.day,
    required this.width,
    required this.weekday,
    required this.selected,
    required this.past,
    required this.today,
    required this.onTap,
  });

  final int day;
  final double width;
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
          width: widget.width,
          height: _cellHeight,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: selected
                  ? AppColors.borderAccent
                  : (widget.today
                      ? AppColors.accent
                      : (widget.past
                          ? AppColors.border
                          : Colors.transparent)),
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.weekday,
                style: TextStyle(
                  fontSize: 9.5,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.day}',
                style: AppText.money(
                  size: 14,
                  color: numberColor,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}