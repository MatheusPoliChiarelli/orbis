import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/habit_dialog.dart';

const _nameColumnWidth = 180.0;
const _cellSize = 26.0;
const _cellGap = 4.0;
const _rowHeight = 34.0;
const _statsWidth = 92.0;

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _gridController = ScrollController();

  int? _cursorDay;
  int _cursorRow = 0;
  List<Habit> _habits = const [];

  String get _monthKey => monthKey(_month);

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _gridController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _cursorDay = null;
    });
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;

    final focused = FocusManager.instance.primaryFocus?.context?.widget;
    if (focused is EditableText) return false;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.equal) {
      showHabitDialog(context: context);
      return true;
    }

    if (_cursorDay == null || _habits.isEmpty) return false;
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _cursorDay = null);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _cursorRow = (_cursorRow + 1).clamp(0, _habits.length - 1);
      });
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _cursorRow = (_cursorRow - 1).clamp(0, _habits.length - 1);
      });
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      setState(() => _cursorDay = (_cursorDay! + 1).clamp(1, _daysInMonth));
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() => _cursorDay = (_cursorDay! - 1).clamp(1, _daysInMonth));
      return true;
    }

    final mark = switch (key) {
      LogicalKeyboardKey.keyS => HabitMark.done,
      LogicalKeyboardKey.keyN => HabitMark.missed,
      LogicalKeyboardKey.keyA => HabitMark.skipped,
      LogicalKeyboardKey.space || LogicalKeyboardKey.backspace =>
        HabitMark.none,
      _ => null,
    };

    if (mark == null) return false;

    HabitService.setMark(
      monthKey: _monthKey,
      habitId: _habits[_cursorRow].id,
      day: _cursorDay!,
      mark: mark,
    );

    setState(() {
      if (_cursorRow < _habits.length - 1) _cursorRow++;
    });
    return true;
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
          'Excluir ${habit.name}?',
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
            _habits = (habitSnap.data ?? const <Habit>[])
                .where((h) => h.active)
                .toList();
            final log = logSnap.data ?? HabitLog.empty(_monthKey);

            if (_cursorRow >= _habits.length) _cursorRow = 0;

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
                      if (_cursorDay != null) ...[
                        const _KeyHints(),
                        const SizedBox(width: 16),
                      ],
                      _AddButton(
                        label: 'Novo hábito',
                        onTap: () => showHabitDialog(context: context),
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
                        padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
                        title: 'Grade do mês',
                        subtitle: _cursorDay == null
                            ? 'Clique numa célula para marcar pelo teclado'
                            : 'Marcando o dia $_cursorDay',
                        child: _habits.isEmpty
                            ? const EmptyHint(
                                message: 'Nenhum hábito cadastrado ainda',
                              )
                            : _Grid(
                                habits: _habits,
                                log: log,
                                month: _month,
                                daysInMonth: _daysInMonth,
                                controller: _gridController,
                                cursorDay: _cursorDay,
                                cursorRow: _cursorRow,
                                onCellTap: (row, day) => setState(() {
                                  _cursorRow = row;
                                  _cursorDay = day;
                                }),
                                onEdit: (habit) => showHabitDialog(
                                  context: context,
                                  existing: habit,
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

class _KeyHints extends StatelessWidget {
  const _KeyHints();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Hint(key_: 'S', label: 'feito', color: AppColors.income),
        SizedBox(width: 10),
        _Hint(key_: 'N', label: 'não feito', color: AppColors.expense),
        SizedBox(width: 10),
        _Hint(key_: 'A', label: 'não valia', color: AppColors.accent),
        SizedBox(width: 10),
        _Hint(key_: 'esc', label: 'sair', color: AppColors.textMuted),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.key_,
    required this.label,
    required this.color,
  });

  final String key_;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: color.withValues(alpha: 0.38),
              width: AppBorders.normal,
            ),
          ),
          child: Text(
            key_,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.habits,
    required this.log,
    required this.month,
    required this.daysInMonth,
    required this.controller,
    required this.cursorDay,
    required this.cursorRow,
    required this.onCellTap,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Habit> habits;
  final HabitLog log;
  final DateTime month;
  final int daysInMonth;
  final ScrollController controller;
  final int? cursorDay;
  final int cursorRow;
  final void Function(int row, int day) onCellTap;
  final ValueChanged<Habit> onEdit;
  final ValueChanged<Habit> onDelete;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;
    final cutoff = isCurrentMonth ? today.day : daysInMonth;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _nameColumnWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              for (var i = 0; i < habits.length; i++)
                _NameCell(
                  habit: habits[i],
                  highlighted: cursorDay != null && i == cursorRow,
                  onEdit: () => onEdit(habits[i]),
                  onDelete: () => onDelete(habits[i]),
                ),
            ],
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
                                  color: day == cursorDay
                                      ? AppColors.accentHover
                                      : (isCurrentMonth && day == today.day
                                          ? AppColors.accent
                                          : AppColors.textMuted),
                                  weight: day == cursorDay ||
                                          (isCurrentMonth && day == today.day)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < habits.length; i++)
                    _HabitRow(
                      habit: habits[i],
                      row: i,
                      log: log,
                      daysInMonth: daysInMonth,
                      cutoff: cutoff,
                      today: isCurrentMonth ? today.day : null,
                      cursorDay: cursorDay,
                      cursorRow: cursorRow,
                      onCellTap: onCellTap,
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: _statsWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 30,
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
              for (final habit in habits)
                _StatsCell(
                  habit: habit,
                  log: log,
                  daysInMonth: daysInMonth,
                  cutoff: cutoff,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCell extends StatelessWidget {
  const _StatsCell({
    required this.habit,
    required this.log,
    required this.daysInMonth,
    required this.cutoff,
  });

  final Habit habit;
  final HabitLog log;
  final int daysInMonth;
  final int cutoff;

  @override
  Widget build(BuildContext context) {
    final done = log.doneCount(habit.id, daysInMonth);
    final expected = log.expectedCount(habit.id, daysInMonth);
    final streak = log.streak(habit.id, cutoff);
    final share = expected == 0 ? 0.0 : (done / expected).clamp(0.0, 1.0);

    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
              const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$done',
              textAlign: TextAlign.right,
              style: AppText.money(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '/$expected',
              style: AppText.money(size: 10.5, color: AppColors.textMuted),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${(share * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: AppText.money(
                size: 10.5,
                color:
                    share >= 1 ? const Color(0xFF3FAE6B) : AppColors.textMuted,
              ),
            ),
          ),
          if (streak > 1) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.bolt,
              size: 11,
              color: AppColors.accent.withValues(alpha: 0.8),
            ),
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
    );
  }
}

class _NameCell extends StatefulWidget {
  const _NameCell({
    required this.habit,
    required this.highlighted,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final bool highlighted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_NameCell> createState() => _NameCellState();
}

class _NameCellState extends State<_NameCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
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
                  widget.habit.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: widget.highlighted
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.highlighted
                        ? AppColors.accent
                        : (_hover
                            ? AppColors.textPrimary
                            : AppColors.textSecondary),
                  ),
                ),
              ),
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
    required this.row,
    required this.log,
    required this.daysInMonth,
    required this.cutoff,
    required this.today,
    required this.cursorDay,
    required this.cursorRow,
    required this.onCellTap,
  });

  final Habit habit;
  final int row;
  final HabitLog log;
  final int daysInMonth;
  final int cutoff;
  final int? today;
  final int? cursorDay;
  final int cursorRow;
  final void Function(int row, int day) onCellTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          for (var day = 1; day <= daysInMonth; day++)
            Padding(
              padding: const EdgeInsets.only(right: _cellGap),
              child: _Cell(
                mark: log.markOf(habit.id, day),
                isToday: day == today,
                isCursor: day == cursorDay && row == cursorRow,
                inCursorColumn: day == cursorDay,
                onTap: () => onCellTap(row, day),
              ),
            ),

        ],
      ),
    );
  }
}

class _Cell extends StatefulWidget {
  const _Cell({
    required this.mark,
    required this.isToday,
    required this.isCursor,
    required this.inCursorColumn,
    required this.onTap,
  });

  final HabitMark mark;
  final bool isToday;
  final bool isCursor;
  final bool inCursorColumn;
  final VoidCallback onTap;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fill = switch (widget.mark) {
      HabitMark.done => const Color(0xFF3FAE6B),
      HabitMark.missed => const Color(0xFFE04848),
      HabitMark.skipped => AppColors.accent.withValues(alpha: 0.55),
      HabitMark.none => _hover ? AppColors.surfaceRaised : AppColors.bg,
    };

    final hasMark = widget.mark != HabitMark.none;

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
            color: fill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isCursor
                  ? AppColors.accentHover
                  : (widget.inCursorColumn
                      ? AppColors.accent.withValues(alpha: 0.35)
                      : (widget.isToday
                          ? AppColors.accent.withValues(alpha: 0.6)
                          : (hasMark ? Colors.transparent : AppColors.border))),
              width: widget.isCursor ? 2 : AppBorders.normal,
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