import '../data/accounts.dart';
import 'month_budget.dart';
import 'transaction.dart';

class MonthStats {
  const MonthStats({
    required this.income,
    required this.expense,
    required this.count,
    required this.dailyIncome,
    required this.dailyExpense,
    required this.byCategory,
    required this.categoryColors,
    required this.categoryIds,
    required this.opening,
    required this.closing,
  });

  final double income;
  final double expense;
  final int count;

  /// Índice 0 é o dia 1 do mês.
  final List<double> dailyIncome;
  final List<double> dailyExpense;

  final Map<String, double> byCategory;
  final Map<String, int> categoryColors;
  final Map<String, String> categoryIds;

  final double opening;
  final double closing;

  double get balance => income - expense;

  double get dailyAverage {
    final days = dailyExpense.length;
    return days == 0 ? 0 : expense / days;
  }

  /// Diferença entre o saldo informado no extrato e o movimento lançado.
  double get missing => (closing - opening) - balance;

  String? get topCategory {
    if (byCategory.isEmpty) return null;
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  double get topCategoryValue {
    final key = topCategory;
    return key == null ? 0 : byCategory[key]!;
  }

  /// Patrimônio acumulado dia a dia, partindo do saldo inicial.
  List<double> get cumulative {
    final result = <double>[];
    var running = opening;
    for (var i = 0; i < dailyIncome.length; i++) {
      running += dailyIncome[i] - dailyExpense[i];
      result.add(running);
    }
    return result;
  }

  factory MonthStats.from({
    required DateTime month,
    required List<Tx> transactions,
    required MonthBudget budget,
    required String accountId,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final dailyIncome = List<double>.filled(daysInMonth, 0);
    final dailyExpense = List<double>.filled(daysInMonth, 0);
    final byCategory = <String, double>{};
    final categoryColors = <String, int>{};
    final categoryIds = <String, String>{};

    final isGeneral = accountId == kGeneralAccountId;

    var income = 0.0;
    var expense = 0.0;
    var count = 0;

    for (final tx in transactions) {
      if (!isGeneral && tx.accountId != accountId) continue;
      if (tx.isTransfer) continue;

      count++;
      final index = tx.date.day - 1;
      if (index < 0 || index >= daysInMonth) continue;

      if (tx.isIncome) {
        income += tx.amount;
        dailyIncome[index] += tx.amount;
      } else {
        expense += tx.amount;
        dailyExpense[index] += tx.amount;
        byCategory[tx.categoryName] =
            (byCategory[tx.categoryName] ?? 0) + tx.amount;
        categoryColors[tx.categoryName] = tx.categoryColor.toARGB32();
        categoryIds[tx.categoryName] = tx.categoryId;
      }
    }

    final opening = isGeneral
        ? realAccountIds.fold<double>(0, (sum, id) => sum + budget.opening(id))
        : budget.opening(accountId);

    final closing = isGeneral
        ? realAccountIds.fold<double>(0, (sum, id) => sum + budget.closing(id))
        : budget.closing(accountId);

    return MonthStats(
      income: income,
      expense: expense,
      count: count,
      dailyIncome: dailyIncome,
      dailyExpense: dailyExpense,
      byCategory: byCategory,
      categoryColors: categoryColors,
      categoryIds: categoryIds,
      opening: opening,
      closing: closing,
    );
  }
}