import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/accounts.dart';
import '../models/month_budget.dart';
import '../models/transaction.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/account_selector.dart';
import '../widgets/day_strip.dart';
import '../widgets/day_summary_cards.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/transaction_list_card.dart';
import '../widgets/calculator_panel.dart';
import '../widgets/category_ranking_card.dart';
import '../widgets/category_filter_chips.dart';
import '../data/account_border.dart';

final _digitKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.digit0: '0',
  LogicalKeyboardKey.digit1: '1',
  LogicalKeyboardKey.digit2: '2',
  LogicalKeyboardKey.digit3: '3',
  LogicalKeyboardKey.digit4: '4',
  LogicalKeyboardKey.digit5: '5',
  LogicalKeyboardKey.digit6: '6',
  LogicalKeyboardKey.digit7: '7',
  LogicalKeyboardKey.digit8: '8',
  LogicalKeyboardKey.digit9: '9',
  LogicalKeyboardKey.numpad0: '0',
  LogicalKeyboardKey.numpad1: '1',
  LogicalKeyboardKey.numpad2: '2',
  LogicalKeyboardKey.numpad3: '3',
  LogicalKeyboardKey.numpad4: '4',
  LogicalKeyboardKey.numpad5: '5',
  LogicalKeyboardKey.numpad6: '6',
  LogicalKeyboardKey.numpad7: '7',
  LogicalKeyboardKey.numpad8: '8',
  LogicalKeyboardKey.numpad9: '9',
};

final _accountKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.keyG: kGeneralAccountId,
  LogicalKeyboardKey.keyN: 'nubank',
  LogicalKeyboardKey.keyB: 'bradesco',
};

class VariableExpensesScreen extends StatefulWidget {
  const VariableExpensesScreen({super.key});

  @override
  State<VariableExpensesScreen> createState() => _VariableExpensesScreenState();
}

