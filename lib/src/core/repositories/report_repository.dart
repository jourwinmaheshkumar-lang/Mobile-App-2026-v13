import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../services/activity_log_service.dart';
import '../models/activity_log.dart';

class ReportRepository {
  static final ReportRepository _instance = ReportRepository._internal();
  factory ReportRepository() => _instance;
  ReportRepository._internal();

  CollectionReference get _collection => 
      FirebaseFirestore.instance.collection('reports');

  List<Report> _localCache = [];

  // Stream of all reports
  Stream<List<Report>> get reportsStream {
    return _collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      _localCache = snapshot.docs.map((doc) => Report.fromDoc(doc)).toList();
      return _localCache;
    });
  }

  List<Report> get all => _localCache;

  // Create a new report
  Future<Report?> create({
    required String title,
    required SelectionMode selectionMode,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _collection.doc();
      
      final report = Report(
        id: docRef.id,
        title: title,
        selectionMode: selectionMode,
        createdAt: now,
        updatedAt: now,
        categories: [],
      );

      await docRef.set(report.toMap());
      // Log asynchronously to avoid blocking the UI if logging fails
      activityLogService.log(
        action: ActivityAction.create,
        entityType: EntityType.report,
        entityName: title,
        entityId: docRef.id,
        details: 'Created new campaign report',
      );
      return report;
    } catch (e) {
      print('Error creating report: $e');
      return null;
    }
  }

  // Update a report
  Future<void> update(Report report) async {
    try {
      await _collection.doc(report.id).update({
        ...report.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating report: $e');
    }
  }

  // Delete a report
  Future<void> delete(String id) async {
    try {
      final report = await getById(id);
      await _collection.doc(id).delete();
      if (report != null) {
        // Log asynchronously
        activityLogService.log(
          action: ActivityAction.delete,
          entityType: EntityType.report,
          entityName: report.title,
          entityId: id,
          details: 'Deleted campaign report',
        );
      }
    } catch (e) {
      print('Error deleting report: $e');
    }
  }

  // Get a single report by ID
  Future<Report?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return Report.fromDoc(doc);
    }
    return null;
  }

  // Add a category to a report
  Future<void> addCategory(String reportId, ReportCategory category) async {
    final report = await getById(reportId);
    if (report == null) return;

    final updatedCategories = [...report.categories, category];
    await _collection.doc(reportId).update({
      'categories': updatedCategories.map((c) => c.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update a category in a report
  Future<void> updateCategory(String reportId, ReportCategory category) async {
    final report = await getById(reportId);
    if (report == null) return;

    final updatedCategories = report.categories.map((c) {
      if (c.id == category.id) return category;
      return c;
    }).toList();

    await _collection.doc(reportId).update({
      'categories': updatedCategories.map((c) => c.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete a category from a report
  Future<void> deleteCategory(String reportId, String categoryId) async {
    final report = await getById(reportId);
    if (report == null) return;

    final updatedCategories = report.categories
        .where((c) => c.id != categoryId)
        .toList();

    await _collection.doc(reportId).update({
      'categories': updatedCategories.map((c) => c.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Save updated categories order
  Future<void> saveCategoriesOrder(String reportId, List<ReportCategory> categories) async {
    await _collection.doc(reportId).update({
      'categories': categories.map((c) => c.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Assign a director to a category
  Future<void> assignDirector({
    required String reportId,
    required String categoryId,
    required String directorId,
    required SelectionMode mode,
  }) async {
    final report = await getById(reportId);
    if (report == null) return;

    List<ReportCategory> updatedCategories;

    if (mode == SelectionMode.single) {
      // Remove director from all other categories first
      updatedCategories = report.categories.map((c) {
        if (c.id == categoryId) {
          // Add to this category
          if (!c.directorIds.contains(directorId)) {
            return c.copyWith(directorIds: [...c.directorIds, directorId]);
          }
          return c;
        } else {
          // Remove from other categories
          return c.copyWith(
            directorIds: c.directorIds.where((id) => id != directorId).toList(),
          );
        }
      }).toList();
    } else {
      // Multi-selection: just add to the specified category
      updatedCategories = report.categories.map((c) {
        if (c.id == categoryId && !c.directorIds.contains(directorId)) {
          return c.copyWith(directorIds: [...c.directorIds, directorId]);
        }
        return c;
      }).toList();
    }

    await _collection.doc(reportId).update({
      'categories': updatedCategories.map((c) => c.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Remove a director from a category
  Future<void> removeDirector({
    required String reportId,
    required String categoryId,
    required String directorId,
  }) async {
    final report = await getById(reportId);
    if (report == null) return;

    final updatedCategories = report.categories.map((c) {
      if (c.id == categoryId) {
        return c.copyWith(
          directorIds: c.directorIds.where((id) => id != directorId).toList(),
        );
      }
      return c;
    }).toList();

    await _collection.doc(reportId).update({
      'categories': updatedCategories.map((c) => c.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
