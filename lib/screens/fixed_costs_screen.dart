import 'package:flutter/material.dart';

import '../models/fixed_cost.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/fixed_cost_dialog.dart';
import 'package:flutter/services.dart';

class FixedCostsScreen extends StatefulWidget {
  const FixedCostsScreen({super.key});

  @override
  State<FixedCostsScreen> createState() => _FixedCostsScreenState();
}

class _FixedCostsScreenState extends State<FixedCostsScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
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
      showFixedCostDialog(context: context, year: _year);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      setState(() => _year++);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() => _year--);
      return true;
    }

    return false;
  }


  Future<void> _confirmDelete(FixedCost item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text(
          'Excluir item',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
        content: Text(
          item.isChild
              ? 'Excluir ${item.name}?'
              : 'Excluir ${item.name} e tudo que está dentro dele?',
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
      await FinanceService.deleteFixedCost(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FixedCost>>(
      stream: FinanceService.watchFixedCosts(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <FixedCost>[];

        final monthly = [
          for (var i = 1; i <= 12; i++)
            FixedCostMonth.build(
              monthKey: '$_year-${i.toString().padLeft(2, '0')}',
              all: all,
            ),
        ];

        final current = monthly[_month - 1];
        final yearTotal = monthly.fold<double>(0, (a, m) => a + m.total);

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
                        onTap: () => setState(() => _year--),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 150,
                        child: Text(
                          '$_year',
                          textAlign: TextAlign.center,
                          style: AppText.serif(size: 26),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _Arrow(
                        icon: Icons.chevron_right,
                        onTap: () => setState(() => _year++),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Custo fixo do ano',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatMoney(yearTotal),
                            style: AppText.money(
                              size: 22,
                              weight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      _AddButton(
                        label: 'Novo item',
                        onTap: () => showFixedCostDialog(
                          context: context,
                          year: _year,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MonthTabs(
                    selected: _month,
                    totals: [for (final m in monthly) m.total],
                    onSelect: (value) => setState(() => _month = value),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        title: 'Itens de ${monthNames[_month - 1]}',
                        subtitle: 'Custo fixo de ${formatMoney(current.total)}',
                        child: current.parents.isEmpty
                            ? const EmptyHint(
                                message: 'Nenhum item fixo neste mês',
                              )
                            : Column(
                                children: [
                                  for (final item in current.parents) ...[
                                    _ItemRow(
                                      item: item,
                                      amount: current.amountOf(item),
                                      children:
                                          current.childrenByParent[item.id] ??
                                              const [],
                                      year: _year,
                                      onDelete: _confirmDelete,
                                    ),
                                    if (item != current.parents.last)
                                      const Divider(
                                        height: 20,
                                        thickness: AppBorders.normal,
                                        color: AppColors.border,
                                      ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      BarChartCard(
                        title: 'Custo fixo por mês',
                        subtitle: 'Projeção de $_year',
                        values: [for (final m in monthly) m.total],
                        color: AppColors.accent,
                        labels: [
                          for (final name in monthNames) name.substring(0, 3),
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

class _MonthTabs extends StatelessWidget {
  const _MonthTabs({
    required this.selected,
    required this.totals,
    required this.onSelect,
  });

  final int selected;
  final List<double> totals;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 12; i++) ...[
          Expanded(
            child: _MonthTab(
              label: monthNames[i - 1].substring(0, 3),
              total: totals[i - 1],
              selected: i == selected,
              onTap: () => onSelect(i),
            ),
          ),
          if (i != 12) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _MonthTab extends StatefulWidget {
  const _MonthTab({
    required this.label,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double total;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends State<_MonthTab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentSoft
                : (_hover ? AppColors.surfaceRaised : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: selected ? AppColors.borderAccent : AppColors.border,
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatMoneyPlain(widget.total),
                style: AppText.money(
                  size: 10.5,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.amount,
    required this.children,
    required this.year,
    required this.onDelete,
  });

  final FixedCost item;
  final double amount;
  final List<FixedCost> children;
  final int year;
  final ValueChanged<FixedCost> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          name: item.name,
          amount: amount,
          period: _periodLabel(item),
          bold: true,
          onEdit: () => showFixedCostDialog(
            context: context,
            year: year,
            existing: item,
          ),
          onDelete: () => onDelete(item),
          onAddChild: () => showFixedCostDialog(
            context: context,
            year: year,
            parentId: item.id,
            parentName: item.name,
          ),
        ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.only(left: 14),
            padding: const EdgeInsets.only(left: 14),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.border,
                  width: AppBorders.selected,
                ),
              ),
            ),
            child: Column(
              children: [
                for (final child in children) ...[
                  _Line(
                    name: child.name,
                    amount: child.amount,
                    period: _periodLabel(child),
                    bold: false,
                    onEdit: () => showFixedCostDialog(
                      context: context,
                      year: year,
                      existing: child,
                    ),
                    onDelete: () => onDelete(child),
                  ),
                  if (child != children.last) const SizedBox(height: 9),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  String? _periodLabel(FixedCost item) {
    if (item.startMonth == null && item.endMonth == null) return null;
    final start = item.startMonth == null
        ? 'início'
        : monthNames[int.parse(item.startMonth!.split('-')[1]) - 1]
            .substring(0, 3)
            .toLowerCase();
    final end = item.endMonth == null
        ? 'dezembro'
        : monthNames[int.parse(item.endMonth!.split('-')[1]) - 1]
            .substring(0, 3)
            .toLowerCase();
    return '$start até $end';
  }
}

class _Line extends StatefulWidget {
  const _Line({
    required this.name,
    required this.amount,
    required this.period,
    required this.bold,
    required this.onEdit,
    required this.onDelete,
    this.onAddChild,
  });

  final String name;
  final double amount;
  final String? period;
  final bool bold;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddChild;

  @override
  State<_Line> createState() => _LineState();
}

class _LineState extends State<_Line> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.bold ? 13.5 : 12.5,
                        fontWeight:
                            widget.bold ? FontWeight.w600 : FontWeight.w400,
                        color: widget.bold
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (widget.period != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        widget.period!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              formatMoney(widget.amount),
              style: AppText.money(
                size: widget.bold ? 13.5 : 12.5,
                weight: widget.bold ? FontWeight.w600 : FontWeight.w500,
                color: widget.bold
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(
              width: widget.onAddChild == null ? 34 : 66,
              child: _hover
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.onAddChild != null)
                          IconButton(
                            onPressed: widget.onAddChild,
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            splashRadius: 16,
                            tooltip: 'Adicionar dentro',
                          ),
                        IconButton(
                          onPressed: widget.onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          splashRadius: 16,
                          tooltip: 'Excluir',
                        ),
                      ],
                    )
                  : null,
            ),
          ],
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