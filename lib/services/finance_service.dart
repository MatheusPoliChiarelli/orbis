import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/month_budget.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'auth_service.dart';

class FinanceService {
  FinanceService._();

  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = AuthService.currentUser!.uid;
    return _db.collection('users').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> get _transactions =>
      _userDoc.collection('transactions');

  static CollectionReference<Map<String, dynamic>> get _budgets =>
      _userDoc.collection('budgets');

  static Stream<List<Tx>> watchMonthTransactions(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) => snap.docs.map(Tx.fromDoc).toList());
  }

  static Stream<MonthBudget> watchMonthBudget(DateTime month) {
    final key = monthKey(month);
    return _budgets.doc(key).snapshots().map(
          (doc) => doc.exists ? MonthBudget.fromDoc(doc) : MonthBudget.empty(key),
        );
  }

  static Future<void> addTransaction(Tx tx) async {
    await _transactions.add(tx.toMap());
  }

  static Future<void> updateTransaction(Tx tx) async {
    await _transactions.doc(tx.id).update(tx.toMap());
  }

  static Future<void> deleteTransaction(String id) async {
    await _transactions.doc(id).delete();
  }

  static Future<void> setOpeningBalance({
    required DateTime month,
    required String accountId,
    required double value,
  }) async {
    await _budgets.doc(monthKey(month)).set(
      {
        'openingBalances': {accountId: value},
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> setClosingBalance({
    required DateTime month,
    required String accountId,
    required double value,
  }) async {
    await _budgets.doc(monthKey(month)).set(
      {
        'closingBalances': {accountId: value},
      },
      SetOptions(merge: true),
    );
  }
}