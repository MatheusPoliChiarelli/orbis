import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/habit.dart';
import 'auth_service.dart';
import '../models/habit.dart';

class HabitService {
  HabitService._();

  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = AuthService.currentUser!.uid;
    return _db.collection('users').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> get _habits =>
      _userDoc.collection('habits');

  static CollectionReference<Map<String, dynamic>> get _logs =>
      _userDoc.collection('habitLogs');

  static Stream<List<Habit>> watchHabits() {
    return _habits.snapshots().map(
          (snap) => snap.docs.map(Habit.fromDoc).toList()
            ..sort((a, b) {
              final byOrder = a.order.compareTo(b.order);
              return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
            }),
        );
  }

  static Stream<HabitLog> watchLog(String monthKey) {
    return _logs.doc(monthKey).snapshots().map(
          (doc) => doc.exists ? HabitLog.fromDoc(doc) : HabitLog.empty(monthKey),
        );
  }

  static Future<void> addHabit(Habit habit) async {
    await _habits.add(habit.toMap());
  }

  static Future<void> updateHabit(Habit habit) async {
    await _habits.doc(habit.id).update(habit.toMap());
  }

  static Future<void> deleteHabit(String id) async {
    await _habits.doc(id).delete();
  }

  static Future<void> setMark({
    required String monthKey,
    required String habitId,
    required int day,
    required HabitMark mark,
  }) async {
    await _logs.doc(monthKey).set(
      {
        'marks': {'$habitId:$day': mark.name},
      },
      SetOptions(merge: true),
    );
  }
}