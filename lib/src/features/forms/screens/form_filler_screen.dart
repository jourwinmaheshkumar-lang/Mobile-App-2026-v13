import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/models/user.dart';
import '../models/form_field.dart';
import '../models/form_model.dart';
import '../models/form_submission.dart';
import '../services/form_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../core/models/notification.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/models/director.dart';
import '../../../core/repositories/director_repository.dart';

class FormFillerScreen extends StatefulWidget {
  final FormModel form;
  final FormSubmissionModel? submission; // Optional: directly pass submission if viewing from reports
  const FormFillerScreen({super.key, required this.form, this.submission});

  @override
  State<FormFillerScreen> createState() => _FormFillerScreenState();
}

class _FormFillerScreenState extends State<FormFillerScreen> {
  final _repository = FormRepository();
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {};
  FormSubmissionModel? _currentSubmission;
  bool _isLoading = true;
  bool _isSaving = false;
  late bool _isReadOnly;
  
  // Proxy filling
  final _directorRepo = DirectorRepository();
  List<Director> _allDirectors = [];
  Director? _selectedProxyDirector;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    if (widget.submission != null) {
      _currentSubmission = widget.submission;
    } else {
      final user = await AuthService().currentAppUser;
      if (user != null) {
        _currentSubmission = await _repository.getUserSubmission(widget.form.id, user.uid);
      }
    }

    if (_currentSubmission != null) {
      _responses.addAll(_currentSubmission!.responses);
    }

     _isReadOnly = _currentSubmission != null && 
                  _currentSubmission!.status != SubmissionStatus.draft && 
                  _currentSubmission!.status != SubmissionStatus.rejected;
    
    // Check if the current user is Admin/Office Team for administrative actions
    _currentUser = await AuthService().currentAppUser;
    final isAdmin = _currentUser != null && (_currentUser!.role == UserRole.admin || _currentUser!.role == UserRole.officeTeam);

