import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/form_model.dart';
import '../models/form_submission.dart';

class FormRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Forms Collection
  CollectionReference get _formsCollection => _firestore.collection('forms');
  
  // Submissions Collection
  CollectionReference get _submissionsCollection => _firestore.collection('form_submissions');

  // Create or Update Form
  Future<void> saveForm(FormModel form) async {
    await _formsCollection.doc(form.id.isEmpty ? null : form.id).set(
      form.toMap(),
      SetOptions(merge: true),
    );
  }

  // Delete Form
  Future<void> deleteForm(String formId) async {
    await _formsCollection.doc(formId).delete();
    // Optionally delete all submissions associated with this form
    final submissions = await _submissionsCollection.where('formId', isEqualTo: formId).get();
    for (var doc in submissions.docs) {
      await doc.reference.delete();
    }
  }

  // Get Stream of Forms
  Stream<List<FormModel>> getFormsStream({bool activeOnly = false}) {
    // Fetch all forms and handle filtering/sorting in memory to avoid requiring composite indexes
    return _formsCollection.snapshots().map((snapshot) {
      final forms = snapshot.docs.map((doc) => FormModel.fromDoc(doc)).toList();
      
      // Filter if necessary
      final filtered = activeOnly 
          ? forms.where((f) => f.isActive).toList() 
          : forms;
          
      // Sort in memory by createdAt descending
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return filtered;
    });
  }

  // Get Single Form
  Future<FormModel?> getForm(String formId) async {
    final doc = await _formsCollection.doc(formId).get();
    if (doc.exists) {
      return FormModel.fromDoc(doc);
    }
    return null;
  }

  // Save Submission (Draft or Complete)
  Future<void> saveSubmission(FormSubmissionModel submission) async {
    // Enforce "One director to only one form" using a deterministic ID
    // format: {userId}_{formId}. This ensures only one document exists per user-form pair.
    final String docId = submission.id.isNotEmpty 
        ? submission.id 
        : '${submission.userId}_${submission.formId}';

    final docRef = _submissionsCollection.doc(docId);
    
    await docRef.set(
      submission.copyWith(id: docId).toMap(),
      SetOptions(merge: true),
    );
  }

  // Get User's Submission for a Specific Form
  Future<FormSubmissionModel?> getUserSubmission(String formId, String userId) async {
    // 1. Try deterministic ID first (the new standard)
    final deterministicDoc = await _submissionsCollection.doc('${userId}_${formId}').get();
    if (deterministicDoc.exists) {
      return FormSubmissionModel.fromDoc(deterministicDoc);
    }

    // 2. Fallback to query (for legacy submissions with random IDs)
    final snapshot = await _submissionsCollection
        .where('formId', isEqualTo: formId)
        .where('userId', isEqualTo: userId)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      // Sort in memory to find the most recently modified one if duplicates exist
      final submissions = snapshot.docs.map((doc) => FormSubmissionModel.fromDoc(doc)).toList();
      submissions.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return submissions.first;
    }
    return null;
  }

  // Update Submission Status (Approve/Reject)
  Future<void> updateSubmissionStatus(String submissionId, SubmissionStatus status, {String? rejectedBy}) async {
    await _submissionsCollection.doc(submissionId).update({
      'status': status.name,
      'lastModified': Timestamp.now(),
      if (rejectedBy != null) 'rejectedBy': rejectedBy,
    });
  }

  // Bulk Update Status
  Future<void> bulkUpdateStatus(List<String> submissionIds, SubmissionStatus status, {String? rejectedBy}) async {
    final batch = _firestore.batch();
    for (final id in submissionIds) {
      batch.update(_submissionsCollection.doc(id), {
        'status': status.name,
        'lastModified': Timestamp.now(),
        if (rejectedBy != null) 'rejectedBy': rejectedBy,
      });
    }
    await batch.commit();
  }

  // Bulk Delete Submissions
  Future<void> bulkDeleteSubmissions(List<String> submissionIds) async {
    final batch = _firestore.batch();
    for (final id in submissionIds) {
      batch.delete(_submissionsCollection.doc(id));
    }
    await batch.commit();
  }

  // Get Submissions for a Form
  Stream<List<FormSubmissionModel>> getSubmissionsStream(String formId) {
    // Fetch submissions for this form and sort in memory to avoid requiring composite indexes
    return _submissionsCollection
        .where('formId', isEqualTo: formId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => FormSubmissionModel.fromDoc(doc)).toList();
      // Sort in memory by submittedAt descending
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }
}
