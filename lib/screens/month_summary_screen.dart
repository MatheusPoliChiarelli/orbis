import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../models/month_budget.dart';
import '../models/month_stats.dart';
import '../models/transaction.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/account_glow.dart';
import '../widgets/account_selector.dart';
import '../widgets/app_card.dart';
import '../widgets/category_ranking_card.dart';
import '../widgets/all_transactions_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/cumulative_chart_card.dart';
import '../widgets/transaction_dialog.dart';
import 'package:flutter/services.dart';


final _accountKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.keyG: kGeneralAccountId,
  LogicalKeyboardKey.keyN: 'nubank',
  LogicalKeyboardKey.keyB: 'bradesco',
};


class MonthSummaryScreen extends StatefulWidget {
  const MonthSummaryScreen({super.key});

  @override
  State<MonthSummaryScreen> createState() => _MonthSummaryScreenState();
}

class _MonthSummaryScreenState extends State<MonthSummaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _accountId = kGeneralAccountId;


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

    final accountId = _accountKeys[event.logicalKey];
    if (accountId != null) {
      setState(() => _accountId = accountId);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _changeMonth(1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _changeMonth(-1);
      return true;
    }

    return false;
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  List<Tx> _filtered(List<Tx> all) {
    if (_accountId == kGeneralAccountId) return all;
    return all.where((tx) => tx.accountId == _accountId).toList();
  }

  void _openDialog(Tx tx) {
    showTransactionDialog(
      context: context,
      date: tx.date,
      accountId: tx.accountId,
      type: tx.type,
      existing: tx,
    );
  }

  Future<void> _confirmDelete(Tx tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text(
          'Excluir lançamento',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
        content: Text(
          'Excluir ${tx.description.isEmpty ? tx.categoryName : tx.description}?',
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
      await FinanceService.deleteTransaction(tx.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tx>>(
      stream: FinanceService.watchMonthTransactions(_month),
      builder: (context, txSnap) {
        return StreamBuilder<MonthBudget>(
          stream: FinanceService.watchMonthBudget(_month),
          builder: (context, budgetSnap) {
            final transactions = txSnap.data ?? const <Tx>[];
            final budget =
                budgetSnap.data ?? MonthBudget.empty(monthKey(_month));

            final stats = MonthStats.from(
              month: _month,
              transactions: transactions,
              budget: budget,
              accountId: _accountId,
            );

            final periodLabel = '${monthLabel(_month)} de ${_month.year}';
            final dayLabels = [
              for (var i = 1; i <= stats.dailyIncome.length; i++) '$i',
            ];

            return AccountGlow(
              accountId: _accountId,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _MonthArrow(
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
                            _MonthArrow(
                              icon: Icons.chevron_right,
                              onTap: () => _changeMonth(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AccountSelector(
                          selectedId: _accountId,
                          onSelect: (id) => setState(() => _accountId = id),
                          balances: const {},
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _BigMetric(
                                    label: 'Receitas',
                                    value: stats.income,
                                    color: AppColors.income,
                                    icon: Icons.arrow_upward,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _BigMetric(
                                    label: 'Despesas',
                                    value: stats.expense,
                                    color: AppColors.expense,
                                    icon: Icons.arrow_downward,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _MetricsRow(stats: stats),
                            const SizedBox(height: 14),
                            CategoryRankingCard(
                              byCategory: stats.byCategory,
                              categoryColors: stats.categoryColors,
                              categoryIds: stats.categoryIds,
                              total: stats.expense,
                              subtitle: periodLabel,
                            ),
                            const SizedBox(height: 14),
                            CumulativeChartCard(
                              title: 'Patrimônio ao longo do mês',
                              subtitle: 'Saldo acumulado dia a dia',
                              values: stats.cumulative,
                              labels: dayLabels,
                            ),
                            const SizedBox(height: 14),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: BarChartCard(
                                      title: 'Entradas por dia',
                                      subtitle: periodLabel,
                                      values: stats.dailyIncome,
                                      color: AppColors.income,
                                      labels: dayLabels,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: BarChartCard(
                                      title: 'Saídas por dia',
                                      subtitle: periodLabel,
                                      values: stats.dailyExpense,
                                      color: AppColors.expense,
                                      labels: dayLabels,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            AllTransactionsCard(
                              transactions: _filtered(transactions),
                              balance: stats.balance,
                              showAccountBadge:
                                  _accountId == kGeneralAccountId,
                              onEdit: _openDialog,
                              onDelete: _confirmDelete,
                            ),
                          ],
                        ),
                      ),
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
}

class _BigMetric extends StatelessWidget {
  const _BigMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatMoney(value),
            style: AppText.money(
              size: 26,
              color: color,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.stats});

  final MonthStats stats;

  @override
  Widget build(BuildContext context) {
    final top = stats.topCategory;

    return Row(
      children: [
        Expanded(
          child: _SmallMetric(
            label: 'Média diária de gastos',
            value: formatMoney(stats.dailyAverage),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SmallMetric(
            label: 'Maior categoria',
            value: top ?? 'Sem dados',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SmallMetric(
            label: 'Total de lançamentos',
            value: '${stats.count}',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SmallMetric(
            label: 'Balanço',
            value: formatSigned(stats.balance),
            valueColor: stats.balance < 0
                ? AppColors.expense
                : AppColors.income,
          ),
        ),
      ],
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: AppText.money(
              size: 13.5,
              weight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatefulWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_MonthArrow> createState() => _MonthArrowState();
}

class _MonthArrowState extends State<_MonthArrow> {
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