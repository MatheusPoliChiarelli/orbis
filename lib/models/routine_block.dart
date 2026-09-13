import 'package:cloud_firestore/cloud_firestore.dart';

enum DayType { weekday, saturday, sunday }

extension DayTypeLabel on DayType {
  String get label {
    return switch (this) {
      DayType.weekday => 'Dias úteis',
      DayType.saturday => 'Sábado',
      DayType.sunday => 'Domingo',
    };
  }
}

DayType _parseDayType(Object? raw) {
  return switch (raw) {
    'saturday' => DayType.saturday,
    'sunday' || 'sundayN' || 'sundayD' => DayType.sunday,
    _ => DayType.weekday,
  };
}

class RoutineBlock {
  const RoutineBlock({
    required this.id,
    required this.dayType,
    required this.startMinutes,
    required this.endMinutes,
    required this.label,
    this.weekdays = const [],
    this.order = 0,
  });

  final String id;
  final DayType dayType;

  /// Minutos desde a meia-noite. 4:00 é 240.
  final int startMinutes;
  final int endMinutes;

  final String label;

  /// Quando vazio, vale em todos os dias do tipo. 1 é segunda, 5 é sexta.
  final List<int> weekdays;

  final int order;

  String get startLabel => format(startMinutes);
  String get endLabel => format(endMinutes);
  String get rangeLabel => '$startLabel às $endLabel';

  /// Duração em minutos, tratando blocos que cruzam a meia-noite.
  int get duration {
    final raw = endMinutes - startMinutes;
    return raw >= 0 ? raw : raw + 24 * 60;
  }

  bool appliesTo(int weekday) {
    if (weekdays.isEmpty) return true;
    return weekdays.contains(weekday);
  }

  /// Verdadeiro se o horário informado cai dentro do bloco.
  bool containsMinute(int minute) {
    if (endMinutes >= startMinutes) {
      return minute >= startMinutes && minute < endMinutes;
    }
    return minute >= startMinutes || minute < endMinutes;
  }

  static String format(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  factory RoutineBlock.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return RoutineBlock(
      id: doc.id,
      dayType: _parseDayType(data['dayType']),
      startMinutes: (data['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (data['endMinutes'] as num?)?.toInt() ?? 0,
      label: data['label'] as String? ?? '',
      weekdays: (data['weekdays'] as List?)
              ?.map((v) => (v as num).toInt())
              .toList() ??
          const [],
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayType': dayType.name,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'label': label,
      'weekdays': weekdays,
      'order': order,
    };
  }

  RoutineBlock copyWith({
    DayType? dayType,
    int? startMinutes,
    int? endMinutes,
    String? label,
    List<int>? weekdays,
    int? order,
  }) {
    return RoutineBlock(
      id: id,
      dayType: dayType ?? this.dayType,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      label: label ?? this.label,
      weekdays: weekdays ?? this.weekdays,
      order: order ?? this.order,
    );
  }
}

/// Conclusões de um dia, no formato "blockId": true.
class RoutineLog {
  const RoutineLog({required this.dayKey, required this.done});

  final String dayKey;
  final Map<String, bool> done;

  bool isDone(String blockId) => done[blockId] == true;

  int get doneCount => done.values.where((v) => v).length;

  factory RoutineLog.empty(String key) {
    return RoutineLog(dayKey: key, done: const {});
  }

  factory RoutineLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final raw = data['done'];
    if (raw is! Map) return RoutineLog.empty(doc.id);

    return RoutineLog(
      dayKey: doc.id,
      done: raw.map((key, value) => MapEntry(key.toString(), value == true)),
    );
  }
}