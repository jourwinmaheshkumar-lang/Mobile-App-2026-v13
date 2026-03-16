import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/models/notification.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import '../forms/screens/form_list_screen.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().userStream,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context, user),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF8FAFF), const Color(0xFFF1F5F9)],
              ),
            ),
            child: StreamBuilder<List<NotificationModel>>(
              stream: notificationService.getNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final notifications = snapshot.data ?? [];
                
                if (notifications.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(context, notifications[index], user.uid);
                  },
                );
              },
            ),
          ),
        );
      }
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppUser user) {
    return AppBar(
      title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all_rounded),
          tooltip: 'Mark all as read',
          onPressed: () {
            HapticFeedback.mediumImpact();
            notificationService.markAllAsRead(user.uid);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded),
          tooltip: 'Clear all',
          onPressed: () => _confirmClearAll(context, user.uid),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.textTertiary.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent activity will appear here.',
            style: TextStyle(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

   Widget _buildNotificationCard(BuildContext context, NotificationModel note, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    IconData icon;
    Color color;
    switch (note.type) {
      case NotificationType.success:
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF10B981);
        break;
      case NotificationType.warning:
        icon = Icons.warning_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case NotificationType.error:
        icon = Icons.error_rounded;
        color = const Color(0xFFEF4444);
        break;
      case NotificationType.info:
      default:
        icon = Icons.info_rounded;
        color = const Color(0xFF6366F1);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: note.isRead ? (isDark ? Colors.white.withOpacity(0.03) : Colors.white) : (isDark ? Colors.white.withOpacity(0.07) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: note.isRead ? Colors.transparent : color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: note.isRead ? [] : [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!note.isRead) notificationService.markAsRead(userId, note.id);
            _handleNotificationClick(context, note);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: TextStyle(
                                fontWeight: note.isRead ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 16,
                                color: note.isRead ? AppTheme.textSecondary : null,
                              ),
                            ),
                          ),
                          if (!note.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.message,
                        style: TextStyle(
                          color: note.isRead ? AppTheme.textTertiary : AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, hh:mm a').format(note.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (note.clickAction != null)
                             const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationClick(BuildContext context, NotificationModel note) {
    if (note.clickAction == 'open_form_list') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => FormListScreen()));
    }
  }

  void _confirmClearAll(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will permanently delete all your notification history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notificationService.clearAll(userId);
              Navigator.pop(context);
            },
            child: const Text('CLEAR ALL', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
