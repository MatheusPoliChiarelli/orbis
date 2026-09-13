import 'dart:async';

import 'package:flutter/material.dart';

import '../models/routine_block.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/routine_block_dialog.dart';
import 'package:flutter/services.dart';

const _timeColumnWidth = 118.0;
const _rowHeight = 46.0;
const _headerHeight = 38.0;
const _cellGap = 8.0;

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  Timer? _clock;
  int _nowMinutes = 0;
  int _todayWeekday = DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
    _updateClock();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _clock?.cancel();
    super.dispose();
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
      showRoutineBlockDialog(context: context, dayType: DayType.weekday);
      return true;
    }

    return false;
  }

  void _updateClock() {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    if ((minutes != _nowMinutes || now.weekday != _todayWeekday) && mounted) {
      setState(() {
        _nowMinutes = minutes;
        _todayWeekday = now.weekday;
      });
    }
  }

  Future<void> _confirmDelete(RoutineBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text(
          'Excluir bloco',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
        content: Text(
          'Excluir ${block.label} de ${block.rangeLabel}?',
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
      await RoutineService.deleteBlock(block.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoutineBlock>>(
      stream: RoutineService.watchBlocks(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <RoutineBlock>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rotina', style: AppText.serif(size: 26)),
                      const SizedBox(height: 3),
                      const Text(
                        'Seu padrão semanal de atividades',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _AddButton(
                    label: 'Novo bloco',
                    onTap: () => showRoutineBlockDialog(
                      context: context,
                      dayType: DayType.weekday,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: all.isEmpty
                      ? const _EmptyState()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Table(
                              title: 'Dias úteis',
                              blocks: all
                                  .where((b) => b.dayType == DayType.weekday)
                                  .toList(),
                              columns: [
                                for (var day = 1; day <= 5; day++)
                                  _ColumnInfo(
                                    weekday: day,
                                    label: const [
                                      'Segunda',
                                      'Terça',
                                      'Quarta',
                                      'Quinta',
                                      'Sexta',
                                    ][day - 1],
                                    isToday: day == _todayWeekday,
                                  ),
                              ],
                              nowMinutes: _nowMinutes,
                              onDelete: _confirmDelete,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _Table(
                                    title: 'Sábado',
                                    blocks: all
                                        .where(
                                          (b) => b.dayType == DayType.saturday,
                                        )
                                        .toList(),
                                    columns: [
                                      _ColumnInfo(
                                        weekday: DateTime.saturday,
                                        label: 'Sábado',
                                        isToday:
                                            _todayWeekday == DateTime.saturday,
                                        showHeader: false,
                                      ),
                                    ],
                                    nowMinutes: _nowMinutes,
                                    onDelete: _confirmDelete,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _Table(
                                    title: 'Domingo',
                                    blocks: all
                                        .where(
                                          (b) => b.dayType == DayType.sunday,
                                        )
                                        .toList(),
                                    columns: [
                                      _ColumnInfo(
                                        weekday: DateTime.sunday,
                                        label: 'Domingo',
                                        isToday:
                                            _todayWeekday == DateTime.sunday,
                                        showHeader: false,
                                      ),
                                    ],
                                    nowMinutes: _nowMinutes,
                                    onDelete: _confirmDelete,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColumnInfo {
  const _ColumnInfo({
    required this.weekday,
    required this.label,
    required this.isToday,
    this.showHeader = true,
  });

  final int weekday;
  final String label;
  final bool isToday;
  final bool showHeader;
}

class _Slot {
  const _Slot({required this.start, required this.end, required this.blocks});

  final int start;
  final int end;
  final List<RoutineBlock> blocks;

  String get startLabel => RoutineBlock.format(start);
  String get endLabel => RoutineBlock.format(end);

  RoutineBlock? blockFor(int weekday) {
    for (final block in blocks) {
      if (block.appliesTo(weekday)) return block;
    }
    return null;
  }

  bool containsMinute(int minute) {
    if (end >= start) return minute >= start && minute < end;
    return minute >= start || minute < end;
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.title,
    required this.blocks,
    required this.columns,
    required this.nowMinutes,
    required this.onDelete,
  });

  final String title;
  final List<RoutineBlock> blocks;
  final List<_ColumnInfo> columns;
  final int nowMinutes;
  final ValueChanged<RoutineBlock> onDelete;

  List<_Slot> get _slots {
    final grouped = <String, List<RoutineBlock>>{};
    for (final block in blocks) {
      final key = '${block.startMinutes}-${block.endMinutes}';
      grouped.putIfAbsent(key, () => []).add(block);
    }

    return grouped.values
        .map(
          (list) => _Slot(
            start: list.first.startMinutes,
            end: list.first.endMinutes,
            blocks: list,
          ),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots;
    final showHeader = columns.any((c) => c.showHeader);

    return AppCard(
      title: title,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: slots.isEmpty
          ? const EmptyHint(message: 'Nenhum bloco cadastrado aqui')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader)
                  SizedBox(
                    height: _headerHeight,
                    child: Row(
                      children: [
                        const SizedBox(width: _timeColumnWidth),
                        for (final column in columns)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: _cellGap),
                              child: Center(
                                child: Text(
                                  column.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: column.isToday
                                        ? AppColors.accentHover
                                        : AppColors.accent,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                for (var i = 0; i < slots.length; i++)
                  _Row(
                    slot: slots[i],
                    columns: columns,
                    striped: i.isOdd,
                    nowMinutes: nowMinutes,
                    onDelete: onDelete,
                  ),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.slot,
    required this.columns,
    required this.striped,
    required this.nowMinutes,
    required this.onDelete,
  });

  final _Slot slot;
  final List<_ColumnInfo> columns;
  final bool striped;
  final int nowMinutes;
  final ValueChanged<RoutineBlock> onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${slot.startLabel} - ${slot.endLabel}',
                  style: AppText.money(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
          for (final column in columns)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: _cellGap, bottom: 5),
                child: _Cell(
                  block: slot.blockFor(column.weekday),
                  current: column.isToday && slot.containsMinute(nowMinutes),
                  onDelete: onDelete,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatefulWidget {
  const _Cell({
    required this.block,
    required this.current,
    required this.onDelete,
  });

  final RoutineBlock? block;
  final bool current;
  final ValueChanged<RoutineBlock> onDelete;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final block = widget.block;

    if (block == null) {
      return Center(
        child: Container(
          width: 14,
          height: 1,
          color: AppColors.border,
        ),
      );
    }

    final current = widget.current;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => showRoutineBlockDialog(
          context: context,
          dayType: block.dayType,
          existing: block,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: current
                ? AppColors.accentSoft
                : (_hover ? AppColors.surfaceRaised : AppColors.surface),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: current
                  ? AppColors.accent
                  : (_hover
                      ? AppColors.accent.withValues(alpha: 0.55)
                      : AppColors.borderAccent),
              width: current ? AppBorders.selected : AppBorders.normal,
            ),
            boxShadow: current
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.20),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                block.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                  color: current ? AppColors.accentHover : AppColors.textPrimary,
                ),
              ),
              if (_hover)
                Align(
                  alignment: Alignment.centerRight,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => widget.onDelete(block),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        color: current
                            ? AppColors.accentSoft
                            : AppColors.surfaceRaised,
                        child: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Rotina da semana',
      child: Column(
        children: [
          const EmptyHint(
            message: 'Você ainda não tem nenhuma rotina cadastrada',
          ),
          const SizedBox(height: 6),
          Center(
            child: _AddButton(
              label: 'Carregar rotina padrão',
              onTap: RoutineService.seedDefaults,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Traz o template da sua planilha, que você pode ajustar depois',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
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