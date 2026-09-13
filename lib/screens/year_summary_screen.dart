import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../models/month_budget.dart';
import '../models/transaction.dart';
import '../models/year_stats.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/account_glow.dart';
import '../widgets/account_selector.dart';
import '../widgets/all_transactions_card.dart';
import '../widgets/app_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/category_ranking_card.dart';
import '../widgets/cumulative_chart_card.dart';
import '../widgets/transaction_dialog.dart';
import 'package:flutter/services.dart';



final _accountKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.keyG: kGeneralAccountId,
  LogicalKeyboardKey.keyN: 'nubank',
  LogicalKeyboardKey.keyB: 'bradesco',
};

class YearSummaryScreen extends StatefulWidget {
  const YearSummaryScreen({super.key});

  @override
  State<YearSummaryScreen> createState() => _YearSummaryScreenState();
}

class _YearSummaryScreenState extends State<YearSummaryScreen> {
  int _year = DateTime.now().year;
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
      _changeYear(1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _changeYear(-1);
      return true;
    }

    return false;
  }

  void _changeYear(int delta) {
    setState(() => _year += delta);
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
    final monthLabels = [
      for (final name in monthNames) name.substring(0, 3),
    ];

    return StreamBuilder<List<Tx>>(
      stream: FinanceService.watchYearTransactions(_year),
      builder: (context, txSnap) {
        return StreamBuilder<List<MonthBudget>>(
          stream: FinanceService.watchYearBudgets(_year),
          builder: (context, budgetSnap) {
            final transactions = txSnap.data ?? const <Tx>[];
            final budgets = budgetSnap.data ?? const <MonthBudget>[];

            final stats = YearStats.from(
              transactions: transactions,
              budgets: budgets,
              accountId: _accountId,
              year: _year,
            );

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
                            _YearArrow(
                              icon: Icons.chevron_left,
                              onTap: () => _changeYear(-1),
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
                            _YearArrow(
                              icon: Icons.chevron_right,
                              onTap: () => _changeYear(1),
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
                              subtitle: 'Ano de $_year',
                            ),
                            const SizedBox(height: 14),
                            CumulativeChartCard(
                              title: 'Patrimônio ao longo do ano',
                              subtitle: 'Saldo acumulado mês a mês',
                              values: stats.cumulative,
                              labels: monthLabels,
                            ),
                            const SizedBox(height: 14),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: BarChartCard(
                                      title: 'Entradas por mês',
                                      subtitle: 'Ano de $_year',
                                      values: stats.monthlyIncome,
                                      color: AppColors.income,
                                      labels: monthLabels,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: BarChartCard(
                                      title: 'Saídas por mês',
                                      subtitle: 'Ano de $_year',
                                      values: stats.monthlyExpense,
                                      color: AppColors.expense,
                                      labels: monthLabels,
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

  final YearStats stats;

  @override
  Widget build(BuildContext context) {
    final topMonth = stats.topExpenseMonth;

    return Row(
      children: [
        Expanded(
          child: _SmallMetric(
            label: 'Média mensal de gastos',
            value: formatMoney(stats.monthlyAverage),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SmallMetric(
            label: 'Maior categoria',
            value: stats.topCategory ?? 'Sem dados',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SmallMetric(
            label: 'Mês de maior gasto',
            value: topMonth == null ? 'Sem dados' : monthNames[topMonth],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SmallMetric(
            label: 'Balanço',
            value: formatSigned(stats.balance),
            valueColor:
                stats.balance < 0 ? AppColors.expense : AppColors.income,
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
            overflow: TextOverflow.ellipsis,
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

class _YearArrow extends StatefulWidget {
  const _YearArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_YearArrow> createState() => _YearArrowState();
}

class _YearArrowState extends State<_YearArrow> {
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