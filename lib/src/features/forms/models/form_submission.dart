import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionStatus {
  draft,
  completed,
  approved,
  rejected,
}

class FormSubmissionModel {
  final String id;
  final String formId;
  final String userId;
  final String? userName;
  final Map<String, dynamic> responses;
  final DateTime submittedAt;
  final DateTime lastModified;
  final SubmissionStatus status;
  final String? rejectedBy; // Name and DIN of the person who rejected it
  final String? rejectionReason;
  final int rejectionCount;
  final String? filledByUserId;
  final String? filledByUserName;
  final List<String>? lastChangedFields;

  FormSubmissionModel({
    required this.id,
    required this.formId,
    required this.userId,
    this.userName,
    required this.responses,
    required this.submittedAt,
    required this.lastModified,
    this.status = SubmissionStatus.completed,
    this.rejectedBy,
    this.rejectionReason,
    this.rejectionCount = 0,
    this.filledByUserId,
    this.filledByUserName,
    this.lastChangedFields,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'formId': formId,
      'userId': userId,
      'userName': userName,
      'responses': responses,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'lastModified': Timestamp.fromDate(lastModified),
      'status': status.name,
      'rejectedBy': rejectedBy,
      'rejectionReason': rejectionReason,
      'rejectionCount': rejectionCount,
      'filledByUserId': filledByUserId,
      'filledByUserName': filledByUserName,
      'lastChangedFields': lastChangedFields,
    };
  }

  factory FormSubmissionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormSubmissionModel(
      id: doc.id,
      formId: data['formId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'],
      responses: Map<String, dynamic>.from(data['responses'] ?? {}),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate() ?? (data['submittedAt'] as Timestamp).toDate(),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SubmissionStatus.completed,
      ),
      rejectedBy: data['rejectedBy'],
      rejectionReason: data['rejectionReason'],
      rejectionCount: data['rejectionCount'] ?? 0,
      filledByUserId: data['filledByUserId'],
      filledByUserName: data['filledByUserName'],
      lastChangedFields: data['lastChangedFields'] != null ? List<String>.from(data['lastChangedFields']) : null,
    );
  }

  FormSubmissionModel copyWith({
    String? id,
    Map<String, dynamic>? responses,
    SubmissionStatus? status,
    DateTime? lastModified,
    String? rejectedBy,
    String? rejectionReason,
    int? rejectionCount,
    String? filledByUserId,
    String? filledByUserName,
    List<String>? lastChangedFields,
  }) {
    return FormSubmissionModel(
      id: id ?? this.id,
      formId: formId,
      userId: userId,
      userName: userName,
      responses: responses ?? this.responses,
      submittedAt: submittedAt,
      lastModified: lastModified ?? this.lastModified,
      status: status ?? this.status,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectionCount: rejectionCount ?? this.rejectionCount,
      filledByUserId: filledByUserId ?? this.filledByUserId,
      filledByUserName: filledByUserName ?? this.filledByUserName,
      lastChangedFields: lastChangedFields ?? this.lastChangedFields,
    );
  }
}