class _VariableExpensesScreenState extends State<VariableExpensesScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;
  String _accountId = kGeneralAccountId;

  String _dayBuffer = '';
  Timer? _dayTimer;
  bool _showCalculator = false;

  bool get _isGeneral => _accountId == kGeneralAccountId;
    Color? get _border => accountBorder(_accountId);

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;
  ExpenseFilter _expenseFilter = ExpenseFilter.all;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _dayTimer?.cancel();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;

    if (ModalRoute.of(context)?.isCurrent != true) return false;

    final focused = FocusManager.instance.primaryFocus?.context?.widget;
    if (focused is EditableText) return false;

    final key = event.logicalKey;

    if (_showCalculator) return false;

    if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.equal) {
      setState(() => _showCalculator = true);
      return true;
    }

    final accountId = _accountKeys[key];
    if (accountId != null) {
      setState(() => _accountId = accountId);
      return true;
    }

    final digit = _digitKeys[key];
    if (digit != null) {
      _pushDigit(digit);
      return true;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      _openDialog(type: TxType.expense);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _openDialog(type: TxType.income);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _changeMonth(1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _changeMonth(-1);
      return true;
    }

    return false;
  }

  void _pushDigit(String digit) {
    _dayTimer?.cancel();

    if (_dayBuffer.isNotEmpty) {
      final combined = int.parse('$_dayBuffer$digit');
      _dayBuffer = '';
      if (combined >= 1 && combined <= _daysInMonth) {
        _selectDay(combined);
      } else {
        final single = int.parse(digit);
        if (single >= 1 && single <= _daysInMonth) _selectDay(single);
      }
      return;
    }

    final value = int.parse(digit);

    if (value >= 1 && value <= 3) {
      _dayBuffer = digit;
      _selectDay(value);
      _dayTimer = Timer(const Duration(milliseconds: 500), () {
        _dayBuffer = '';
      });
      return;
    }

    if (value >= 4 && value <= 9) {
      _selectDay(value);
    }
  }

  void _selectDay(int day) {
    if (day < 1 || day > _daysInMonth) return;
    setState(() => _selectedDay = day);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      if (_selectedDay > _daysInMonth) _selectedDay = _daysInMonth;
    });
  }

  List<Tx> _visibleTransactions(List<Tx> all) {
    return all.where((tx) {
      if (tx.date.day != _selectedDay) return false;
      if (_isGeneral) return true;
      return tx.accountId == _accountId || tx.toAccountId == _accountId;
    }).toList();
  }

  void _openDialog({required TxType type, Tx? existing}) {
    if (_isGeneral && existing == null) return;

    showTransactionDialog(
      context: context,
      date: DateTime(_month.year, _month.month, _selectedDay),
      accountId: existing?.accountId ?? _accountId,
      type: type,
      existing: existing,
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
            final dayTx = _visibleTransactions(transactions);

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  _Header(
                    month: _month,
                    accountId: _accountId,
                    budget: budget,
                    transactions: transactions,
                    onChangeMonth: _changeMonth,
                    onSelectAccount: (id) => setState(() => _accountId = id),
                    onNewIncome: () => _openDialog(type: TxType.income),
                    onNewExpense: () => _openDialog(type: TxType.expense),
                    borderColor: _border,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 18),
                    child: DayStrip(
                      month: _month,
                      selectedDay: _selectedDay,
                      onSelect: _selectDay,
                      borderColor: _border,
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
                            DaySummaryCards(
                              transactions: dayTx,
                              borderColor: _border,
                            ),
                            const SizedBox(height: 14),
                            TransactionListCard(
                              transactions: dayTx,
                              showAccountBadge: _isGeneral,
                              borderColor: _border,
                              onEdit: (tx) => _openDialog(
                                type: tx.type,
                                existing: tx,
                              ),
                              onDelete: _confirmDelete,
                            ),
                            const SizedBox(height: 14),
                            Builder(
                              builder: (context) {
                                final expenses = <String, double>{};
                                final expenseColors = <String, int>{};
                                final expenseIds = <String, String>{};
                                final incomes = <String, double>{};
                                final incomeColors = <String, int>{};
                                final incomeIds = <String, String>{};

                                var expenseTotal = 0.0;
                                var incomeTotal = 0.0;

                                for (final tx in dayTx) {
                                  if (tx.isTransfer) continue;
                                  if (tx.categoryId == 'investimentos') {
                                    continue;
                                  }

                                  if (tx.isIncome) {
                                    incomes[tx.categoryName] =
                                        (incomes[tx.categoryName] ?? 0) +
                                            tx.amount;
                                    incomeColors[tx.categoryName] =
                                        tx.categoryColor.toARGB32();
                                    incomeIds[tx.categoryName] = tx.categoryId;
                                    incomeTotal += tx.amount;
                                  } else {
                                    final keep = switch (_expenseFilter) {
                                      ExpenseFilter.all => true,
                                      ExpenseFilter.fixed => tx.isFixed,
                                      ExpenseFilter.variable => !tx.isFixed,
                                    };
                                    if (!keep) continue;

                                    expenses[tx.categoryName] =
                                        (expenses[tx.categoryName] ?? 0) +
                                            tx.amount;
                                    expenseColors[tx.categoryName] =
                                        tx.categoryColor.toARGB32();
                                    expenseIds[tx.categoryName] =
                                        tx.categoryId;
                                    expenseTotal += tx.amount;
                                  }
                                }

                                final label =
                                    '$_selectedDay de ${monthLabel(_month).toLowerCase()}';

                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: CategoryRankingCard(
                                          byCategory: expenses,
                                          categoryColors: expenseColors,
                                          categoryIds: expenseIds,
                                          total: expenseTotal,
                                          subtitle: label,
                                          action: CategoryFilterChips(
                                            selected: _expenseFilter,
                                            onSelect: (value) => setState(
                                              () => _expenseFilter = value,
                                            ),
                                          ),
                                          borderColor: _border,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: CategoryRankingCard(
                                          title: 'Entradas por categoria',
                                          emptyMessage:
                                              'Sem entradas registradas neste dia',
                                          byCategory: incomes,
                                          categoryColors: incomeColors,
                                          categoryIds: incomeIds,
                                          total: incomeTotal,
                                          subtitle: label,
                                          borderColor: _border,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
                if (_showCalculator)
                  Positioned(
                    right: 28,
                    bottom: 28,
                    child: CalculatorPanel(
                      onClose: () => setState(() => _showCalculator = false),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.accountId,
    required this.budget,
    required this.transactions,
    required this.onChangeMonth,
    required this.onSelectAccount,
    required this.onNewIncome,
    required this.onNewExpense,
    required this.borderColor,
  });

  final DateTime month;
  final String accountId;
  final MonthBudget budget;
  final List<Tx> transactions;
  final ValueChanged<int> onChangeMonth;
  final ValueChanged<String> onSelectAccount;
  final VoidCallback onNewIncome;
  final VoidCallback onNewExpense;
  final Color? borderColor;

  double _balanceFor(String id) {
    if (id == kGeneralAccountId) {
      var total = 0.0;
      for (final accountId in realAccountIds) {
        total += _balanceFor(accountId);
      }
      return total;
    }

    var total = budget.opening(id);
    for (final tx in transactions) {
      if (tx.isTransfer) {
        if (tx.accountId == id) total -= tx.amount;
        if (tx.toAccountId == id) total += tx.amount;
        continue;
      }
      if (tx.accountId != id) continue;
      total += tx.isIncome ? tx.amount : -tx.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final balances = <String, double>{
      for (final account in accounts) account.id: _balanceFor(account.id),
    };
    final isGeneral = accountId == kGeneralAccountId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MonthArrow(
                icon: Icons.chevron_left,
                onTap: () => onChangeMonth(-1),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 210,
                child: Text(
                  '${monthLabel(month)} ${month.year}',
                  textAlign: TextAlign.center,
                  style: AppText.serif(size: 26),
                ),
              ),
              const SizedBox(width: 4),
              _MonthArrow(
                icon: Icons.chevron_right,
                onTap: () => onChangeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              AccountSelector(
                selectedId: accountId,
                onSelect: onSelectAccount,
                balances: balances,
              ),
              const Spacer(),
              Opacity(
                opacity: isGeneral ? 0 : 1,
                child: IgnorePointer(
                  ignoring: isGeneral,
                  child: Row(
                    children: [
                      _ActionButton(
                        label: 'Saída',
                        icon: Icons.arrow_downward,
                        color: AppColors.expense,
                        enabled: true,
                        onTap: onNewExpense,
                      ),
                      const SizedBox(width: 10),
                      _ActionButton(
                        label: 'Entrada',
                        icon: Icons.arrow_upward,
                        color: AppColors.income,
                        enabled: true,
                        onTap: onNewIncome,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 140,
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          decoration: BoxDecoration(
            color: _hover
                ? color.withValues(alpha: 0.14)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: color.withValues(alpha: _hover ? 0.55 : 0.32),
              width: AppBorders.normal,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.20),
                      blurRadius: 18,
                      spreadRadius: -6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 14, color: color),
              ),
              Expanded(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 26),
            ],
          ),
        ),
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