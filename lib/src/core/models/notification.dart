import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? relatedEntityId;
  final String? category; // 'form', 'director', 'general'
  final String? clickAction; // e.g., 'open_form_list', 'open_form_filler'

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = NotificationType.info,
    this.relatedEntityId,
    this.category,
    this.clickAction,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.name,
      'relatedEntityId': relatedEntityId,
      'category': category,
      'clickAction': clickAction,
    };
  }

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.info,
      ),
      relatedEntityId: data['relatedEntityId'],
      category: data['category'],
      clickAction: data['clickAction'],
    );
  }
}
