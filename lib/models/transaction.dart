import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TxType { income, expense, transfer }

class Tx {
  const Tx({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.accountId,
    this.toAccountId,
    this.createdAt,
  });

  final String id;
  final double amount;
  final TxType type;
  final DateTime date;
  final String description;
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final String accountId;
  final String? toAccountId;
  final DateTime? createdAt;

  bool get isTransfer => type == TxType.transfer;
  bool get isIncome => type == TxType.income;
  bool get isExpense => type == TxType.expense;

  factory Tx.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Tx(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: TxType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => TxType.expense,
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      categoryColor: Color(data['categoryColor'] as int? ?? 0xFF9AA1A8),
      accountId: data['accountId'] as String? ?? '',
      toAccountId: data['toAccountId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type.name,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryColor': categoryColor.toARGB32(),
      'accountId': accountId,
      'toAccountId': toAccountId,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  Tx copyWith({
    double? amount,
    TxType? type,
    DateTime? date,
    String? description,
    String? categoryId,
    String? categoryName,
    Color? categoryColor,
    String? accountId,
    String? toAccountId,
  }) {
    return Tx(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      createdAt: createdAt,
    );
  }
}