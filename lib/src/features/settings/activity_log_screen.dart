import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/activity_log_service.dart';
import '../../core/models/activity_log.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark),
          _buildLogList(isDark),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppTheme.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          localizationService.tr('activity_log'),
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.delete_sweep_outlined,
            color: isDark ? Colors.white70 : AppTheme.textSecondary,
          ),
          onPressed: () => _confirmClearLogs(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLogList(bool isDark) {
    return StreamBuilder<List<ActivityLog>>(
      stream: activityLogService.activityStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(isDark),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final log = logs[index];
                final showDateHeader = index == 0 || 
                    _formatDate(logs[index-1].timestamp) != _formatDate(log.timestamp);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader) _buildDateHeader(log.timestamp, isDark),
                    _buildLogTile(log, isDark),
                  ],
                );
              },
              childCount: logs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);
    
    String label = DateFormat('MMMM d, yyyy').format(date);
    if (logDate == today) {
      label = 'Today';
    } else if (logDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLogTile(ActivityLog log, bool isDark) {
    final (icon, color) = _getActionColor(log.action);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderLight : AppTheme.borderLight,
        ),
        boxShadow: isDark ? null : AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getEntityLabel(log.entityType),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(log.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '${log.entityName} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: log.details.toLowerCase(),
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${log.userId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Activity Recorded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System actions will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _getEntityLabel(EntityType type) {
    switch (type) {
      case EntityType.director: return 'DIRECTOR';
      case EntityType.report: return 'CAMPAIGN';
      case EntityType.campaign: return 'CAMPAIGN';
      case EntityType.system: return 'SYSTEM';
      case EntityType.form: return 'FORM';
    }
  }

  (IconData, Color) _getActionColor(ActivityAction action) {
    switch (action) {
      case ActivityAction.create: return (Icons.add_circle_outline_rounded, AppTheme.success);
      case ActivityAction.update: return (Icons.edit_note_rounded, AppTheme.info);
      case ActivityAction.delete: return (Icons.delete_outline_rounded, AppTheme.error);
      case ActivityAction.restore: return (Icons.restore_rounded, Colors.teal);
      case ActivityAction.permanentDelete: return (Icons.delete_forever_rounded, AppTheme.error);
      case ActivityAction.export: return (Icons.ios_share_rounded, Colors.purple);
      case ActivityAction.sync: return (Icons.sync_rounded, AppTheme.primary);
    }
  }

  void _confirmClearLogs(BuildContext context) {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Clear Activity Log?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently delete all activity records.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizationService.tr('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      onPressed: () {
                        activityLogService.clearLogs();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
