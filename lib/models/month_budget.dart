import 'package:cloud_firestore/cloud_firestore.dart';

class MonthBudget {
  const MonthBudget({
    required this.monthKey,
    required this.openingBalances,
    required this.closingBalances,
  });

  final String monthKey;
  final Map<String, double> openingBalances;
  final Map<String, double> closingBalances;

  double opening(String accountId) => openingBalances[accountId] ?? 0;
  double closing(String accountId) => closingBalances[accountId] ?? 0;

  factory MonthBudget.empty(String key) {
    return MonthBudget(
      monthKey: key,
      openingBalances: const {},
      closingBalances: const {},
    );
  }

  factory MonthBudget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MonthBudget(
      monthKey: doc.id,
      openingBalances: _readMap(data['openingBalances']),
      closingBalances: _readMap(data['closingBalances']),
    );
  }

  static Map<String, double> _readMap(Object? raw) {
    if (raw is! Map) return <String, double>{};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as num?)?.toDouble() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'openingBalances': openingBalances,
      'closingBalances': closingBalances,
    };
  }
}