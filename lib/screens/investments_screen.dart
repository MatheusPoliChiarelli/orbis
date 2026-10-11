import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/accounts.dart';
import '../models/transaction.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/account_glow.dart';
import '../widgets/all_transactions_card.dart';
import '../widgets/app_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/cumulative_chart_card.dart';
import '../widgets/transaction_dialog.dart';

final _accountKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.keyG: kGeneralAccountId,
  LogicalKeyboardKey.keyN: 'nubank',
  LogicalKeyboardKey.keyB: 'bradesco',
};

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
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
      setState(() => _year++);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() => _year--);
      return true;
    }

    return false;
  }

  List<Tx> _investments(List<Tx> all) {
    return all.where((tx) {
      if (tx.categoryId != 'investimentos') return false;
      if (_accountId == kGeneralAccountId) return true;
      return tx.accountId == _accountId;
    }).toList();
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
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <Tx>[];
        final investments = _investments(all);

        final monthly = List<double>.filled(12, 0);
        for (final tx in investments) {
          final index = tx.date.month - 1;
          if (index >= 0 && index < 12) monthly[index] += tx.amount;
        }

        final total = monthly.fold<double>(0, (a, value) => a + value);

        final accumulated = <double>[];
        var running = 0.0;
        for (final value in monthly) {
          running += value;
          accumulated.add(running);
        }

        final bestMonth = _bestMonth(monthly);

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Total investido',
                                value: formatMoney(total),
                                color: AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _Metric(
                                label: 'Média mensal',
                                value: formatMoney(total / 12),
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _Metric(
                                label: 'Melhor mês',
                                value: bestMonth == null
                                    ? 'Sem dados'
                                    : monthNames[bestMonth],
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _Metric(
                                label: 'Aportes no ano',
                                value: '${investments.length}',
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        BarChartCard(
                          title: 'Aportes por mês',
                          subtitle: 'Ano de $_year',
                          values: monthly,
                          color: AppColors.income,
                          labels: monthLabels,
                          height: 230,
                        ),
                        const SizedBox(height: 14),
                        CumulativeChartCard(
                          title: 'Acumulado no ano',
                          subtitle: 'Soma dos aportes mês a mês',
                          values: accumulated,
                          labels: monthLabels,
                        ),
                        const SizedBox(height: 14),
                        AllTransactionsCard(
                          transactions: investments,
                          balance: total,
                          showAccountBadge: false,
                          showFilters: false,
                          amountAtEnd: true,
                          amountColor: AppColors.income,
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
  }

  int? _bestMonth(List<double> monthly) {
    var best = -1;
    var bestValue = 0.0;
    for (var i = 0; i < monthly.length; i++) {
      if (monthly[i] > bestValue) {
        bestValue = monthly[i];
        best = i;
      }
    }
    return best < 0 ? null : best;
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: AppText.money(
              size: 18,
              color: color,
              weight: FontWeight.w600,
            ),
          ),
        ],
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