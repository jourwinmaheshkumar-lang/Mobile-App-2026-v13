import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Represents a director's role/posting within a project.
class ProjectDirector {
  final String directorId;
  final String directorName;
  final String role; // 'special', 'leading', 'normal'
  final String? designation; // For normal directors
  final String? posting; // For normal directors

  ProjectDirector({
    required this.directorId,
    required this.directorName,
    required this.role,
    this.designation,
    this.posting,
  });

  Map<String, dynamic> toMap() {
    return {
      'directorId': directorId,
      'directorName': directorName,
      'role': role,
      'designation': designation,
      'posting': posting,
    };
  }

  factory ProjectDirector.fromMap(Map<String, dynamic> map) {
    return ProjectDirector(
      directorId: map['directorId'] ?? '',
      directorName: map['directorName'] ?? '',
      role: map['role'] ?? 'normal',
      designation: map['designation'],
      posting: map['posting'],
    );
  }
}

/// Represents a project in the system.
class Project {
  final String id;
  final String title;
  final String category;
  final String details;
  final String? projectValue;
  final List<ProjectDirector> directors;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> locations;

  Project({
    required this.id,
    required this.title,
    required this.category,
    required this.details,
    this.projectValue,
    this.directors = const [],
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.locations = const [],
  });

  /// Get special directors for this project
  List<ProjectDirector> get specialDirectors =>
      directors.where((d) => d.role == 'special').toList();

  /// Get leading directors for this project
  List<ProjectDirector> get leadingDirectors =>
      directors.where((d) => d.role == 'leading').toList();

  /// Get normal directors for this project
  List<ProjectDirector> get normalDirectors =>
      directors.where((d) => d.role == 'normal').toList();

  /// Get project value formatted as Indian currency (INR)
  String get formattedValue {
    if (projectValue == null || projectValue!.isEmpty) return '';

    // Try to parse numerical value
    try {
      // Remove any existing currency symbols and separators
      final cleanValue = projectValue!.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanValue.isEmpty) return projectValue!;

      final value = double.parse(cleanValue);
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      return formatter.format(value);
    } catch (e) {
      return projectValue!;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'details': details,
      'projectValue': projectValue,
      'directors': directors.map((d) => d.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'locations': locations,
    };
  }

  factory Project.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<ProjectDirector> directors = [];
    if (data['directors'] != null && data['directors'] is List) {
      directors = (data['directors'] as List)
          .map((d) => ProjectDirector.fromMap(d as Map<String, dynamic>))
          .toList();
    }

    return Project(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      details: data['details'] ?? '',
      projectValue: data['projectValue'],
      directors: directors,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      locations: data['locations'] != null ? List<String>.from(data['locations']) : const [],
    );
  }

  Project copyWith({
    String? title,
    String? category,
    String? details,
    String? projectValue,
    List<ProjectDirector>? directors,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? locations,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      details: details ?? this.details,
      projectValue: projectValue ?? this.projectValue,
      directors: directors ?? this.directors,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locations: locations ?? this.locations,
    );
  }
}
