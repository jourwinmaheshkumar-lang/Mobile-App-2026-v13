import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/text_utils.dart';
import '../../../main.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import '../auth/login_screen.dart';
import 'activity_log_screen.dart';
import '../../core/services/update_service.dart';
import '../../core/models/version_info.dart';
import 'package:ota_update/ota_update.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometric = true;
  bool _notifications = true;
  
  VersionInfo? _serverVersion;
  bool _isCheckingUpdate = false;
  double? _downloadProgress;
  String? _downloadStatus;
  String _currentVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentVersion = await updateService.getCurrentVersion();
    if (mounted) setState(() {});
    _checkForUpdates(silent: true);
  }

  Future<void> _checkForUpdates({bool silent = false}) async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    
    try {
      final available = await updateService.isUpdateAvailable();
      if (available) {
        _serverVersion = await updateService.getLatestVersion();
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App is up to date! ✅')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  void _runUpdate() {
    if (_serverVersion == null || _downloadStatus == 'DOWNLOADING') return;
    
    HapticFeedback.heavyImpact();
    
    updateService.downloadAndInstall(_serverVersion!.downloadUrl).listen(
      (OtaEvent event) {
        if (!mounted) return;
        setState(() {
          _downloadStatus = event.status.name;
          if (event.value != null) {
            _downloadProgress = double.tryParse(event.value!) ?? 0;
          }
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _downloadStatus = 'FAILED';
          _downloadProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installation failed. Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _runUpdate,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return StreamBuilder<AppUser?>(
      stream: AuthService().userStream,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final role = user?.role ?? UserRole.director;

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                stretch: true,
                backgroundColor: bgColor,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    localizationService.tr('settings'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: Container(
                    color: bgColor,
                  ),
                ),
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Card
                    _buildProfileCard(context, user),
                    
                    const SizedBox(height: 32),
                    
                    // Security Section
                    _buildSectionHeader(localizationService.tr('security')),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      icon: Icons.fingerprint_rounded,
                      title: localizationService.tr('biometric_login'),
                      subtitle: localizationService.tr('use_face_fingerprint'),
                      value: _biometric,
                      onChanged: (v) => setState(() => _biometric = v),
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your login password',
                      onTap: () => _showChangePasswordDialog(context),
                      color: AppTheme.warning,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      icon: Icons.notifications_active_rounded,
                      title: localizationService.tr('push_notifications'),
                      subtitle: localizationService.tr('receive_alerts'),
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                      color: AppTheme.warning,
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Preferences Section
                    _buildSectionHeader(localizationService.tr('preferences')),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      icon: Icons.dark_mode_rounded,
                      title: localizationService.tr('dark_mode'),
                      subtitle: localizationService.tr('switch_dark_theme'),
                      value: themeService.isDarkMode,
                      onChanged: (v) async {
                        await themeService.setDarkMode(v);
                        setState(() {});
                        HapticFeedback.mediumImpact();
                      },
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.language_rounded,
                      title: localizationService.tr('language'),
                      subtitle: localizationService.currentLanguageName,
                      onTap: () => _showLanguageSheet(context),
                    ),
                    const SizedBox(height: 28),
                    
                    // Text Display Section
                    _buildSectionHeader(localizationService.tr('text_display')),
                    const SizedBox(height: 12),
                    _buildCaseFormatSelector(),
                    
                    const SizedBox(height: 28),
                    
                    // Data Section
                    _buildSectionHeader(localizationService.tr('data_sync')),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.cloud_sync_rounded,
                      title: localizationService.tr('sync_data'),
                      subtitle: localizationService.tr('last_synced'),
                      onTap: () => _showSnackBar(context, localizationService.tr('syncing_data')),
                      color: AppTheme.info,
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.backup_rounded,
                      title: localizationService.tr('backup'),
                      subtitle: localizationService.tr('create_backup'),
                      onTap: () => _showSnackBar(context, localizationService.tr('creating_backup')),
                      color: AppTheme.success,
                    ),
                    
                    const SizedBox(height: 12),
                    if (_serverVersion != null) ...[
                      _buildUpdateBanner(),
                      const SizedBox(height: 12),
                    ],
                    _buildActionTile(
                      icon: Icons.system_update_rounded,
                      title: 'Check for Updates',
                      subtitle: _isCheckingUpdate ? 'Checking...' : 'Check if a newer version is available',
                      onTap: () => _checkForUpdates(silent: false),
                      color: AppTheme.primary,
                    ),
                    if (role == UserRole.admin) ...[
                      const SizedBox(height: 12),
                      _buildActionTile(
                        icon: Icons.history_rounded,
                        title: localizationService.tr('activity_log'),
                        subtitle: localizationService.tr('view_activity'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ActivityLogScreen()),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 28),
                    
                    // About Section
                    _buildSectionHeader(localizationService.tr('about')),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.info_outline_rounded,
                      title: localizationService.tr('about_app'),
                      subtitle: localizationService.tr('version'),
                      onTap: () => _showAboutDialog(context),
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.help_outline_rounded,
                      title: localizationService.tr('help_support'),
                      subtitle: localizationService.tr('get_help'),
                      onTap: () => _showSnackBar(context, localizationService.tr('opening_help')),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Logout Button
                    _buildLogoutButton(context),
                    
                    const SizedBox(height: 32),
                    
                    // Version Info
                    Center(
                      child: Column(
                        children: [
                          Text(
                            localizationService.tr('app_name'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v$_currentVersion',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, AppUser? user) {
    final role = user?.role ?? UserRole.director;
    final name = user?.displayName ?? (role == UserRole.admin ? 'Administrator' : (user?.username ?? 'Guest'));
    final username = user?.username ?? '';
    final roleName = role.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.darkGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        textUtils.format(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (role == UserRole.admin)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
                        onPressed: () => _showEditProfileSheet(context, user!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (username.isNotEmpty && role != UserRole.admin)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'DIN: $username',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppTheme.success,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        roleName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? color,
  }) {
    final tileColor = color ?? AppTheme.primary;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorderLight : AppTheme.borderLight;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textTertiary = isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: isDark ? null : AppTheme.softShadow,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tileColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: tileColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 30,
                  decoration: BoxDecoration(
                    color: value ? AppTheme.success : (isDark ? AppTheme.darkBorder : AppTheme.border),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        left: value ? 24 : 2,
                        top: 2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkTextPrimary : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? AppTheme.textSecondary;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorderLight : AppTheme.borderLight;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textTertiary = isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary;
    final surfaceVariant = isDark ? AppTheme.darkSurfaceVariant : AppTheme.surfaceVariant;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: isDark ? null : AppTheme.softShadow,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tileColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: tileColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: textTertiary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaseFormatSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorderLight : AppTheme.borderLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: isDark ? null : AppTheme.softShadow,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.text_format_rounded, color: AppTheme.info, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizationService.tr('name_case_format'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      localizationService.tr('choose_case_display'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCaseOption('titleCase', localizationService.tr('title_case'), isSelected: textUtils.currentFormat == 'titleCase'),
          const SizedBox(height: 8),
          _buildCaseOption('uppercase', localizationService.tr('uppercase'), isSelected: textUtils.currentFormat == 'uppercase'),
          const SizedBox(height: 8),
          _buildCaseOption('lowercase', localizationService.tr('lowercase'), isSelected: textUtils.currentFormat == 'lowercase'),
        ],
      ),
    );
  }

  Widget _buildCaseOption(String format, String label, {required bool isSelected}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String example = 'Hello World';
    if (format == 'uppercase') example = 'HELLO WORLD';
    if (format == 'lowercase') example = 'hello world';
    if (format == 'titleCase') example = 'Hello World';

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await textUtils.setFormat(format);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary.withOpacity(0.1) 
              : (isDark ? AppTheme.darkSurfaceVariant : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : (isDark ? AppTheme.darkBorder : AppTheme.border),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primary : (isDark ? Colors.white70 : AppTheme.textSecondary),
              ),
            ),
            const Text(' — ', style: TextStyle(color: AppTheme.textTertiary)),
            Expanded(
              child: Text(
                example,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.textTertiary),
                ),
              ),
            ),
            if (isSelected) 
              Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmLogout(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.error,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  localizationService.tr('logout'),
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.primaryShadow,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Director Hub Pro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version $_currentVersion',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizationService.tr('about_app_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFCBD5E1) : AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizationService.tr('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localizationService.tr('logout'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizationService.tr('logout_confirm_msg'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : AppTheme.border),
                      ),
                       child: Text(localizationService.tr('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const LoginScreen(),
                            transitionDuration: const Duration(milliseconds: 400),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(localizationService.tr('logout'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showLanguageSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: isDark ? const Border(top: BorderSide(color: Color(0xFF334155))) : null,
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            
            Text(
              localizationService.tr('select_language'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // English Option
            _buildLanguageOption(
              context: context,
              langCode: 'en',
              title: 'English',
              subtitle: localizationService.tr('default_language_desc'),
              flag: '🇬🇧',
              isSelected: localizationService.currentLanguage == 'en',
            ),
            const SizedBox(height: 12),
            
            // Tamil Option
            _buildLanguageOption(
              context: context,
              langCode: 'ta',
              title: 'தமிழ்',
              subtitle: 'Tamil',
              flag: '🇮🇳',
              isSelected: localizationService.currentLanguage == 'ta',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String langCode,
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await localizationService.setLanguage(langCode);
        Navigator.pop(context);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary.withOpacity(0.1) 
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primary 
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected 
                          ? AppTheme.primary 
                          : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AppUser user) {
    final nameController = TextEditingController(text: user.displayName);
    final usernameController = TextEditingController(text: user.username);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                enabled: user.role == UserRole.admin,
                decoration: InputDecoration(
                  labelText: user.role == UserRole.admin ? 'Username' : 'DIN (ReadOnly)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().updateProfile(
                      displayName: nameController.text,
                      username: user.role == UserRole.admin ? usernameController.text : null,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      _showSnackBar(context, 'Profile updated successfully');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a new password for your account.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 4) {
                _showSnackBar(context, 'Password must be at least 4 characters');
                return;
              }
              await AuthService().changePassword(passwordController.text);
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar(context, 'Password updated successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner() {
    if (_serverVersion == null) return const SizedBox.shrink();
    
    final isDownloading = _downloadProgress != null && _downloadStatus == 'DOWNLOADING';
    final isCompleted = _downloadStatus == 'INSTALLING';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD946EF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Update: v${_serverVersion!.latestVersion}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _serverVersion!.changelog,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _downloadProgress! / 100,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading: ${_downloadProgress!.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ] else if (isCompleted) ...[
            const Center(
              child: Text(
                'Opening Installer...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _runUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('UPDATE NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
        ],
      ),
    );
  }
}
