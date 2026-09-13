import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/habit_dialog.dart';

const _nameColumnWidth = 230.0;
const _cellSize = 26.0;
const _cellGap = 3.0;
const _rowHeight = 34.0;

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  final _gridController = ScrollController();

  String get _monthKey => monthKey(_month);

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _confirmDelete(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text(
          'Excluir hábito',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
        content: Text(
          'Excluir ${habit.name}? As marcações continuam gravadas, mas deixam de aparecer',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HabitService.deleteHabit(habit.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Habit>>(
      stream: HabitService.watchHabits(),
      builder: (context, habitSnap) {
        return StreamBuilder<HabitLog>(
          stream: HabitService.watchLog(_monthKey),
          builder: (context, logSnap) {
            final habits =
                (habitSnap.data ?? const <Habit>[]).where((h) => h.active).toList();
            final log = logSnap.data ?? HabitLog.empty(_monthKey);

            final groups = habits
                .map((h) => h.group)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Row(
                    children: [
                      _Arrow(
                        icon: Icons.chevron_left,
                        onTap: () => _changeMonth(-1),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 210,
                        child: Text(
                          '${monthLabel(_month)} ${_month.year}',
                          textAlign: TextAlign.center,
                          style: AppText.serif(size: 26),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _Arrow(
                        icon: Icons.chevron_right,
                        onTap: () => _changeMonth(1),
                      ),
                      const Spacer(),
                      _AddButton(
                        label: 'Novo hábito',
                        onTap: () => showHabitDialog(
                          context: context,
                          groups: groups,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      child: AppCard(
                        title: 'Grade do mês',
                        subtitle:
                            '${habits.length} hábitos acompanhados em ${monthLabel(_month).toLowerCase()}',
                        child: habits.isEmpty
                            ? const EmptyHint(
                                message: 'Nenhum hábito cadastrado ainda',
                              )
                            : _Grid(
                                habits: habits,
                                groups: groups,
                                log: log,
                                month: _month,
                                daysInMonth: _daysInMonth,
                                monthKey: _monthKey,
                                controller: _gridController,
                                onEdit: (habit) => showHabitDialog(
                                  context: context,
                                  existing: habit,
                                  groups: groups,
                                ),
                                onDelete: _confirmDelete,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.habits,
    required this.groups,
    required this.log,
    required this.month,
    required this.daysInMonth,
    required this.monthKey,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Habit> habits;
  final List<String> groups;
  final HabitLog log;
  final DateTime month;
  final int daysInMonth;
  final String monthKey;
  final ScrollController controller;
  final ValueChanged<Habit> onEdit;
  final ValueChanged<Habit> onDelete;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;
    final cutoff = isCurrentMonth ? today.day : daysInMonth;

    final ordered = <Habit>[];
    final headers = <int, String>{};

    for (final group in groups) {
      final inGroup = habits.where((h) => h.group == group).toList();
      if (inGroup.isEmpty) continue;
      headers[ordered.length] = group;
      ordered.addAll(inGroup);
    }
    final ungrouped = habits.where((h) => h.group == null).toList();
    if (ungrouped.isNotEmpty) {
      if (groups.isNotEmpty) headers[ordered.length] = 'Outros';
      ordered.addAll(ungrouped);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _nameColumnWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              for (var i = 0; i < ordered.length; i++) ...[
                if (headers.containsKey(i)) _GroupHeader(label: headers[i]!),
                _NameCell(
                  habit: ordered[i],
                  onEdit: () => onEdit(ordered[i]),
                  onDelete: () => onDelete(ordered[i]),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        for (var day = 1; day <= daysInMonth; day++)
                          SizedBox(
                            width: _cellSize + _cellGap,
                            child: Center(
                              child: Text(
                                '$day',
                                style: AppText.money(
                                  size: 9.5,
                                  color: isCurrentMonth && day == today.day
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                  weight: isCurrentMonth && day == today.day
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        const SizedBox(
                          width: 96,
                          child: Center(
                            child: Text(
                              'MÊS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < ordered.length; i++) ...[
                    if (headers.containsKey(i))
                      const SizedBox(height: _groupHeaderHeight),
                    _HabitRow(
                      habit: ordered[i],
                      log: log,
                      monthKey: monthKey,
                      daysInMonth: daysInMonth,
                      cutoff: cutoff,
                      today: isCurrentMonth ? today.day : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _groupHeaderHeight = 30.0;

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _groupHeaderHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _NameCell extends StatefulWidget {
  const _NameCell({
    required this.habit,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_NameCell> createState() => _NameCellState();
}

class _NameCellState extends State<_NameCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _hover
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (habit.frequency != HabitFrequency.daily) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    habit.frequency == HabitFrequency.weekly ? 'sem' : 'mês',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: 28,
                child: _hover
                    ? IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                        splashRadius: 15,
                        padding: EdgeInsets.zero,
                        tooltip: 'Excluir',
                      )
                    : null,
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.log,
    required this.monthKey,
    required this.daysInMonth,
    required this.cutoff,
    required this.today,
  });

  final Habit habit;
  final HabitLog log;
  final String monthKey;
  final int daysInMonth;
  final int cutoff;
  final int? today;

  @override
  Widget build(BuildContext context) {
    final done = log.doneCount(habit.id, daysInMonth);
    final streak = log.streak(habit.id, cutoff);

    final expected = switch (habit.frequency) {
      HabitFrequency.daily => daysInMonth,
      HabitFrequency.weekly => (daysInMonth / 7).ceil(),
      HabitFrequency.monthly => 1,
    };
    final share = expected == 0 ? 0.0 : (done / expected).clamp(0.0, 1.0);

    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          for (var day = 1; day <= daysInMonth; day++)
            Padding(
              padding: const EdgeInsets.only(right: _cellGap),
              child: _Cell(
                done: log.isDone(habit.id, day),
                isToday: day == today,
                onTap: () => HabitService.toggleMark(
                  monthKey: monthKey,
                  habitId: habit.id,
                  day: day,
                  done: !log.isDone(habit.id, day),
                ),
              ),
            ),
          const SizedBox(width: 16),
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$done',
                  style: AppText.money(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '/$expected',
                  style: AppText.money(size: 10.5, color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${(share * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: AppText.money(
                      size: 10.5,
                      color: share >= 1
                          ? AppColors.income
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                if (streak > 1) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$streak',
                    style: AppText.money(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatefulWidget {
  const _Cell({
    required this.done,
    required this.isToday,
    required this.onTap,
  });

  final bool done;
  final bool isToday;
  final VoidCallback onTap;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(
            color: widget.done
                ? AppColors.accent
                : (_hover ? AppColors.surfaceRaised : AppColors.bg),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isToday
                  ? AppColors.accent.withValues(alpha: 0.75)
                  : (widget.done ? Colors.transparent : AppColors.border),
              width: widget.isToday
                  ? AppBorders.selected
                  : AppBorders.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: _hover ? AppColors.accentSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: _hover ? AppColors.borderAccent : AppColors.border,
              width: AppBorders.normal,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 15, color: AppColors.accent),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatefulWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_Arrow> createState() => _ArrowState();
}

class _ArrowState extends State<_Arrow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hover ? AppColors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Icon(
            widget.icon,
            size: 19,
            color: _hover ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}