    if (widget.form.allowProxySubmission || isAdmin) {
      _allDirectors = List<Director>.from(_directorRepo.all)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (_allDirectors.isEmpty) {
        await _directorRepo.loadAll();
        _allDirectors = List<Director>.from(_directorRepo.all)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
    }

    if (mounted) setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.form.title),
        actions: [
          if (_currentSubmission != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: _buildStatusBadge(_currentSubmission!.status)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.form.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    widget.form.description,
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                   ),
                ),
              if (_shouldShowProxySelector()) _buildProxySelector(),
              if (_currentSubmission?.status == SubmissionStatus.rejected && !_isAdmin())
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
                          SizedBox(width: 8),
                          Text('Previous Rejection', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentSubmission?.rejectionReason ?? 'No reason provided. Please review all fields and resubmit.',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'You can now edit the fields below and resubmit for approval.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ...widget.form.fields.map((field) => _buildFieldInput(field)).toList(),
              const SizedBox(height: 40),
              if (!_isReadOnly) _buildActionButtons(),
              if (_isReadOnly) ...[
                Center(
                  child: Text(
                    'This form is completed and locked.',
                    style: TextStyle(color: AppTheme.textTertiary, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isAdmin()) _buildAdminActions(),
              ],
              if (_isAdmin() && _currentSubmission != null) ...[
                const SizedBox(height: 40),
                _buildAdminSummary(),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  bool _isAdmin() {
    return _currentUser != null && (_currentUser!.role == UserRole.admin || _currentUser!.role == UserRole.officeTeam);
  }

  bool _shouldShowProxySelector() {
    if (_currentSubmission != null) return false; // Already submitted, don't show selector
    if (_isAdmin()) return true;
    return widget.form.allowProxySubmission;
  }

  Widget _buildProxySelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Fill Form for Another Director', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Director>(
            value: _selectedProxyDirector,
            decoration: const InputDecoration(
              labelText: 'Select Director (DIN)',
              hintText: 'Search by name or DIN',
            ),
            items: _allDirectors.map((d) => DropdownMenuItem(
              value: d,
              child: Text('${d.name} (${d.din})'),
            )).toList(),
            onChanged: (val) {
              setState(() => _selectedProxyDirector = val);
              if (val != null) {
                _checkExistingSubmission(val.din);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkExistingSubmission(String din) async {
    // Note: Since users here are directors, their UID is usually their DIN in this app's logic
    // or they have a mapping. getUserSubmission uses userId.
    final existing = await _repository.getUserSubmission(widget.form.id, din);
    if (existing != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Director with DIN $din has already submitted this form.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Widget _buildAdminSummary() {
    final sub = _currentSubmission!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text('Administrative Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(height: 32),
          _buildSummaryRow('Submitted By', sub.filledByUserName ?? sub.userName ?? 'User'),
          _buildSummaryRow('Submitted For', sub.userName ?? (sub.userId.length == 8 ? 'DIN: ${sub.userId}' : sub.userId)),
          _buildSummaryRow('Initial Date', DateFormat('MMM dd, yyyy - hh:mm a').format(sub.submittedAt)),
          _buildSummaryRow('Last Modified', DateFormat('MMM dd, yyyy - hh:mm a').format(sub.lastModified)),
          _buildSummaryRow('Rejection Count', sub.rejectionCount.toString(), isHighlight: sub.rejectionCount > 0),
          if (sub.rejectedBy != null)
             _buildSummaryRow('Last Rejected By', sub.rejectedBy!),
          if (sub.rejectionReason != null)
             _buildSummaryRow('Rejection Reason', sub.rejectionReason!, isHighlight: true),
          if (sub.lastChangedFields != null && sub.lastChangedFields!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('CHANGES SINCE REJECTION:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sub.lastChangedFields!.map((lab) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Text(lab, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  )).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: AppTheme.textTertiary, fontSize: 14))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? AppTheme.error : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Column(
      children: [
        Row(
          children: [
            _buildAdminPillButton(
              onPressed: _isSaving ? null : () => _submitForm(SubmissionStatus.approved),
              icon: Icons.check_circle_rounded,
              label: 'Approve',
              color: const Color(0xFF2E7D32),
              gradient: [const Color(0xFF43A047), const Color(0xFF2E7D32)],
            ),
            const SizedBox(width: 8),
            _buildAdminPillButton(
              onPressed: _isSaving ? null : () => _submitForm(SubmissionStatus.rejected),
              icon: Icons.cancel_rounded,
              label: 'Reject',
              color: const Color(0xFFC62828),
              gradient: [const Color(0xFFE53935), const Color(0xFFC62828)],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAdminPillButton(
          onPressed: _isSaving ? null : () => _submitForm(SubmissionStatus.draft),
          icon: Icons.lock_open_rounded,
          label: 'UNLOCK FOR USER TO EDIT',
          color: const Color(0xFFE65100),
          gradient: [const Color(0xFFFB8C00), const Color(0xFFE65100)],
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildAdminPillButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required List<Color> gradient,
    bool isFullWidth = false,
  }) {
    Widget child = Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: onPressed == null 
            ? null 
            : LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        color: onPressed == null ? Colors.grey : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null ? null : [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: child) : Expanded(child: child);
  }

  Widget _buildStatusBadge(SubmissionStatus status) {
    Color color = Colors.grey;
    String text = status.name.toUpperCase();
    switch (status) {
      case SubmissionStatus.draft: color = Colors.orange; text = 'DRAFT'; break;
      case SubmissionStatus.completed: color = Colors.blue; text = 'PENDING FOR APPROVAL'; break;
      case SubmissionStatus.approved: color = Colors.green; text = 'APPROVED'; break;
      case SubmissionStatus.rejected: color = Colors.red; text = 'REJECTED'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _submitForm(SubmissionStatus.draft),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving ? _loader() : const Text('SAVE DRAFT'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _submitForm(SubmissionStatus.completed),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving ? _loader() : const Text('COMPLETE & SUBMIT'),
          ),
        ),
      ],
    );
  }

  Widget _loader() => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));

  Widget _buildFieldInput(FormFieldModel field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (field.isRequired && !_isReadOnly)
                const Text(' *', style: TextStyle(color: AppTheme.error)),
              const Spacer(),
              if (_isAdmin() && _currentSubmission != null && (_currentSubmission!.lastChangedFields?.contains(field.label) ?? false))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('UPDATED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isReadOnly ? _buildReadOnlyView(field) : _buildInputWidget(field),
        ],
      ),
    );
  }

  Widget _buildReadOnlyView(FormFieldModel field) {
    var resp = _responses[field.id];
    String display = 'N/A';
    if (resp != null) {
      if (field.type == FormFieldType.currency) display = '₹ $resp';
      else if (resp is List) display = resp.join(', ');
      else display = resp.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Text(
        display,
        style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildInputWidget(FormFieldModel field) {
    switch (field.type) {
      case FormFieldType.text:
        return TextFormField(
          initialValue: _responses[field.id],
          decoration: InputDecoration(hintText: field.placeholder ?? 'Enter text'),
          validator: field.isRequired ? (val) => val == null || val.isEmpty ? 'This field is required' : null : null,
          onChanged: (val) => _responses[field.id] = val,
        );
      case FormFieldType.number:
        return TextFormField(
          initialValue: _responses[field.id],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: field.placeholder ?? 'Enter number'),
          validator: field.isRequired ? (val) => val == null || val.isEmpty ? 'This field is required' : null : null,
          onChanged: (val) => setState(() => _responses[field.id] = val),
        );
      case FormFieldType.date:
        return _DateInput(
          field: field,
          initialValue: _responses[field.id],
          onChanged: (val) => _responses[field.id] = val,
        );
      case FormFieldType.dropdown:
        return DropdownButtonFormField<String>(
          value: _responses[field.id],
          decoration: const InputDecoration(),
          items: (field.options ?? []).map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          validator: field.isRequired ? (val) => val == null ? 'Please select an option' : null : null,
          onChanged: (val) => setState(() => _responses[field.id] = val),
        );
      case FormFieldType.checkbox:
        return _CheckboxInput(
          field: field,
          initialValue: _responses[field.id] != null ? List<String>.from(_responses[field.id]) : [],
          onChanged: (val) => _responses[field.id] = val,
        );
      case FormFieldType.radio:
        return _RadioInput(
          field: field,
          initialValue: _responses[field.id],
          onChanged: (val) => _responses[field.id] = val,
        );
      case FormFieldType.currency:
        return TextFormField(
          initialValue: _responses[field.id],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: field.placeholder ?? '0.00',
            prefixText: '₹ ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          validator: field.isRequired ? (val) => val == null || val.isEmpty ? 'This field is required' : null : null,
           onChanged: (val) => setState(() => _responses[field.id] = val),
        );
      case FormFieldType.calculation:
        final result = _calculateMathValue(field);
        _responses[field.id] = result.toString();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calculate_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              const Text('Computed Result:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text(
                '₹ $result',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary),
              ),
            ],
          ),
        );
      case FormFieldType.notes:
        return TextFormField(
          initialValue: _responses[field.id],
          maxLines: 4,
          decoration: InputDecoration(hintText: field.placeholder ?? 'Enter additional notes...'),
          onChanged: (val) => _responses[field.id] = val,
        );
    }
  }

  double _calculateMathValue(FormFieldModel field) {
    if (field.mathSourceFields == null || field.mathSourceFields!.isEmpty) return 0.0;
    
    List<double> values = [];
    for (var sourceId in field.mathSourceFields!) {
      final val = _responses[sourceId];
      if (val != null) {
        values.add(double.tryParse(val.toString()) ?? 0.0);
      }
    }

    if (values.isEmpty) return 0.0;

    double result = 0.0;
    final op = field.mathOperation ?? 'add';

    if (op == 'add') {
      result = values.reduce((a, b) => a + b);
    } else if (op == 'subtract') {
      result = values.reduce((a, b) => a - b);
    } else if (op == 'multiply') {
      result = values.reduce((a, b) => a * b);
    }

    return double.parse(result.toStringAsFixed(2));
  }

  Future<void> _submitForm(SubmissionStatus targetStatus) async {
    if (targetStatus == SubmissionStatus.completed) {
      if (!_formKey.currentState!.validate()) return;
    }
    
    setState(() => _isSaving = true);

    try {
      final user = await AuthService().currentAppUser;
      
      // Secondary collision check for proxy submission
      if (_selectedProxyDirector != null) {
        final existing = await _repository.getUserSubmission(widget.form.id, _selectedProxyDirector!.din);
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: Director ${_selectedProxyDirector!.name} already has a submission for this form.')),
            );
            setState(() => _isSaving = false);
          }
          return;
        }
      }

      final isAdmin = user != null && (user.role == UserRole.admin || user.role == UserRole.officeTeam);

      if (!isAdmin && widget.form.deadline != null && DateTime.now().isAfter(widget.form.deadline!)) {
        if (targetStatus == SubmissionStatus.completed || targetStatus == SubmissionStatus.draft) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deadline passed. Form submissions are no longer accepted. Please contact Admin/Office Team to extend the time.')));
            setState(() => _isSaving = false);
          }
          return;
        }
      }

      String? rejectedByInfo;
      String? rejectionReason;
      List<String>? changedFields;
      
      if (targetStatus == SubmissionStatus.rejected) {
        final reason = await _showRejectionReasonDialog();
        if (reason == null) {
          setState(() => _isSaving = false);
          return; // Cancelled
        }
        rejectionReason = reason;
      }

      if (_currentSubmission?.status == SubmissionStatus.rejected && targetStatus == SubmissionStatus.completed) {
        final oldResponses = _currentSubmission!.responses;
        changedFields = [];
        for (final field in widget.form.fields) {
          if (oldResponses[field.id] != _responses[field.id]) {
            changedFields.add(field.label);
          }
        }
        
        final prevRejecter = _currentSubmission?.rejectedBy ?? "Admin";
        String changesMsg = changedFields.isNotEmpty ? " Changed fields: ${changedFields.join(', ')}." : " No fields changed.";
        
        activityLogService.log(
          action: ActivityAction.update,
          entityType: EntityType.form,
          entityName: widget.form.title,
          details: "Form resubmitted by ${user?.displayName ?? 'Director'}. (Previously rejected by $prevRejecter).$changesMsg",
        );
      } else if (targetStatus == SubmissionStatus.rejected) {
        rejectedByInfo = "${user?.displayName ?? 'Admin'} (${user?.username ?? 'Admin'})";
        activityLogService.log(
          action: ActivityAction.update,
          entityType: EntityType.form,
          entityName: widget.form.title,
          details: "Form rejected by $rejectedByInfo.",
        );
      }

      final submission = FormSubmissionModel(
        id: _currentSubmission?.id ?? '',
        formId: widget.form.id,
        userId: _selectedProxyDirector?.din ?? _currentSubmission?.userId ?? user?.uid ?? 'anonymous',
        userName: _selectedProxyDirector?.name ?? _currentSubmission?.userName ?? user?.displayName ?? user?.username ?? 'User',
        responses: _responses,
        submittedAt: _currentSubmission?.submittedAt ?? DateTime.now(),
        lastModified: DateTime.now(),
        status: targetStatus,
        rejectedBy: targetStatus == SubmissionStatus.rejected ? rejectedByInfo : _currentSubmission?.rejectedBy,
        rejectionReason: targetStatus == SubmissionStatus.rejected 
            ? rejectionReason 
            : (targetStatus == SubmissionStatus.completed ? null : _currentSubmission?.rejectionReason),
        rejectionCount: targetStatus == SubmissionStatus.rejected 
            ? (_currentSubmission?.rejectionCount ?? 0) + 1 
            : (_currentSubmission?.rejectionCount ?? 0),
        filledByUserId: _selectedProxyDirector != null ? user?.uid : (_currentSubmission?.filledByUserId ?? user?.uid),
        filledByUserName: _selectedProxyDirector != null 
            ? (user?.displayName ?? user?.username ?? 'Admin') 
            : (_currentSubmission?.filledByUserName ?? user?.displayName ?? user?.username ?? 'User'),
        lastChangedFields: changedFields ?? (targetStatus == SubmissionStatus.approved ? null : _currentSubmission?.lastChangedFields),
      );

      await _repository.saveSubmission(submission);
      if (mounted) {
        String msg = targetStatus == SubmissionStatus.draft 
            ? 'Progress saved as draft' 
            : targetStatus == SubmissionStatus.approved ? 'Form approved successfully 👍'
            : targetStatus == SubmissionStatus.rejected ? 'Form rejected successfully'
            : localizationService.tr('form_submitted_success');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        
        // Internal notification
        if (user != null) {
          String notifTitle = '';
          String notifMsg = '';
          NotificationType type = NotificationType.info;
          
          if (targetStatus == SubmissionStatus.draft) {
            notifTitle = 'Draft Saved';
            notifMsg = 'Your draft for "${widget.form.title}" has been saved.';
          } else if (targetStatus == SubmissionStatus.completed) {
            notifTitle = 'Form Submitted';
            notifMsg = 'Your submission for "${widget.form.title}" is now pending approval.';
            type = NotificationType.success;
          } else if (targetStatus == SubmissionStatus.approved) {
            notifTitle = 'Form Approved';
            notifMsg = 'Congratulations! 🏅 Your submission for "${widget.form.title}" has been approved!';
            type = NotificationType.success;
          } else if (targetStatus == SubmissionStatus.rejected) {
            notifTitle = 'Form Rejected';
            notifMsg = 'Your submission for "${widget.form.title}" has been rejected. Please review and resubmit.';
            type = NotificationType.error;
          }

          String targetUserId = _currentSubmission?.userId ?? user.uid;

          notificationService.notify(
            userId: targetUserId,
            title: notifTitle,
            message: notifMsg,
            type: type,
            relatedEntityId: widget.form.id,
            category: 'forms',
            clickAction: 'open_form_list',
          );
        }

        if (targetStatus == SubmissionStatus.approved) {
          _showApprovalCelebration();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showApprovalCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 100),
                    const SizedBox(height: 24),
                    const Text(
                      'CONGRATULATIONS!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The form has been approved successfully. A reward medal has been sent to the director!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Pop dialog
                        if (mounted) Navigator.pop(context); // Pop screen
                      },
                      child: const Text('GREAT!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showRejectionReasonDialog() async {
    String? reason;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: AppTheme.error),
              SizedBox(width: 8),
              Text('Reject Submission'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide a reason for rejection. This will be shown to the director.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g., Wrong DIN format, attached incorrect document, etc.',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () { reason = controller.text.trim(); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('REJECT'),
            ),
          ],
        );
      },
    );
    if (reason != null && reason!.isEmpty) return 'No specific reason provided.';
    return reason;
  }
}

