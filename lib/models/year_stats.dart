import '../data/accounts.dart';
import 'month_budget.dart';
import 'transaction.dart';

class YearStats {
  const YearStats({
    required this.income,
    required this.expense,
    required this.expenseFixed,
    required this.expenseVariable,
    required this.count,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.byCategory,
    required this.categoryColors,
    required this.categoryIds,
    required this.opening,
  });

  final double income;
  final double expense;
  final double expenseFixed;
  final double expenseVariable;
  final int count;

  /// Índice 0 é janeiro.
  final List<double> monthlyIncome;
  final List<double> monthlyExpense;

  final Map<String, double> byCategory;
  final Map<String, int> categoryColors;
  final Map<String, String> categoryIds;

  final double opening;

  double get balance => income - expense;

  double get monthlyAverage => expense / 12;

  String? get topCategory {
    if (byCategory.isEmpty) return null;
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  int? get topExpenseMonth {
    var best = -1;
    var bestValue = 0.0;
    for (var i = 0; i < monthlyExpense.length; i++) {
      if (monthlyExpense[i] > bestValue) {
        bestValue = monthlyExpense[i];
        best = i;
      }
    }
    return best < 0 ? null : best;
  }

  /// Patrimônio acumulado mês a mês, partindo do saldo inicial de janeiro.
  List<double> get cumulative {
    final result = <double>[];
    var running = opening;
    for (var i = 0; i < monthlyIncome.length; i++) {
      running += monthlyIncome[i] - monthlyExpense[i];
      result.add(running);
    }
    return result;
  }

  factory YearStats.from({
    required List<Tx> transactions,
    required List<MonthBudget> budgets,
    required String accountId,
    required int year,
  }) {
    final monthlyIncome = List<double>.filled(12, 0);
    final monthlyExpense = List<double>.filled(12, 0);
    final byCategory = <String, double>{};
    final categoryColors = <String, int>{};
    final categoryIds = <String, String>{};

    final isGeneral = accountId == kGeneralAccountId;

    var income = 0.0;
    var expense = 0.0;
    var expenseFixed = 0.0;
    var expenseVariable = 0.0;
    var count = 0;

    for (final tx in transactions) {
      if (!isGeneral && tx.accountId != accountId) continue;
      if (tx.isTransfer) continue;

      count++;
      final index = tx.date.month - 1;
      if (index < 0 || index > 11) continue;

      if (tx.isIncome) {
        income += tx.amount;
        monthlyIncome[index] += tx.amount;
      } else {
        expense += tx.amount;
        if (tx.isFixed) {
          expenseFixed += tx.amount;
        } else {
          expenseVariable += tx.amount;
        }
        monthlyExpense[index] += tx.amount;
        byCategory[tx.categoryName] =
            (byCategory[tx.categoryName] ?? 0) + tx.amount;
        categoryColors[tx.categoryName] = tx.categoryColor.toARGB32();
        categoryIds[tx.categoryName] = tx.categoryId;
      }
    }

    final januaryKey = '$year-01';
    final january = budgets.where((b) => b.monthKey == januaryKey).firstOrNull;

    final opening = january == null
        ? 0.0
        : (isGeneral
            ? realAccountIds.fold<double>(
                0,
                (sum, id) => sum + january.opening(id),
              )
            : january.opening(accountId));

    return YearStats(
      income: income,
      expense: expense,
      expenseFixed: expenseFixed,
      expenseVariable: expenseVariable,
      count: count,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      byCategory: byCategory,
      categoryColors: categoryColors,
      categoryIds: categoryIds,
      opening: opening,
    );
  }
}