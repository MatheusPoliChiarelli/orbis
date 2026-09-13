import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitFrequency { daily, weekly, monthly }

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.frequency,
    required this.active,
    this.group,
    this.order = 0,
  });

  final String id;
  final String name;
  final HabitFrequency frequency;
  final bool active;

  /// Agrupamento visual, por exemplo "Concurso".
  final String? group;

  final int order;

  String get frequencyLabel {
    return switch (frequency) {
      HabitFrequency.daily => 'Diário',
      HabitFrequency.weekly => 'Semanal',
      HabitFrequency.monthly => 'Mensal',
    };
  }

  factory Habit.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Habit(
      id: doc.id,
      name: data['name'] as String? ?? '',
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == data['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      active: data['active'] as bool? ?? true,
      group: data['group'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'frequency': frequency.name,
      'active': active,
      'group': group,
      'order': order,
    };
  }

  Habit copyWith({
    String? name,
    HabitFrequency? frequency,
    bool? active,
    String? group,
    int? order,
    bool clearGroup = false,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      active: active ?? this.active,
      group: clearGroup ? null : (group ?? this.group),
      order: order ?? this.order,
    );
  }
}

/// Marcações de um mês inteiro, no formato "habitId:dia".
enum HabitMark { none, done, missed, skipped }

/// Marcações de um mês inteiro, no formato "habitId:dia".
class HabitLog {
  const HabitLog({required this.monthKey, required this.marks});

  final String monthKey;
  final Map<String, String> marks;

  HabitMark markOf(String habitId, int day) {
    return switch (marks['$habitId:$day']) {
      'done' => HabitMark.done,
      'missed' => HabitMark.missed,
      'skipped' => HabitMark.skipped,
      _ => HabitMark.none,
    };
  }

  bool isDone(String habitId, int day) =>
      markOf(habitId, day) == HabitMark.done;

  factory HabitLog.empty(String key) {
    return HabitLog(monthKey: key, marks: const {});
  }

  factory HabitLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final raw = data['marks'];
    if (raw is! Map) return HabitLog.empty(doc.id);

    return HabitLog(
      monthKey: doc.id,
      marks: raw.map(
        (key, value) => MapEntry(
          key.toString(),
          value == true ? 'done' : value.toString(),
        ),
      ),
    );
  }

  /// Quantos dias do mês o hábito foi cumprido.
  int doneCount(String habitId, int daysInMonth) {
    var total = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      if (isDone(habitId, day)) total++;
    }
    return total;
  }

  /// Quantos dias foram cobrados, ou seja, não marcados como dispensados.
  int expectedCount(String habitId, int daysInMonth) {
    var total = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      if (markOf(habitId, day) != HabitMark.skipped) total++;
    }
    return total;
  }

  /// Sequência atual, contada de trás para frente a partir do dia de corte.
  /// Dias dispensados não quebram a sequência.
  int streak(String habitId, int upToDay) {
    var count = 0;
    for (var day = upToDay; day >= 1; day--) {
      final mark = markOf(habitId, day);
      if (mark == HabitMark.skipped) continue;
      if (mark != HabitMark.done) break;
      count++;
    }
    return count;
  }
}