import 'package:cloud_firestore/cloud_firestore.dart';

class FixedCost {
  const FixedCost({
    required this.id,
    required this.name,
    required this.amount,
    required this.startMonth,
    required this.endMonth,
    this.parentId,
    this.order = 0,
  });

  final String id;
  final String name;
  final double amount;

  /// Formato "2026-01". Nulo significa desde sempre.
  final String? startMonth;

  /// Formato "2026-06". Nulo significa sem data de fim.
  final String? endMonth;

  /// Quando preenchido, este item é uma assinatura dentro de uma fatura.
  final String? parentId;

  final int order;

  bool get isChild => parentId != null;

  /// Verdadeiro se o item existe no mês informado.
  bool activeIn(String key) {
    if (startMonth != null && key.compareTo(startMonth!) < 0) return false;
    if (endMonth != null && key.compareTo(endMonth!) > 0) return false;
    return true;
  }

  factory FixedCost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FixedCost(
      id: doc.id,
      name: data['name'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      startMonth: data['startMonth'] as String?,
      endMonth: data['endMonth'] as String?,
      parentId: data['parentId'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'startMonth': startMonth,
      'endMonth': endMonth,
      'parentId': parentId,
      'order': order,
    };
  }

  FixedCost copyWith({
    String? name,
    double? amount,
    String? startMonth,
    String? endMonth,
    String? parentId,
    int? order,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearParent = false,
  }) {
    return FixedCost(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startMonth: clearStart ? null : (startMonth ?? this.startMonth),
      endMonth: clearEnd ? null : (endMonth ?? this.endMonth),
      parentId: clearParent ? null : (parentId ?? this.parentId),
      order: order ?? this.order,
    );
  }
}

/// Agrupa os itens do mês e calcula o total, respeitando os compostos.
class FixedCostMonth {
  const FixedCostMonth({
    required this.monthKey,
    required this.parents,
    required this.childrenByParent,
  });

  final String monthKey;
  final List<FixedCost> parents;
  final Map<String, List<FixedCost>> childrenByParent;

  /// Uma fatura vale a soma das assinaturas dentro dela.
  double amountOf(FixedCost item) {
    final children = childrenByParent[item.id];
    if (children == null || children.isEmpty) return item.amount;
    return children.fold<double>(0, (sum, child) => sum + child.amount);
  }

  double get total {
    return parents.fold<double>(0, (sum, item) => sum + amountOf(item));
  }

  factory FixedCostMonth.build({
    required String monthKey,
    required List<FixedCost> all,
  }) {
    final active = all.where((item) => item.activeIn(monthKey)).toList();

    final parents = active.where((item) => !item.isChild).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });

    final childrenByParent = <String, List<FixedCost>>{};
    for (final item in active.where((item) => item.isChild)) {
      childrenByParent.putIfAbsent(item.parentId!, () => []).add(item);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    }

    return FixedCostMonth(
      monthKey: monthKey,
      parents: parents,
      childrenByParent: childrenByParent,
    );
  }
}