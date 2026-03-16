import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCollection(String userId) => 
      _firestore.collection('users').doc(userId).collection('notifications');

  Future<void> notify({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? relatedEntityId,
    String? category,
    String? clickAction,
  }) async {
    try {
      final doc = _getCollection(userId).doc();
      final notification = NotificationModel(
        id: doc.id,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
        relatedEntityId: relatedEntityId,
        category: category,
        clickAction: clickAction,
      );
      await doc.set(notification.toMap());
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> notifyAllDirectors({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? relatedEntityId,
    String? category,
    String? clickAction,
  }) async {
    try {
      final directors = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      
      for (var doc in directors.docs) {
        final notifDoc = _firestore.collection('users').doc(doc.id).collection('notifications').doc();
        final notification = NotificationModel(
          id: notifDoc.id,
          title: title,
          message: message,
          timestamp: DateTime.now(),
          type: type,
          relatedEntityId: relatedEntityId,
          category: category,
          clickAction: clickAction,
        );
        batch.set(notifDoc, notification.toMap());
      }
      await batch.commit();
    } catch (e) {
      print('Error sending broad notification: $e');
    }
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _getCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NotificationModel.fromDoc(doc)).toList());
  }

  Stream<int> getUnreadCount(String userId) {
    return _getCollection(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> getUnreadCountByCategory(String userId, String category) {
    return _getCollection(userId)
        .where('isRead', isEqualTo: false)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _getCollection(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snap = await _getCollection(userId).where('isRead', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markAllAsReadByCategory(String userId, String category) async {
    final snap = await _getCollection(userId)
        .where('isRead', isEqualTo: false)
        .where('category', isEqualTo: category)
        .get();
        
    if (snap.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> clearAll(String userId) async {
    final snap = await _getCollection(userId).get();
    if (snap.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

final notificationService = NotificationService();
