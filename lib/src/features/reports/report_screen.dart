import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/services/localization_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final repo = DirectorRepository();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Premium SliverAppBar
          _buildAppBar(isDark),
          
          // Analytical Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header with micro-animation
                _buildAnimatedHeader(isDark),
                const SizedBox(height: 28),
                
                // Dynamic Distribution Card (Glassmorphism feel)
                FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.7)),
                  child: _buildReportCard(
                    context: context,
                    title: localizationService.tr('directorship_distribution'),
                    subtitle: localizationService.tr('active_inactive_status'),
                    icon: Icons.pie_chart_rounded,
                    color: AppTheme.primary,
                    content: _buildDistributionChart(context, repo),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Integrity & Compliance
                FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.3, 0.8)),
                  child: _buildReportCard(
                    context: context,
                    title: localizationService.tr('data_integrity'),
                    subtitle: "System Completion & Validation",
                    icon: Icons.verified_user_rounded,
                    color: AppTheme.success,
                    content: Column(
                      children: [
                        _buildProgressRow(context, "Profile Data", 0.92, AppTheme.primary),
                        const SizedBox(height: 18),
                        _buildProgressRow(context, "DIN Records", 1.0, AppTheme.success),
                        const SizedBox(height: 18),
                        _buildProgressRow(context, "Contact KYC", 0.78, AppTheme.warning),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // High-Impact Stats Grid
                _buildStaggeredStats(isDark),
                
                const SizedBox(height: 32),
                
                // Premium Quick Action
                FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.6, 1.0)),
                  child: _buildQuickReportAction(context),
                ),
                
                const SizedBox(height: 20),
                
                // Main Export Master Report
                FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.7, 1.0)),
                  child: _buildExportButton(context, repo),
                ),
                
                const SizedBox(height: 60),
              ]),
            ),
          ),
          // Premium Fintech Header
          _buildAppBar(),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("OVERVIEW ANALYSIS"),
                  const SizedBox(height: 16),
                  _buildMainStatsGrid(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader("DATA INTEGRITY"),
                  const SizedBox(height: 16),
                  _buildIntegrityCard(),
                  const SizedBox(height: 24),

                  _buildSectionHeader("DIRECTORSHIP DISTRIBUTION"),
                  const SizedBox(height: 16),
                  _buildDistributionCard(),
                  const SizedBox(height: 32),

                  _buildSectionHeader("EXECUTIVE ACTIONS"),
                  const SizedBox(height: 16),
                  _buildQuickActionAudit(),
                  const SizedBox(height: 16),
                  _buildExportMasterButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      backgroundColor: const Color(0xFF7C3AED),
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFC026D3), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: 20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.analytics_rounded, size: 150, color: Colors.white),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "LIVE ENGINE ANALYTICS",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizationService.tr('reports'),
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildAnimatedHeader(bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.05, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizationService.tr('analytics_overview'),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      "Last updated 5 mins ago",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredStats(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPremiumStatCard(
                title: localizationService.tr('total_records'),
                value: '${repo.totalCount}',
                label: 'Profiles',
                icon: Icons.folder_copy_rounded,
                color: AppTheme.primary,
                delay: 0.4,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPremiumStatCard(
                title: localizationService.tr('active'),
                value: '${repo.activeCount}',
                label: 'Compliant',
                icon: Icons.check_circle_rounded,
                color: AppTheme.success,
                delay: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPremiumStatCard(
                title: localizationService.tr('issues'),
                value: '${repo.noDinCount + repo.addressMismatchCount}',
                label: 'Action Required',
                icon: Icons.assignment_late_rounded,
                color: AppTheme.warning,
                delay: 0.6,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPremiumStatCard(
                title: 'Data Sync',
                value: '100%',
                label: 'Real-time',
                icon: Icons.sync_lock_rounded,
                color: AppTheme.accent,
                delay: 0.7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumStatCard({
    required String title,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required double delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Interval(delay, 1.0, curve: Curves.easeOutBack)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          content,
        ],
      ),
    );
  }

  Widget _buildDistributionChart(BuildContext context, DirectorRepository repo) {
    final activePercent = repo.activePercentage / 100;
    final inactivePercent = 1 - activePercent;
    
    return Row(
      children: [
        _buildChartBar(localizationService.tr('active'), activePercent, AppTheme.success),
        const SizedBox(width: 24),
        _buildChartBar(localizationService.tr('inactive'), inactivePercent, AppTheme.error),
      ],
    );
  }

  Widget _buildChartBar(String label, double percent, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutQuart,
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context, String label, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, _) => LinearProgressIndicator(
                value: animValue,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReportAction(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.premiumGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            _showSnackBar(context, "Initializing Audit Intelligence...");
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizationService.tr('quarterly_audit_report'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Run proprietary AI compliance audit",
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, DirectorRepository repo) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.25),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showSnackBar(context, localizationService.tr('download_success_msg'));
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_motion_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 14),
                Text(
                  localizationService.tr('export_master_report').toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
