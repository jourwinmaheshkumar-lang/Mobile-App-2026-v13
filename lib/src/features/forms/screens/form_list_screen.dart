import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
            title: Text(
              localizationService.tr('dynamic_forms'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          body: StreamBuilder<List<FormModel>>(
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
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
                  itemCount: forms.length,
                  itemBuilder: (context, index) {
                    final form = forms[index];
                    return _buildFormCard(form, canManage);
                  },
                );
              },
            ),
          floatingActionButton: canManage
              ? Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () => _navigateToBuilder(context),
                    label: Text(
                      localizationService.tr('create_form'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assignment_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16, 
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Created ${DateFormat('MMM dd, yyyy').format(form.createdAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 10, 
                              color: AppTheme.textSecondary, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildAdminMenu(context),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.1) : const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildStatsSection(context),
                ),
                if (form.deadline != null) ...[
                  const SizedBox(height: 12),
                  _buildDeadlineInfo(isDark),
                ],
              ],
            ),
          ),
          _buildBottomAction(context, isDark),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                _buildStatItem('Pending', pending, const Color(0xFF6366F1)),
                _buildStatItem('Rejected', rejected, const Color(0xFFEF4444)),
                _buildStatItem('Total', total, isDark ? Colors.white70 : const Color(0xFF1E293B)),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(approved, pending, rejected, total, isDark),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 8, color: color.withOpacity(0.7), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildProgressBar(int approved, int pending, int rejected, int total, bool isDark) {
    if (total == 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final approvedWidth = approved / total;
    final pendingWidth = pending / total;
    final rejectedWidth = rejected / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        width: double.infinity,
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        child: Row(
          children: [
            if (approvedWidth > 0)
              Flexible(flex: (approvedWidth * 100).toInt(), child: Container(color: Colors.green)),
            if (pendingWidth > 0)
              Flexible(flex: (pendingWidth * 100).toInt(), child: Container(color: AppTheme.primary)),
            if (rejectedWidth > 0)
              Flexible(flex: (rejectedWidth * 100).toInt(), child: Container(color: AppTheme.error)),
            Flexible(flex: ((1 - approvedWidth - pendingWidth - rejectedWidth) * 100).toInt(), child: Container(color: Colors.blue.withOpacity(0.1))),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineInfo(bool isDark) {
    if (form.deadline == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(child: _CountdownTimer(deadline: form.deadline!)),
          Text(
            DateFormat('MM/dd HH:mm').format(form.deadline!),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.03),
        border: Border(top: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)).top),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onViewReports(form),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'DETAILED REPORTS',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary, 
                    fontWeight: FontWeight.w700, 
                    fontSize: 11, 
                    letterSpacing: 0.5,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate(form),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form.title, 
                            style: GoogleFonts.poppins(
                              fontSize: 15, 
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            form.description, 
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, 
                              fontSize: 11, 
                              fontWeight: FontWeight.w500,
                            ), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildUserStatus(isDark),
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

  Widget _buildUserStatus(bool isDark) {
    return FutureBuilder<AppUser?>(
      future: AuthService().currentAppUser,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        return FutureBuilder<FormSubmissionModel?>(
          future: repository.getUserSubmission(form.id, userSnap.data!.uid),
          builder: (context, snap) {
            final sub = snap.data;
            if (sub == null) {
              return _buildStatusPill(null, isDark);
            }
            return _buildStatusPill(sub.status, isDark);
          },
        );
      },
    );
  }

  Widget _buildStatusPill(SubmissionStatus? status, bool isDark) {
    Color color = isDark ? Colors.white38 : Colors.black38;
    String text = 'NOT SUBMITTED';
    
    if (status != null) {
      switch (status) {
        case SubmissionStatus.draft: color = const Color(0xFFF59E0B); text = 'DRAFT'; break;
        case SubmissionStatus.completed: color = const Color(0xFF6366F1); text = 'PENDING'; break;
        case SubmissionStatus.approved: color = const Color(0xFF10B981); text = 'APPROVED'; break;
        case SubmissionStatus.rejected: color = const Color(0xFFEF4444); text = 'REJECTED'; break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text, 
            style: GoogleFonts.poppins(
              color: color, 
              fontSize: 9, 
              fontWeight: FontWeight.w700, 
              letterSpacing: 0.5,
            ),
          ),
        ],
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
