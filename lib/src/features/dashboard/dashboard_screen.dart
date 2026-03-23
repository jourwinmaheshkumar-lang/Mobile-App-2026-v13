import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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
import '../projects/projects_screen.dart';
import '../club/club_screen.dart';
import '../structure/office_structure_screen.dart';
import 'dart:math' as math;
import '../../core/services/notification_service.dart';
import '../../core/services/activity_log_service.dart';
import '../../core/models/company.dart';
import '../../core/utils/company_data.dart';
import '../biometrics/biometric_scanner_sheet.dart';
import '../../core/models/activity_log.dart';
import 'widgets/celebration_card.dart';
import 'notification_list_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final PageController _celebrationPageController = PageController(viewportFraction: 0.92);

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
    _celebrationPageController.dispose();
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
                        AppTheme.background,
                        AppTheme.surface,
                      ]
                    : [
                        AppTheme.background,
                        const Color(0xFFF1F1F1),
                      ],
                ),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // SECTION 1 — HEADER
                  _buildPremiumHeader(snapshot.connectionState, directors, currentUser, repo),
                  
                  // Main Content
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SECTION 2 & 3 — ANNIVERSARY CARD
                              _buildFeaturedBirthdays(directors),
                              const SizedBox(height: 24),

                              if (isDirector)
                                _buildDirectorDashboard(directors, currentDirector, currentUser)
                              else ...[
                                // SECTION 4 — KEY METRICS GRID
                                _buildMetricsSection(),
                                const SizedBox(height: 32),
                                // SECTION 5 — QUICK ACTIONS
                                _buildQuickActionsSection(isAdmin, currentUser),
                              ],
                              
                              const SizedBox(height: 20),
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

  Widget _buildPremiumHeader(ConnectionState connectionState, List<Director> directors, AppUser? user, DirectorRepository repo) {
    final displayName = user?.role == UserRole.admin ? 'Super Admin' : (user?.username ?? 'Director Hub');
    final now = DateTime.now();
    String greeting = "Good Morning";
    if (now.hour >= 12 && now.hour < 17) greeting = "Good Afternoon";
    else if (now.hour >= 17) greeting = "Good Evening";

    return SliverAppBar(
      expandedHeight: 220,
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0, 
      backgroundColor: const Color(0xFF5C1228),
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      flexibleSpace: FlexibleSpaceBar(
        expandedTitleScale: 1, 
        background: Stack(
          clipBehavior: Clip.none, 
          children: [
            // Multi-stop gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5C1228),   // very deep wine
                    Color(0xFF8B1F45),   // dark plum
                    Color(0xFFC03060),   // purple-red
                    Color(0xFFFA425A),   // coral red
                    Color(0xFFF6753A),   // orange-red
                    Color(0xFFF37950),   // warm orange
                  ],
                  stops: [0.0, 0.18, 0.38, 0.62, 0.82, 1.0],
                ),
              ),
            ),
            // Diagonal Texture Overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.022,
                child: CustomPaint(
                  painter: DiagonalTexturePainter(),
                ),
              ),
            ),
            // Decorative Circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Header Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 60), 
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Side: Greeting + Name + Badge
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$greeting,",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'DJM MANAGEMENT SYSTEM',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.58),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4AE8A0),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Administrator',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right Side: Logo with Rings
                    SizedBox(
                      width: 94,               // Increased size
                      height: 94,              // Increased size
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF6BC59).withOpacity(0.70),
                            width: 2.5,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3E2723), 
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              width: 78,       // Increased image size
                              height: 78,      // Increased image size
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Curved Bottom
            Positioned(
              bottom: -32,
              left: -12,
              right: -12,
              child: Container(
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F4F6),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(200),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Transform.translate(
          offset: const Offset(0, 12), // Shift downward to overlap body
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF813563).withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFloatingStat(directors.length.toString(), 'Directors', const Color(0xFFFA425A)),
                _buildVerticalDivider(),
                _buildFloatingStat(directors.where((d) => d.status.toLowerCase() == "active").length.toString(), 'Active', const Color(0xFF1E9D8A)),
                _buildVerticalDivider(),
                _buildFloatingStat(directors.where((d) => (d.din ?? '').isEmpty).length.toString(), 'No DIN', const Color(0xFFC9920A)),
                _buildVerticalDivider(),
                _buildFloatingStat(repo.addressMismatchCount.toString(), 'Mismatch', const Color(0xFF813563)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB09AB0),
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFF0F0F0),
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
        Text(
          "Key Metrics",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF813563),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.3,   // Increased to 1.3 to remove gaps
          children: [
            _buildMetricCard(
              label: "Total Directors",
              value: repo.totalCount.toString(),
              cardIcon: Icons.people,
              accentColor: const Color(0xFFFA425A),
              onTap: () => widget.onNavigate?.call(1),
            ),
            _buildMetricCard(
              label: "No DIN/Proposal",
              value: repo.noDinCount.toString(),
              cardIcon: Icons.warning_amber_rounded,
              accentColor: const Color(0xFF813563),
              onTap: () => _navigateToFiltered(DirectorFilter.noDin),
            ),
            _buildMetricCard(
              label: "Address Mismatch",
              value: repo.addressMismatchCount.toString(),
              cardIcon: Icons.location_off,
              accentColor: const Color(0xFFC9920A),
              onTap: () => _navigateToFiltered(DirectorFilter.addressMismatch),
            ),
            _buildMetricCard(
              label: "Active Directors",
              value: repo.all.where((d) => d.status.toLowerCase() == "active").length.toString(),
              cardIcon: Icons.check_circle_outline,
              accentColor: const Color(0xFF1E9D8A),
              onTap: () => _navigateToFiltered(DirectorFilter.activeOnly),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData cardIcon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // ADD THIS LINE for perfect corner clipping
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                color: accentColor, // SIMPLIFIED: Radius now handled by clipBehavior
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cardIcon, color: accentColor, size: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      fontFamilyFallback: ['Arial'],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9E9E9E),
                      fontFamilyFallback: ['Arial'],
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
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFA425A), Color(0xFFF37950)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              "Quick Actions",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D1B2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActionTile(
                tileName: 'Corporate Architecture',
                tileSub: 'Hierarchy, Offices & Staff Posting',
                tileIcon: Icons.account_tree_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OfficeStructureScreen())),
              ),
              _buildActionTile(
                tileName: 'Elite Clubs',
                tileSub: 'Exclusive member positions',
                tileIcon: Icons.star_rounded,
                iconBg: const Color(0xFFFEF8E8),
                iconColor: const Color(0xFFC9920A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClubScreen())),
              ),
              _buildActionTile(
                tileName: 'Our Projects',
                tileSub: 'Manage & track all projects',
                tileIcon: Icons.rocket_launch,
                iconBg: const Color(0xFFFEE9EC),
                iconColor: const Color(0xFFFA425A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectsScreen())),
              ),
              _buildActionTile(
                tileName: 'Notifications',
                tileSub: 'View all your notifications',
                tileIcon: Icons.notifications_rounded,
                iconBg: const Color(0xFFF5E8EF),
                iconColor: const Color(0xFF813563),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationListScreen())),
              ),
              _buildActionTile(
                tileName: 'Company Details',
                tileSub: 'CIN and incorporation dates',
                tileIcon: Icons.business_rounded,
                iconBg: const Color(0xFFE3F5F2),
                iconColor: const Color(0xFF1E9D8A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyListScreen())),
              ),
              _buildActionTile(
                tileName: 'Biometric Search',
                tileSub: 'Scan finger for records',
                tileIcon: Icons.fingerprint,
                iconBg: const Color(0xFFFEE9EC),
                iconColor: const Color(0xFFFA425A),
                onTap: _showBiometricSearch,
              ),
              _buildActionTile(
                tileName: 'DJM Form',
                tileSub: 'Fill and submit forms',
                tileIcon: Icons.assignment_rounded,
                iconBg: const Color(0xFFFEF8E8),
                iconColor: const Color(0xFFC9920A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FormListScreen())),
              ),
              if (isAdmin)
                _buildActionTile(
                  tileName: 'Manage Hub Users',
                  tileSub: 'Monitor user access',
                  tileIcon: Icons.manage_accounts,
                  iconBg: const Color(0xFFF5E8EF),
                  iconColor: const Color(0xFF813563),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen())),
                  isLast: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String tileName,
    required String tileSub,
    required IconData tileIcon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF9F5F8), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(tileIcon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tileName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D1B2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tileSub,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFB09AB0),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD0C0CC), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
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
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.black12,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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

   Widget _buildFeaturedBirthdays(List<Director> allDirectors) {
    final now = DateTime.now();
    final allCompanies = CompanyData.companies;
    
    // 1. Separate Today and Others
    final todayCelebrations = allCompanies.where((c) => c.isAnniversaryToday).toList();
    final otherCelebrations = allCompanies.where((c) => !c.isAnniversaryToday).toList();

    // 2. Sort others by next anniversary closeness
    otherCelebrations.sort((a, b) {
      final aDate = a.incorporationDateTime;
      final bDate = b.incorporationDateTime;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      
      DateTime nextA = DateTime(now.year, aDate.month, aDate.day);
      if (nextA.isBefore(DateTime(now.year, now.month, now.day))) nextA = DateTime(now.year + 1, aDate.month, aDate.day);
      
      DateTime nextB = DateTime(now.year, bDate.month, bDate.day);
      if (nextB.isBefore(DateTime(now.year, now.month, now.day))) nextB = DateTime(now.year + 1, bDate.month, bDate.day);
      
      return nextA.compareTo(nextB);
    });

    // 3. Select 1 Today (if exists) and 1 Upcoming
    Company? todayHero = todayCelebrations.isNotEmpty ? todayCelebrations.first : null;
    Company? upcomingCompact = otherCelebrations.isNotEmpty ? otherCelebrations.first : null;

    if (todayHero == null && upcomingCompact == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 12),
          child: Column(
            children: [
              if (todayHero != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CelebrationCard(
                    company: todayHero,
                    directors: allDirectors.where((d) => 
                      d.companies.any((c) => c.companyName.trim().toLowerCase() == todayHero.companyName.trim().toLowerCase())
                    ).toList(),
                    isCompact: false, // Hero view
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => CompanyListScreen(initialSearchQuery: todayHero.companyName))
                    ),
                  ),
                ),
              if (upcomingCompact != null)
                CelebrationCard(
                  company: upcomingCompact,
                  directors: allDirectors.where((d) => 
                    d.companies.any((c) => c.companyName.trim().toLowerCase() == upcomingCompact.companyName.trim().toLowerCase())
                  ).toList(),
                  isCompact: true, // Compact view for upcoming
                  onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => CompanyListScreen(initialSearchQuery: upcomingCompact.companyName))
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildDirectorCompanyCard(Director? director) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.primary;
    
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
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${director?.companies.length ?? 0} Companies Assigned',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
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
          style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
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
          children: logs.map<Widget>((log) => _buildActivityItem(log)).toList(),
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

  void _showBiometricSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BiometricScannerSheet(
        mode: BiometricMode.identify,
        onIdentified: (director) {
          _showDirectorDetails(director);
        },
      ),
    );
  }

  void _showDirectorDetails(Director director) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 32),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(director.name.isNotEmpty ? director.name[0] : '?', style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(director.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      Text('DIN: ${director.din}', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('FOUND', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailRow(Icons.email_outlined, 'Email', director.email),
            _buildDetailRow(Icons.phone_outlined, 'Phone', director.bankLinkedPhone),
            _buildDetailRow(Icons.pin_drop_outlined, 'Address', director.aadhaarAddress),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text(value.isEmpty ? 'Not Provided' : value, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DiagonalTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.022) // Fix 2
      ..strokeWidth = 0.5; // Fix 2

    for (double i = -size.height; i < size.width; i += 24) { // Fix 2 spacing
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

extension DirectorExtension on Director {
  bool get hasAddressMismatch {
    // Current logic from previous conversations or repo
    // Placeholder if not defined: assuming addressMismatchCount uses some criteria
    // We'll use a check if available or just false for now if not defined, 
    // but the user said "do not change logic", so I should try to find where addressMismatch is determined.
    // In DashboardScreen, repo.addressMismatchCount is used.
    // I will use totalDirectors/active/noDin/mismatch based on repo stats passed in.
    return false; // This is just for the badge, but I'll use repo counts directly in the header.
  }
}
