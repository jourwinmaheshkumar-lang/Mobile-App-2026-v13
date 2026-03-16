import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_field.dart';

class FormModel {
  final String id;
  final String title;
  final String description;
  final List<FormFieldModel> fields;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? deadline;
  final bool isActive;
  final bool allowProxySubmission;

  FormModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
    required this.createdBy,
    required this.createdAt,
    this.startDate,
    this.deadline,
    this.isActive = true,
    this.allowProxySubmission = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fields': fields.map((f) => f.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'isActive': isActive,
      'allowProxySubmission': allowProxySubmission,
    };
  }

  factory FormModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fields: (data['fields'] as List? ?? [])
          .map((f) => FormFieldModel.fromMap(f as Map<String, dynamic>))
          .toList(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      allowProxySubmission: data['allowProxySubmission'] ?? false,
    );
  }

  FormModel copyWith({
    String? title,
    String? description,
    List<FormFieldModel>? fields,
    DateTime? startDate,
    DateTime? deadline,
    bool? isActive,
    bool? allowProxySubmission,
  }) {
    return FormModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      fields: fields ?? this.fields,
      createdBy: createdBy,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      isActive: isActive ?? this.isActive,
      allowProxySubmission: allowProxySubmission ?? this.allowProxySubmission,
    );
  }
}