class _DateInput extends StatefulWidget {
  final FormFieldModel field;
  final String? initialValue;
  final Function(String) onChanged;
  const _DateInput({required this.field, this.initialValue, required this.onChanged});

  @override
  State<_DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<_DateInput> {
  DateTime? _selectedDate;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    if (widget.initialValue != null) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.initialValue!);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            _controller.text = DateFormat('yyyy-MM-dd').format(date);
          });
          widget.onChanged(_controller.text);
        }
      },
      decoration: const InputDecoration(
        hintText: 'Select date',
        suffixIcon: Icon(Icons.calendar_today_rounded),
      ),
      validator: widget.field.isRequired ? (val) => val == null || val.isEmpty ? 'Please select a date' : null : null,
    );
  }
}

class _CheckboxInput extends StatefulWidget {
  final FormFieldModel field;
  final List<String> initialValue;
  final Function(List<String>) onChanged;
  const _CheckboxInput({required this.field, required this.initialValue, required this.onChanged});

  @override
  State<_CheckboxInput> createState() => _CheckboxInputState();
}

class _CheckboxInputState extends State<_CheckboxInput> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: (widget.field.options ?? []).map((opt) {
        return CheckboxListTile(
          title: Text(opt),
          value: _selected.contains(opt),
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selected.add(opt);
              } else {
                _selected.remove(opt);
              }
            });
            widget.onChanged(_selected);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}

class _RadioInput extends StatefulWidget {
  final FormFieldModel field;
  final String? initialValue;
  final Function(String) onChanged;
  const _RadioInput({required this.field, this.initialValue, required this.onChanged});

  @override
  State<_RadioInput> createState() => _RadioInputState();
}

class _RadioInputState extends State<_RadioInput> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: (widget.field.options ?? []).map((opt) {
        return RadioListTile<String>(
          title: Text(opt),
          value: opt,
          groupValue: _selected,
          onChanged: (val) {
            setState(() {
              _selected = val;
            });
            if (val != null) widget.onChanged(val);
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}
