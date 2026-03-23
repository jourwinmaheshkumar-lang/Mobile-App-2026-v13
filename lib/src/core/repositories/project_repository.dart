import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import '../models/notification.dart';
import '../services/activity_log_service.dart';
import '../models/activity_log.dart';
import '../services/notification_service.dart';

class ProjectRepository {
  static final ProjectRepository _instance = ProjectRepository._internal();
  factory ProjectRepository() => _instance;
  ProjectRepository._internal();

  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('projects');

  /// Stream of all projects ordered by creation date (newest first)
  Stream<List<Project>> get projectsStream {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Project.fromDoc(doc)).toList();
    });
  }

  /// Stream of a single project by ID
  Stream<Project?> projectStream(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return Project.fromDoc(doc);
      }
      return null;
    });
  }

  /// Get a single project by ID
  Future<Project?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return Project.fromDoc(doc);
      }
    } catch (e) {
      print('Error fetching project: $e');
    }
    return null;
  }

  /// Create a new project
  Future<String> create(Project project) async {
    try {
      final doc = _collection.doc();
      final newProject = Project(
        id: doc.id,
        title: project.title,
        category: project.category,
        details: project.details,
        projectValue: project.projectValue,
        directors: project.directors,
        createdBy: project.createdBy,
        createdAt: DateTime.now(),
        locations: project.locations,
      );
      await doc.set(newProject.toMap());

      // Log the activity
      await activityLogService.log(
        action: ActivityAction.create,
        entityType: EntityType.project,
        entityName: project.title,
        entityId: doc.id,
        details: 'Created new project: ${project.title}',
      );

      // Notify all users
      await notificationService.notifyAllDirectors(
        title: '📋 New Project Created',
        message: 'A new project "${project.title}" has been created under ${project.category}.',
        type: NotificationType.info,
        relatedEntityId: doc.id,
        category: 'project',
        clickAction: 'open_project',
      );

      return doc.id;
    } catch (e) {
      print('Error creating project: $e');
      rethrow;
    }
  }

  /// Update an existing project
  Future<void> update(Project project) async {
    try {
      final updatedProject = project.copyWith(updatedAt: DateTime.now());
      await _collection.doc(project.id).update(updatedProject.toMap());

      await activityLogService.log(
        action: ActivityAction.update,
        entityType: EntityType.project,
        entityName: project.title,
        entityId: project.id,
        details: 'Updated project: ${project.title}',
      );
    } catch (e) {
      print('Error updating project: $e');
      rethrow;
    }
  }

  /// Delete a project
  Future<void> delete(String id, String projectTitle) async {
    try {
      await _collection.doc(id).delete();

      await activityLogService.log(
        action: ActivityAction.delete,
        entityType: EntityType.project,
        entityName: projectTitle,
        entityId: id,
        details: 'Deleted project: $projectTitle',
      );
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  /// Get projects filtered by category
  Stream<List<Project>> getByCategory(String category) {
    return _collection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Project.fromDoc(doc)).toList();
    });
  }

  /// Search projects by title
  List<Project> search(List<Project> projects, String query) {
    if (query.isEmpty) return projects;
    final lowerQuery = query.toLowerCase();
    return projects.where((p) {
      return p.title.toLowerCase().contains(lowerQuery) ||
          p.category.toLowerCase().contains(lowerQuery) ||
          p.details.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

final projectRepository = ProjectRepository();
