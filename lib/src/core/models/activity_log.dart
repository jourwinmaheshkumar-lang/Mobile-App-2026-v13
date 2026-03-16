import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityAction {
  create,
  update,
  delete,
  restore,
  permanentDelete,
  export,
  sync,
}

enum EntityType {
  director,
  report,
  campaign,
  system,
  form,
}

class ActivityLog {
  final String id;
  final ActivityAction action;
  final EntityType entityType;
  final String entityName;
  final String? entityId;
  final DateTime timestamp;
  final String details;
  final String userId;

  ActivityLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityName,
    this.entityId,
    required this.timestamp,
    required this.details,
    this.userId = 'Admin',
  });

  factory ActivityLog.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Support both full enum string and simple string
    ActivityAction parseAction(String? value) {
      if (value == null) return ActivityAction.update;
      return ActivityAction.values.firstWhere(
        (e) => e.toString() == value || e.name == value,
        orElse: () => ActivityAction.update,
      );
    }

    EntityType parseEntityType(String? value) {
      if (value == null) return EntityType.system;
      return EntityType.values.firstWhere(
        (e) => e.toString() == value || e.name == value,
        orElse: () => EntityType.system,
      );
    }

    return ActivityLog(
      id: doc.id,
      action: parseAction(data['action']),
      entityType: parseEntityType(data['entityType']),
      entityName: data['entityName'] ?? '',
      entityId: data['entityId'],
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      details: data['details'] ?? '',
      userId: data['userId'] ?? 'Admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action.toString(),
      'entityType': entityType.toString(),
      'entityName': entityName,
      'entityId': entityId,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
      'userId': userId,
    };
  }
}
