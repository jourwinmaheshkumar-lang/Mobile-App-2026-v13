import 'package:cloud_firestore/cloud_firestore.dart';

enum SelectionMode { single, multi }

class ReportCategory {
  final String id;
  final String name;
  final List<String> directorIds;
  final int order;

  ReportCategory({
    required this.id,
    required this.name,
    this.directorIds = const [],
    this.order = 0,
  });

  int get count => directorIds.length;

  ReportCategory copyWith({
    String? id,
    String? name,
    List<String>? directorIds,
    int? order,
  }) {
    return ReportCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      directorIds: directorIds ?? this.directorIds,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'directorIds': directorIds,
      'order': order,
    };
  }

  factory ReportCategory.fromMap(Map<String, dynamic> map) {
    return ReportCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      directorIds: List<String>.from(map['directorIds'] ?? []),
      order: map['order'] ?? 0,
    );
  }
}

class Report {
  final String id;
  final String title;
  final SelectionMode selectionMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReportCategory> categories;

  Report({
    required this.id,
    required this.title,
    required this.selectionMode,
    required this.createdAt,
    required this.updatedAt,
    this.categories = const [],
  });

  // Get all assigned director IDs across all categories
  Set<String> get allAssignedDirectorIds {
    final Set<String> ids = {};
    for (var cat in categories) {
      ids.addAll(cat.directorIds);
    }
    return ids;
  }

  // Get total directors count
  int get totalDirectorsCount {
    if (selectionMode == SelectionMode.single) {
      return allAssignedDirectorIds.length;
    } else {
      // For multi-selection, count all assignments
      int count = 0;
      for (var cat in categories) {
        count += cat.directorIds.length;
      }
      return count;
    }
  }

  Report copyWith({
    String? id,
    String? title,
    SelectionMode? selectionMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReportCategory>? categories,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      selectionMode: selectionMode ?? this.selectionMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'selectionMode': selectionMode == SelectionMode.single ? 'single' : 'multi',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  factory Report.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      title: data['title'] ?? '',
      selectionMode: data['selectionMode'] == 'single' 
          ? SelectionMode.single 
          : SelectionMode.multi,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categories: (data['categories'] as List<dynamic>?)
          ?.map((c) => ReportCategory.fromMap(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
