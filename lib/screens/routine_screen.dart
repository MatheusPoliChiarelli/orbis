import 'dart:async';

import 'package:flutter/material.dart';

import '../models/routine_block.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/routine_block_dialog.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  DateTime _date = DateTime.now();
  DayType? _override;
  Timer? _clock;
  int _nowMinutes = 0;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    if (minutes != _nowMinutes && mounted) {
      setState(() => _nowMinutes = minutes);
    }
  }

  String get _dayKey => dayKey(_date);

  bool get _isToday {
    final now = DateTime.now();
    return now.year == _date.year &&
        now.month == _date.month &&
        now.day == _date.day;
  }

  DayType get _dayType {
    if (_override != null) return _override!;
    final weekday = _date.weekday;
    if (weekday == DateTime.saturday) return DayType.saturday;
    if (weekday == DateTime.sunday) {
      /// Domingos ímpares do mês são tipo N, pares são tipo D.
      final index = ((_date.day - 1) ~/ 7);
      return index.isEven ? DayType.sundayN : DayType.sundayD;
    }
    return DayType.weekday;
  }

  void _changeDay(int delta) {
    setState(() {
      _date = _date.add(Duration(days: delta));
      _override = null;
    });
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
      builder: (context, blockSnap) {
        return StreamBuilder<RoutineLog>(
          stream: RoutineService.watchLog(_dayKey),
          builder: (context, logSnap) {
            final all = blockSnap.data ?? const <RoutineBlock>[];
            final log = logSnap.data ?? RoutineLog.empty(_dayKey);

            final blocks = all
                .where((b) => b.dayType == _dayType)
                .where((b) => b.appliesTo(_date.weekday))
                .toList();

            final done = blocks.where((b) => log.isDone(b.id)).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Arrow(
                            icon: Icons.chevron_left,
                            onTap: () => _changeDay(-1),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 290,
                            child: Column(
                              children: [
                                Text(
                                  '${weekdayShort[_date.weekday - 1]}, ${_date.day} de ${monthLabel(_date).toLowerCase()}',
                                  textAlign: TextAlign.center,
                                  style: AppText.serif(size: 24),
                                ),
                                if (_isToday) ...[
                                  const SizedBox(height: 2),
                                  const Text(
                                    'hoje',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.accent,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          _Arrow(
                            icon: Icons.chevron_right,
                            onTap: () => _changeDay(1),
                          ),
                          const Spacer(),
                          if (blocks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                '$done de ${blocks.length} concluídos',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          _AddButton(
                            label: 'Novo bloco',
                            onTap: () => showRoutineBlockDialog(
                              context: context,
                              dayType: _dayType,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          for (final type in DayType.values) ...[
                            _TypeChip(
                              label: type.label,
                              selected: type == _dayType,
                              onTap: () => setState(() => _override = type),
                            ),
                            if (type != DayType.values.last)
                              const SizedBox(width: 9),
                          ],
                        ],
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
                      child: blocks.isEmpty
                          ? _EmptyState(
                              hasAnyBlock: all.isNotEmpty,
                              dayLabel: _dayType.label,
                            )
                          : AppCard(
                              title: 'Agenda do dia',
                              subtitle: _dayType.label,
                              child: Column(
                                children: [
                                  for (final block in blocks) ...[
                                    _BlockRow(
                                      block: block,
                                      done: log.isDone(block.id),
                                      current: _isToday &&
                                          block.containsMinute(_nowMinutes),
                                      onToggle: () => RoutineService.toggleDone(
                                        dayKey: _dayKey,
                                        blockId: block.id,
                                        done: !log.isDone(block.id),
                                      ),
                                      onEdit: () => showRoutineBlockDialog(
                                        context: context,
                                        dayType: _dayType,
                                        existing: block,
                                      ),
                                      onDelete: () => _confirmDelete(block),
                                    ),
                                    if (block != blocks.last)
                                      const SizedBox(height: 8),
                                  ],
                                ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAnyBlock, required this.dayLabel});

  final bool hasAnyBlock;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Agenda do dia',
      subtitle: dayLabel,
      child: Column(
        children: [
          EmptyHint(
            message: hasAnyBlock
                ? 'Nenhum bloco cadastrado para $dayLabel'
                : 'Você ainda não tem nenhuma rotina cadastrada',
          ),
          if (!hasAnyBlock) ...[
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
        ],
      ),
    );
  }
}

class _BlockRow extends StatefulWidget {
  const _BlockRow({
    required this.block,
    required this.done,
    required this.current,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final RoutineBlock block;
  final bool done;
  final bool current;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final done = widget.done;
    final current = widget.current;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: current
              ? AppColors.accentSoft
              : (_hover ? AppColors.surfaceRaised : AppColors.bg),
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(
            color: current ? AppColors.borderAccent : AppColors.border,
            width: current ? AppBorders.selected : AppBorders.normal,
          ),
        ),
        child: Row(
          children: [
            _Check(done: done, onTap: widget.onToggle),
            const SizedBox(width: 13),
            SizedBox(
              width: 108,
              child: Text(
                block.rangeLabel,
                style: AppText.money(
                  size: 12,
                  weight: FontWeight.w500,
                  color: current ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onEdit,
                  child: Text(
                    block.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                      color: done
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            if (current) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: const Text(
                  'agora',
                  style: TextStyle(fontSize: 10, color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${block.duration} min',
              style: AppText.money(size: 11, color: AppColors.textMuted),
            ),
            SizedBox(
              width: 34,
              child: _hover
                  ? IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      splashRadius: 15,
                      tooltip: 'Excluir',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: done ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: done ? AppColors.accent : AppColors.border,
              width: done ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 13, color: AppColors.onAccent)
              : null,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? AppColors.borderAccent : AppColors.border,
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.accent : AppColors.textSecondary,
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