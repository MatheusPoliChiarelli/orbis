import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/default_routine.dart';
import '../models/routine_block.dart';
import 'auth_service.dart';
import '../utils/formatters.dart';

class RoutineService {
  RoutineService._();

  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = AuthService.currentUser!.uid;
    return _db.collection('users').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> get _blocks =>
      _userDoc.collection('routineBlocks');

  static CollectionReference<Map<String, dynamic>> get _logs =>
      _userDoc.collection('routineLogs');

  static Stream<List<RoutineBlock>> watchBlocks() {
    return _blocks.snapshots().map(
          (snap) => snap.docs.map(RoutineBlock.fromDoc).toList()
            ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes)),
        );
  }

  static Stream<Map<String, RoutineLog>> watchWeekLogs(DateTime weekStart) {
    final start = dayKey(weekStart);
    final end = dayKey(weekStart.add(const Duration(days: 6)));

    return _logs
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: start)
        .where(FieldPath.documentId, isLessThanOrEqualTo: end)
        .snapshots()
        .map(
          (snap) => {
            for (final doc in snap.docs) doc.id: RoutineLog.fromDoc(doc),
          },
        );
  }

  static Stream<RoutineLog> watchLog(String dayKey) {
    return _logs.doc(dayKey).snapshots().map(
          (doc) => doc.exists ? RoutineLog.fromDoc(doc) : RoutineLog.empty(dayKey),
        );
  }

  static Future<void> addBlock(RoutineBlock block) async {
    await _blocks.add(block.toMap());
  }

  static Future<void> updateBlock(RoutineBlock block) async {
    await _blocks.doc(block.id).update(block.toMap());
  }

  static Future<void> deleteBlock(String id) async {
    await _blocks.doc(id).delete();
  }

  static Future<void> toggleDone({
    required String dayKey,
    required String blockId,
    required bool done,
  }) async {
    await _logs.doc(dayKey).set(
      {
        'done': {blockId: done},
      },
      SetOptions(merge: true),
    );
  }

  /// Grava o template da planilha. Só roda se ainda não houver blocos.
  static Future<void> seedDefaults() async {
    final existing = await _blocks.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final block in buildDefaultRoutine()) {
      batch.set(_blocks.doc(), block.toMap());
    }
    await batch.commit();
  }
}