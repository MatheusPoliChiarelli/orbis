import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/month_budget.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'auth_service.dart';
import '../models/fixed_cost.dart';

class FinanceService {
  FinanceService._();

  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = AuthService.currentUser!.uid;
    return _db.collection('users').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> get _fixedCosts =>
      _userDoc.collection('fixedCosts');

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

  static Stream<List<Tx>> watchYearTransactions(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    return _transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) => snap.docs.map(Tx.fromDoc).toList());
  }

  static Stream<List<MonthBudget>> watchYearBudgets(int year) {
    return _budgets
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$year-01')
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$year-12')
        .snapshots()
        .map((snap) => snap.docs.map(MonthBudget.fromDoc).toList());
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

  
  static Stream<List<FixedCost>> watchFixedCosts() {
    return _fixedCosts
        .snapshots()
        .map((snap) => snap.docs.map(FixedCost.fromDoc).toList());
  }

  static Future<void> addFixedCost(FixedCost item) async {
    await _fixedCosts.add(item.toMap());
  }

  static Future<void> updateFixedCost(FixedCost item) async {
    await _fixedCosts.doc(item.id).update(item.toMap());
  }

  static Future<void> deleteFixedCost(String id) async {
    final children =
        await _fixedCosts.where('parentId', isEqualTo: id).get();

    final batch = _db.batch();
    for (final doc in children.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_fixedCosts.doc(id));
    await batch.commit();
  }



}