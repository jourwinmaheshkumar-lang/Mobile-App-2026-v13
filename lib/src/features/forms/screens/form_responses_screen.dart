import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/services/localization_service.dart';
import '../models/form_field.dart';
import '../models/form_model.dart';
import '../models/form_submission.dart';
import '../services/form_repository.dart';
import '../services/form_export_service.dart';
import 'form_filler_screen.dart';
import '../../../core/models/notification.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user.dart';

class FormResponsesScreen extends StatefulWidget {
  final FormModel form;
  const FormResponsesScreen({super.key, required this.form});

  @override
  State<FormResponsesScreen> createState() => _FormResponsesScreenState();
}

class _FormResponsesScreenState extends State<FormResponsesScreen> {
  final _repository = FormRepository();
  final Set<String> _selectedSubmissions = {};
  bool _isSelectionMode = false;
  List<FormSubmissionModel> _currentSubmissions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedSubmissions.length} Selected' : '${widget.form.title} - Reports'),
        leading: _isSelectionMode 
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelectionMode = false; _selectedSubmissions.clear(); }))
            : null,
        actions: [
          if (_isSelectionMode) ...[
            StreamBuilder<List<FormSubmissionModel>>(
              stream: _repository.getSubmissionsStream(widget.form.id),
              builder: (context, snapshot) {
                final allIds = snapshot.data?.map((e) => e.id).toList() ?? [];
                return IconButton(
                  icon: const Icon(Icons.select_all_rounded),
                  onPressed: () => setState(() {
                    if (_selectedSubmissions.length == allIds.length) _selectedSubmissions.clear();
                    else _selectedSubmissions.addAll(allIds);
                    if (_selectedSubmissions.isEmpty) _isSelectionMode = false;
                  }),
                );
              }
            ),
          ] else
            StreamBuilder<List<FormSubmissionModel>>(
              stream: _repository.getSubmissionsStream(widget.form.id),
              builder: (context, snapshot) {
                final submissions = snapshot.data ?? [];
                if (submissions.isEmpty) return const SizedBox.shrink();
                
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.download_rounded),
                  onSelected: (value) {
                    if (value == 'csv') {
                      FormExportService.exportToCsv(widget.form, submissions);
                    } else if (value == 'pdf') {
                      FormExportService.exportToPdf(widget.form, submissions);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'csv', child: Row(children: [const Icon(Icons.table_chart, size: 20), const SizedBox(width: 8), Text(localizationService.tr('export_csv'))])),
                    PopupMenuItem(value: 'pdf', child: Row(children: [const Icon(Icons.picture_as_pdf, size: 20), const SizedBox(width: 8), Text(localizationService.tr('export_pdf'))])),
                  ],
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<FormSubmissionModel>>(
        stream: _repository.getSubmissionsStream(widget.form.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.error)),
            ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final submissions = snapshot.data ?? [];
          _currentSubmissions = submissions;

          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 80, color: AppTheme.textTertiary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No responses yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              return _buildSubmissionCard(sub);
            },
          );
        },
      ),
      bottomNavigationBar: _isSelectionMode ? _buildBottomActionBar() : null,
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPillButton(
            onPressed: () => _handleBulkAction(SubmissionStatus.approved),
            icon: Icons.check_circle_rounded,
            label: 'Approve',
            color: const Color(0xFF2E7D32),
            gradient: [const Color(0xFF43A047), const Color(0xFF2E7D32)],
          ),
          const SizedBox(width: 10),
          _buildPillButton(
            onPressed: () => _handleBulkAction(SubmissionStatus.rejected),
            icon: Icons.cancel_rounded,
            label: 'Reject',
            color: const Color(0xFFC62828),
            gradient: [const Color(0xFFE53935), const Color(0xFFC62828)],
          ),
          const SizedBox(width: 10),
          _buildPillButton(
            onPressed: () => _handleBulkAction(SubmissionStatus.draft),
            icon: Icons.lock_open_rounded,
            label: 'Unlock',
            color: const Color(0xFFE65100),
            gradient: [const Color(0xFFFB8C00), const Color(0xFFE65100)],
          ),
          const SizedBox(width: 10),
          _buildPillButton(
            onPressed: _handleBulkDelete,
            icon: Icons.delete_forever_rounded,
            label: localizationService.tr('delete'),
            color: Colors.black,
            gradient: [Colors.grey.shade900, Colors.black],
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 10,
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
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBulkAction(SubmissionStatus status) async {
    if (_selectedSubmissions.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status == SubmissionStatus.approved ? "Approve" : "Reject"} ${_selectedSubmissions.length} forms?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(status.name.toUpperCase())),
        ],
      ),
    );

    if (confirmed == true) {
      final user = await AuthService().currentAppUser;
      final rejectedBy = status == SubmissionStatus.rejected 
          ? "${user?.displayName ?? 'Admin'} (${user?.username ?? 'Admin'})" 
          : null;
          
      final count = _selectedSubmissions.length;
      final selectedList = _currentSubmissions.where((s) => _selectedSubmissions.contains(s.id)).toList();
      
      await _repository.bulkUpdateStatus(_selectedSubmissions.toList(), status, rejectedBy: rejectedBy);
      
      // Notify users
      for (final sub in selectedList) {
        String title = '';
        String message = '';
        NotificationType type = NotificationType.info;

        switch (status) {
          case SubmissionStatus.approved:
            title = 'Form Approved';
            message = 'Your submission for "${widget.form.title}" has been approved.';
            type = NotificationType.success;
            break;
          case SubmissionStatus.rejected:
            title = 'Form Rejected';
            message = 'Your submission for "${widget.form.title}" has been rejected.';
            type = NotificationType.error;
            break;
          case SubmissionStatus.draft:
            title = 'Form Unlocked';
            message = 'Your submission for "${widget.form.title}" has been unlocked for editing.';
            type = NotificationType.warning;
            break;
          default:
            continue;
        }

        notificationService.notify(
          userId: sub.userId,
          title: title,
          message: message,
          type: type,
          relatedEntityId: widget.form.id,
        );
      }

      setState(() {
        _isSelectionMode = false;
        _selectedSubmissions.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated $count submissions')));
      }
    }
  }

  void _handleBulkDelete() async {
    if (_selectedSubmissions.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedSubmissions.length} submissions?'),
        content: const Text('This will remove the reports and allow the users to resubmit. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = _selectedSubmissions.length;
      final selectedList = _currentSubmissions.where((s) => _selectedSubmissions.contains(s.id)).toList();

      await _repository.bulkDeleteSubmissions(_selectedSubmissions.toList());

      // Notify users (Notify as Rejected so they know they need to resubmit)
      for (final sub in selectedList) {
        notificationService.notify(
          userId: sub.userId,
          title: 'Form Rejected (Please Resubmit)',
          message: 'Your previous submission for "${widget.form.title}" was removed. Please resubmit if required.',
          type: NotificationType.error,
          relatedEntityId: widget.form.id,
        );
      }

      setState(() {
        _isSelectionMode = false;
        _selectedSubmissions.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permanently deleted $count records')));
      }
    }
  }

  Widget _buildSubmissionCard(FormSubmissionModel sub) {
    final isSelected = _selectedSubmissions.contains(sub.id);
    
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedSubmissions.add(sub.id);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) _selectedSubmissions.remove(sub.id);
            else _selectedSubmissions.add(sub.id);
            if (_selectedSubmissions.isEmpty) _isSelectionMode = false;
          });
        } else {
          // Open in filler screen (read-only)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormFillerScreen(form: widget.form, submission: sub)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.person_rounded, size: 22, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getSubmissionIdentifier(sub),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.4),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    _buildStatusBadge(sub.status),
                                    if (sub.status == SubmissionStatus.completed && sub.rejectionCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange.shade200),
                                        ),
                                        child: const Text('RESUBMITTED', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.event_note_rounded, size: 14, color: AppTheme.textTertiary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMM dd, yyyy - hh:mm a').format(sub.submittedAt),
                                    style: TextStyle(fontSize: 13, color: AppTheme.textTertiary, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  if (sub.lastChangedFields != null && sub.lastChangedFields!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text('${sub.lastChangedFields!.length} FIELDS UPDATED', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  const Spacer(),
                  if (!_isSelectionMode)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FormFillerScreen(form: widget.form, submission: sub)),
                         );
                      },
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                      label: const Text('PREVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            if (_isSelectionMode)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primary : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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

  String _getSubmissionIdentifier(FormSubmissionModel sub) {
    // 1. Try to find a field named "Name" or "Full Name" or "Director Name"
    try {
      final nameField = widget.form.fields.firstWhere(
        (f) {
          final l = f.label.toLowerCase();
          return l == 'name' || l == 'full_name' || l == 'full name' || l == 'directors names' || l == 'director name';
        },
      );
      
      final val = sub.responses[nameField.id];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    } catch (_) {}

    // 2. Fallback to the saved user profile name
    return sub.userName ?? 'Anonymous User';
  }
}
