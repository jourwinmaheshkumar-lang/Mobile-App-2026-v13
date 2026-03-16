import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';
import '../models/form_model.dart';
import '../models/form_submission.dart';
import '../services/form_repository.dart';
import 'form_builder_screen.dart';
import 'form_filler_screen.dart';
import 'form_responses_screen.dart';
import '../../../core/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class FormListScreen extends StatefulWidget {
  const FormListScreen({super.key});

  @override
  State<FormListScreen> createState() => _FormListScreenState();
}

class _FormListScreenState extends State<FormListScreen> {
  final _repository = FormRepository();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<AppUser?>(
      stream: _authService.userStream,
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        // Clear form notifications when visiting this screen
        notificationService.markAllAsReadByCategory(currentUser.uid, 'forms');

        final canManage = currentUser.role == UserRole.admin || currentUser.role == UserRole.officeTeam;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(localizationService.tr('dynamic_forms')),
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF8FAFF), const Color(0xFFF1F5F9)],
              ),
            ),
            child: StreamBuilder<List<FormModel>>(
              stream: _repository.getFormsStream(activeOnly: !canManage),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                          const SizedBox(height: 16),
                          Text('Could not load forms. Please try again.', style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Text(snapshot.error.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final forms = snapshot.data ?? [];

                if (forms.isEmpty) {
                  return _buildEmptyState(canManage);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
                  itemCount: forms.length,
                  itemBuilder: (context, index) {
                    final form = forms[index];
                    return _buildFormCard(form, canManage);
                  },
                );
              },
            ),
          ),
          floatingActionButton: canManage
              ? FloatingActionButton.extended(
                  onPressed: () => _navigateToBuilder(context),
                  label: Text(localizationService.tr('create_form')),
                  icon: const Icon(Icons.add),
                  backgroundColor: AppTheme.primary,
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(bool canManage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: AppTheme.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            localizationService.tr('no_forms_available'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: 8),
            Text(
              'Create your first form to get started',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _navigateToBuilder(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Create Now'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard(FormModel form, bool canManage) {
    if (canManage) {
      return _AdminFormCard(
        form: form, 
        repository: _repository, 
        onEdit: (f) => _navigateToBuilder(context, form: f), 
        onDelete: (f) => _confirmDelete(f), 
        onToggle: (f) => _repository.saveForm(f), 
        onViewReports: (f) => _navigateToResponses(context, f),
        onNavigate: (f) => _navigateToFiller(context, f),
      );
    }
    return _UserFormCard(form: form, repository: _repository, onNavigate: (f) => _navigateToFiller(context, f));
  }

  Widget _buildAdminMenu(FormModel form) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') {
          _navigateToBuilder(context, form: form);
        } else if (value == 'delete') {
          _confirmDelete(form);
        } else if (value == 'toggle') {
          _repository.saveForm(form.copyWith(isActive: !form.isActive));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(localizationService.tr('edit_form'))),
        PopupMenuItem(
          value: 'toggle',
          child: Text(form.isActive ? 'Deactivate' : 'Activate'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(localizationService.tr('delete'), style: TextStyle(color: AppTheme.error)),
        ),
      ],
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _navigateToBuilder(BuildContext context, {FormModel? form}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormBuilderScreen(form: form)),
    );
  }

  void _navigateToFiller(BuildContext context, FormModel form) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormFillerScreen(form: form)),
    );
  }

  void _navigateToResponses(BuildContext context, FormModel form) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormResponsesScreen(form: form)),
    );
  }

  void _confirmDelete(FormModel form) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizationService.tr('delete_form')),
        content: Text('This will permanently delete "${form.title}" and all its submissions. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _repository.deleteForm(form.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(SubmissionStatus status) {
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AdminFormCard extends StatelessWidget {
  final FormModel form;
  final FormRepository repository;
  final Function(FormModel) onEdit;
  final Function(FormModel) onDelete;
  final Function(FormModel) onToggle;
  final Function(FormModel) onViewReports;
  final Function(FormModel) onNavigate;

  const _AdminFormCard({
    required this.form,
    required this.repository,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onViewReports,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Created ${DateFormat('MMM dd').format(form.createdAt)}',
                            style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    _buildAdminMenu(context),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatsSection(context),
                const SizedBox(height: 20),
                _buildDeadlineInfo(),
              ],
            ),
          ),
          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return StreamBuilder<List<FormSubmissionModel>>(
      stream: repository.getSubmissionsStream(form.id),
      builder: (context, snapshot) {
        final submissions = snapshot.data ?? [];
        final approved = submissions.where((s) => s.status == SubmissionStatus.approved).length;
        final pending = submissions.where((s) => s.status == SubmissionStatus.completed).length;
        final rejected = submissions.where((s) => s.status == SubmissionStatus.rejected).length;
        final total = submissions.length;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Approved', approved, Colors.green),
                _buildStatItem('Pending', pending, Colors.blue),
                _buildStatItem('Rejected', rejected, Colors.red),
                _buildStatItem('Total', total, AppTheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(approved, pending, rejected, total),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
      ],
    );
  }

  Widget _buildProgressBar(int approved, int pending, int rejected, int total) {
    if (total == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(4)),
      );
    }

    final approvedWidth = approved / total;
    final pendingWidth = pending / total;
    final rejectedWidth = rejected / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        width: double.infinity,
        color: AppTheme.borderLight,
        child: Row(
          children: [
            if (approvedWidth > 0)
              Flexible(flex: (approvedWidth * 100).toInt(), child: Container(color: Colors.green)),
            if (pendingWidth > 0)
              Flexible(flex: (pendingWidth * 100).toInt(), child: Container(color: Colors.blue)),
            if (rejectedWidth > 0)
              Flexible(flex: (rejectedWidth * 100).toInt(), child: Container(color: Colors.red)),
            Flexible(flex: ((1 - approvedWidth - pendingWidth - rejectedWidth) * 100).toInt(), child: Container(color: Colors.blue.withOpacity(0.1))),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineInfo() {
    if (form.deadline == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(child: _CountdownTimer(deadline: form.deadline!)),
          Text(
            'Limit: ${DateFormat('MMM dd, hh:mm a').format(form.deadline!)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onViewReports(form),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_rounded, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'VIEW DETAILED REPORTS',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (value) {
        if (value == 'edit') onEdit(form);
        else if (value == 'delete') onDelete(form);
        else if (value == 'toggle') onToggle(form.copyWith(isActive: !form.isActive));
        else if (value == 'fill') onNavigate(form);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 20), const SizedBox(width: 8), Text(localizationService.tr('edit_form'))])),
        PopupMenuItem(value: 'fill', child: Row(children: [const Icon(Icons.edit_document, size: 20), const SizedBox(width: 8), const Text('Fill Form')])),
        PopupMenuItem(value: 'toggle', child: Row(children: [Icon(form.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), const SizedBox(width: 8), Text(form.isActive ? 'Deactivate' : 'Activate')])),
        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), const SizedBox(width: 8), Text(localizationService.tr('delete'), style: const TextStyle(color: AppTheme.error))])),
      ],
    );
  }
}

