import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/models/director.dart';
import '../directors/director_list_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import '../admin/user_management_screen.dart';
import '../companies/company_list_screen.dart';
import '../forms/screens/form_list_screen.dart';
import '../../core/services/notification_service.dart';
import './notification_list_screen.dart';
import '../../core/models/activity_log.dart';
import '../../core/services/activity_log_service.dart';
import '../../core/utils/company_data.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final repo = DirectorRepository();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    repo.loadAll().then((_) {
      setState(() {});
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToFiltered(DirectorFilter filter) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DirectorListScreen(filter: filter),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return StreamBuilder<AppUser?>(
      stream: AuthService().userStream,
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) return const Center(child: CircularProgressIndicator());
        
        final isAdmin = currentUser.role == UserRole.admin;
        final isOffice = currentUser.role == UserRole.officeTeam;
        final isDirector = currentUser.role == UserRole.director;

        return StreamBuilder<List<Director>>(
          stream: repo.directorsStream,
          builder: (context, snapshot) {
            final directors = snapshot.data ?? repo.all;
            final currentDirector = directors.where((d) => d.id == currentUser.directorId).firstOrNull;
            
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark 
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                      ]
                    : [
                        const Color(0xFFF8FAFF),
                        const Color(0xFFF1F5F9),
                      ],
                ),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Premium App Bar Header
                  _buildPremiumHeader(snapshot.connectionState, directors.length, currentUser),
                  
                  // Main Content
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isDirector)
                                _buildDirectorDashboard(directors, currentDirector, currentUser)
                              else ...[
                                _buildBirthdayAlerts(),
                                const SizedBox(height: 24),
                                // Metrics Section
                                _buildMetricsSection(),
                                
                                const SizedBox(height: 32),
                                _buildQuickActionsSection(isAdmin, currentUser),
                              ],
                              
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildPremiumHeader(ConnectionState connectionState, int totalDirectors, AppUser? user) {
    final displayName = user?.role == UserRole.admin ? 'Super Admin' : (user?.username ?? 'Director Hub');
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1a1a2e),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background Logo Watermark (Faded)
              Positioned(
                right: 10,
                top: 20,
                bottom: 20,
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              // Content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row - Status Badge
                      Row(
                        children: [
                          _buildLiveStatusBadge(connectionState),
                          const Spacer(),
                          if (user != null) _buildNotificationBell(user.uid),
                          const SizedBox(width: 8),
                          _buildSyncButton(),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Title
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37), // Dark gold
                            Color(0xFFFFD700), // Gold
                            Color(0xFFFFF8DC), // Light shine
                            Color(0xFFFFD700), // Gold
                            Color(0xFFD4AF37), // Dark gold
                          ],
                          stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                        ).createShader(bounds),
                        child: const Text(
                          'DJM Management System',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Stats Row
                      Row(
                        children: [
                          _buildStatPill(
                            Icons.people_rounded,
                            '$totalDirectors',
                            localizationService.tr('directors'),
                          ),
                          const SizedBox(width: 10),
                          _buildProBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatusBadge(ConnectionState connectionState) {
    final isSynced = connectionState == ConnectionState.active;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final accentColor = isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: isSynced ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isSynced ? localizationService.tr('live_synced') : localizationService.tr('syncing'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: Color(0xFF1E3A5F)),
          SizedBox(width: 4),
          Text(
            'PRO',
            style: TextStyle(
              color: Color(0xFF1E3A5F),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        repo.loadAll().then((_) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                  ),
                   const SizedBox(width: 12),
                   Text(localizationService.tr('synced_directors_msg', args: {'count': repo.totalCount.toString()})),
                 ],
               ),
               backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Icon(
          Icons.sync_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNotificationBell(String userId) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationListScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
            StreamBuilder<int>(
              stream: notificationService.getUnreadCount(userId),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();
                
                return Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizationService.tr('key_metrics'), Icons.insights_rounded),
        const SizedBox(height: 16),
        
        // Premium Metric Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 2;
            
            return Column(
              children: [
                Row(
                  children: [
                    _buildPremiumMetricCard(
                      width: cardWidth,
                      title: localizationService.tr('total_directors'),
                      value: '${repo.totalCount}',
                      icon: Icons.groups_rounded,
                      gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      delay: 0,
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                    const SizedBox(width: 16),
                    _buildPremiumMetricCard(
                      width: cardWidth,
                      title: localizationService.tr('no_din_proposal'),
                      value: '${repo.noDinCount}',
                      icon: Icons.warning_amber_rounded,
                      gradientColors: const [Color(0xFFEF4444), Color(0xFFF97316)],
                      delay: 100,
                      onTap: () => _navigateToFiltered(DirectorFilter.noDin),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildPremiumMetricCard(
                      width: cardWidth,
                      title: localizationService.tr('address_mismatch'),
                      value: '${repo.addressMismatchCount}',
                      icon: Icons.location_off_rounded,
                      gradientColors: const [Color(0xFFF59E0B), Color(0xFFEAB308)],
                      delay: 200,
                      onTap: () => _navigateToFiltered(DirectorFilter.addressMismatch),
                    ),
                    const SizedBox(width: 16),
                    _buildPremiumMetricCard(
                      width: cardWidth,
                      title: localizationService.tr('active_directors'),
                      value: '${repo.all.where((d) => d.status.toLowerCase() == "active").length}',
                      icon: Icons.check_circle_rounded,
                      gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
                      delay: 300,
                      onTap: () => _navigateToFiltered(DirectorFilter.activeOnly),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPremiumMetricCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: width,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: gradientColors[1].withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.2,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(bool isAdmin, AppUser? currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizationService.tr('quick_actions'), Icons.flash_on_rounded),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyListScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3), 
                  blurRadius: 15, 
                  offset: const Offset(0, 8)
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), 
                    borderRadius: BorderRadius.circular(14)
                  ),
                  child: const Icon(Icons.business_rounded, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Details', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'View registrations, CIN and incorporation dates', 
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FormListScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.assignment_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(localizationService.tr('dynamic_forms'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(localizationService.tr('fill_manage_forms'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            if (currentUser != null)
              StreamBuilder<int>(
                stream: notificationService.getUnreadCountByCategory(currentUser.uid, 'forms'),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        
        if (isAdmin) ...[
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.manage_accounts_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                 Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage Hub Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Promote roles and monitor access', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],

        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildQuickActionButton(
                icon: Icons.sync_rounded,
                label: localizationService.tr('sync'),
                color: const Color(0xFF6366F1),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  repo.loadAll().then((_) => setState(() {}));
                },
              ),
              _buildQuickActionButton(
                icon: Icons.badge_outlined,
                label: localizationService.tr('no_din'),
                color: const Color(0xFFEF4444),
                onTap: () => _navigateToFiltered(DirectorFilter.noDin),
              ),
              _buildQuickActionButton(
                icon: Icons.location_off_rounded,
                label: localizationService.tr('mismatch'),
                color: const Color(0xFFF59E0B),
                onTap: () => _navigateToFiltered(DirectorFilter.addressMismatch),
              ),
              _buildQuickActionButton(
                icon: Icons.check_circle_rounded,
                label: localizationService.tr('active'),
                color: const Color(0xFF10B981),
                onTap: () => _navigateToFiltered(DirectorFilter.activeOnly),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectorDashboard(
    List<Director> allDirectors, 
    Director? currentDirector, 
    AppUser currentUser
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Birthday Highlights
        _buildBirthdayAlerts(),
        
        const SizedBox(height: 24),
        
        // 1. Company Details Card
        _buildDirectorCompanyCard(currentDirector),
        
        const SizedBox(height: 20),
        
        // 2. DJM Form Card
        _buildDJMFormCard(),
        
        const SizedBox(height: 32),
        
        // 3. Recent Activity (last 10)
        _buildSectionHeader('Your Recent Activity', Icons.history_rounded),
        const SizedBox(height: 16),
        _buildDirectorActivityList(currentDirector?.id ?? '', currentUser.uid),
      ],
    );
  }

  Widget _buildBirthdayAlerts() {
    final companiesWithBirthday = CompanyData.companies.where((c) => c.isBirthdayThisMonth).toList();
    if (companiesWithBirthday.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A00E0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cake_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Celebration!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Birthday this month: ${companiesWithBirthday.take(2).map((c) => c.companyName).join(", ")}${companiesWithBirthday.length > 2 ? '...' : ''}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  Widget _buildDirectorCompanyCard(Director? director) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF6366F1);
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyListScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.business_rounded, color: primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Details',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${director?.companies.length ?? 0} Companies Assigned',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 16),
              ],
            ),
            if (director != null && director.companies.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Director Role', 'Active', isDark),
                  _buildMiniStat('Verification', 'Level 2', isDark),
                  _buildMiniStat('Profile', '90%', isDark),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildDJMFormCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FormListScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DJM Form',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    'Fill and submit forms directly',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorActivityList(String directorId, String userId) {
    return StreamBuilder<List<ActivityLog>>(
      stream: ActivityLogService().getDirectorActivityStream(directorId, userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        
        final logs = snapshot.data!;
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No recent activity',
              style: TextStyle(color: Colors.grey.withOpacity(0.5)),
            ),
          );
        }

        return Column(
          children: logs.map((log) => _buildActivityItem(log)).toList(),
        );
      },
    );
  }

  Widget _buildActivityItem(ActivityLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getActivityColor(log.action).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getActivityIcon(log.action), color: _getActivityColor(log.action), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.details,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(log.timestamp),
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityAction action) {
    switch (action) {
      case ActivityAction.create: return Colors.green;
      case ActivityAction.update: return Colors.blue;
      case ActivityAction.delete: return Colors.red;
      case ActivityAction.export: return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getActivityIcon(ActivityAction action) {
    switch (action) {
      case ActivityAction.create: return Icons.add_circle_outline_rounded;
      case ActivityAction.update: return Icons.edit_note_rounded;
      case ActivityAction.delete: return Icons.delete_outline_rounded;
      case ActivityAction.export: return Icons.ios_share_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }
}
