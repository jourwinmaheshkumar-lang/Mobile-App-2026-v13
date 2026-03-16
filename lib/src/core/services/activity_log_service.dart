import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();
  factory ActivityLogService() => _instance;
  ActivityLogService._internal();

  final CollectionReference _collection = 
      FirebaseFirestore.instance.collection('activity_logs');

  Stream<List<ActivityLog>> get activityStream {
    return _collection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromDoc(doc))
          .where((log) => log.action != ActivityAction.sync)
          .toList();
    });
  }

  Future<void> log({
    required ActivityAction action,
    required EntityType entityType,
    required String entityName,
    String? entityId,
    required String details,
  }) async {
    try {
      final log = ActivityLog(
        id: '', // Firestore will handle this
        action: action,
        entityType: entityType,
        entityName: entityName,
        entityId: entityId,
        timestamp: DateTime.now(),
        details: details,
      );
      await _collection.add(log.toMap());
    } catch (e) {
      print('Error creating activity log: $e');
    }
  }

  Future<void> clearLogs() async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await _collection.get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

final activityLogService = ActivityLogService();