class _UserFormCard extends StatelessWidget {
  final FormModel form;
  final FormRepository repository;
  final Function(FormModel) onNavigate;

  const _UserFormCard({required this.form, required this.repository, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate(form),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(form.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(form.description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    _buildUserStatus(),
                  ],
                ),
                const SizedBox(height: 16),
                if (form.deadline != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Expanded(child: _CountdownTimer(deadline: form.deadline!)),
                      Text(
                        'Starts: ${DateFormat('dd MMM').format(form.startDate ?? form.createdAt)}',
                        style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatus() {
    return FutureBuilder<AppUser?>(
      future: AuthService().currentAppUser,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        return FutureBuilder<FormSubmissionModel?>(
          future: repository.getUserSubmission(form.id, userSnap.data!.uid),
          builder: (context, snap) {
            final sub = snap.data;
            if (sub == null) {
              return _buildStatusPill(null);
            }
            return _buildStatusPill(sub.status);
          },
        );
      },
    );
  }

  Widget _buildStatusPill(SubmissionStatus? status) {
    Color color = Colors.grey;
    String text = 'NOT SUBMITTED';
    
    if (status == null) {
      color = AppTheme.textTertiary;
      text = 'NOT SUBMITTED';
    } else {
      switch (status) {
        case SubmissionStatus.draft: 
          color = Colors.orange; 
          text = 'DRAFT'; 
          break;
        case SubmissionStatus.completed: 
          color = Colors.blue; 
          text = 'PENDING FOR APPROVAL'; 
          break;
        case SubmissionStatus.approved: 
          color = Colors.green; 
          text = 'APPROVED'; 
          break;
        case SubmissionStatus.rejected: 
          color = Colors.red; 
          text = 'REJECTED'; 
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text, 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  final DateTime deadline;
  const _CountdownTimer({required this.deadline});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deadline != oldWidget.deadline) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    _calculateTimeLeft();
    if (!_timeLeft.isNegative) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _calculateTimeLeft());
      });
    }
  }

  void _calculateTimeLeft() {
    _timeLeft = widget.deadline.difference(DateTime.now());
    if (_timeLeft.isNegative) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) {
      return const Text('Deadline Passed', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold));
    }

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final days = _timeLeft.inDays;
    final hours = twoDigits(_timeLeft.inHours.remainder(24));
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    return Text(
      days > 0 ? '$days days $hours:$minutes:$seconds left' : '$hours:$minutes:$seconds left',
      style: TextStyle(
        color: days == 0 && _timeLeft.inHours < 24 ? Colors.red.shade700 : Colors.orange.shade800,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
