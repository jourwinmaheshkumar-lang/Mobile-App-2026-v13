import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/models/report.dart';
import '../../core/repositories/report_repository.dart';
import '../../core/repositories/director_repository.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> 
    with SingleTickerProviderStateMixin {
  final _repo = ReportRepository();
  final _directorRepo = DirectorRepository();
  late AnimationController _animController;
  int _totalDirectors = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();
    _loadTotalDirectors();
  }

  Future<void> _loadTotalDirectors() async {
    final directors = await _directorRepo.loadAll();
    if (mounted) {
      setState(() {
        _totalDirectors = directors.length;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: StreamBuilder<List<Report>>(
        stream: _repo.reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
          // 170px Fintech-Grade Obsidian Header with Dual Mesh Gradient
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Base Obsidian / Dark Surface
                  Container(color: isDark ? const Color(0xFF020617) : const Color(0xFF0F172A)),
                  // Layer 2: Mesh Radial Gradient (Top Right)
                  Positioned(
                    top: -100,
                    right: -50,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isDark ? const Color(0xFF1E293B) : const Color(0xFF1E293B)).withOpacity(0.8),
                            (isDark ? const Color(0xFF020617) : const Color(0xFF0F172A)).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Layer 3: Subtle Emerald Ambient Glow (Bottom Left)
                  Positioned(
                    bottom: -50,
                    left: -50,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF10B981).withOpacity(isDark ? 0.08 : 0.05),
                            (isDark ? const Color(0xFF020617) : const Color(0xFF0F172A)).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content aligned precisely to bottom
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                localizationService.tr('reports'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 32,
                                  letterSpacing: -1.5,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            // Compact + Button with Vibrant Glow
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showCreateReportSheet();
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Solid Assignments Pill
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'ASSIGNMENTS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.4),
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

          // Glassmorphic Segmented Control / Tabs
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizationService.tr('RECENT SURVEYS'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        localizationService.tr('EFFICIENCY'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

              // Redesigned 10x Polished Report Cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = reports[index];
                      return AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final delay = index * 0.08;
                          final animation = CurvedAnimation(
                            parent: _animController,
                            curve: Interval(
                              delay.clamp(0.0, 0.6),
                              (delay + 0.4).clamp(0.0, 1.0),
                              curve: Curves.easeOutQuart,
                            ),
                          );
                          return Transform.translate(
                            offset: Offset(0, 40 * (1 - animation.value)),
                            child: Opacity(
                              opacity: animation.value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildReportCard(report, index),
                      );
                    },
                    childCount: reports.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
            const SizedBox(height: 24),
            Text(
              'Database Error',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Reports Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first report to start\ncategorizing and tracking directors',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _showCreateReportSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Create Your First Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
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

  Widget _buildReportCard(Report report, int index) {
    final assignedCount = report.allAssignedDirectorIds.length;
    final progress = _totalDirectors > 0 
        ? (assignedCount / _totalDirectors).clamp(0.0, 1.0) 
        : 0.0;
    
    final isSingle = report.selectionMode == SelectionMode.single;
    
    // 10x Polished Theme Palettes
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 10x Polished Theme Palettes
    final Color themeColor = isSingle ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);
    final Color themeLight = isSingle 
        ? (isDark ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFFEEF2FF))
        : (isDark ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFFFFF7ED));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF334155) 
              : const Color(0xFF0F172A).withOpacity(0.04), 
          width: 1.5
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openReport(report),
          splashColor: themeColor.withOpacity(0.05),
          highlightColor: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              // Polished Campaign Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: themeLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isSingle ? 'SINGLE' : 'MULTI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: themeColor,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Active Dot Mesh Indicator
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeColor.withOpacity(0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat('MMM dd, yyyy').format(report.updatedAt),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12), // Slightly tighter gap 
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert_rounded, 
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), 
                        size: 24
                      ),
                      onSelected: (value) {
                        if (value == 'delete') _deleteReport(report);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Delete', 
                                style: TextStyle(
                                  color: AppTheme.error, 
                                  fontWeight: FontWeight.w600
                                )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // High-Gloss Progress Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.02, 1.0),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSingle 
                                          ? [const Color(0xFF6366F1), const Color(0xFF818CF8)]
                                          : [const Color(0xFF10B981), const Color(0xFF34D399)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isSingle ? const Color(0xFF6366F1) : const Color(0xFF10B981)).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                // Polished Thumb
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSingle ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateReportSheet() {
    final titleController = TextEditingController();
    SelectionMode selectedMode = SelectionMode.single;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: isDark ? Border(top: BorderSide(color: const Color(0xFF334155))) : null,
            ),
            padding: EdgeInsets.fromLTRB(
              24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
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
                  localizationService.tr('create_campaign'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: localizationService.tr('campaign_title'),
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 13),
                    hintText: 'e.g. Q1 Annual Audit',
                    hintStyle: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.5), fontSize: 14),
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF10B981), size: 22),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  localizationService.tr('selection_mode'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    _buildModeOption(
                      title: localizationService.tr('single'),
                      icon: Icons.person_rounded,
                      isSelected: selectedMode == SelectionMode.single,
                      onTap: () => setModalState(() => selectedMode = SelectionMode.single),
                    ),
                    const SizedBox(width: 12),
                    _buildModeOption(
                      title: localizationService.tr('multi'),
                      icon: Icons.group_rounded,
                      isSelected: selectedMode == SelectionMode.multi,
                      onTap: () => setModalState(() => selectedMode = SelectionMode.multi),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        _createReport(titleController.text, selectedMode);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      localizationService.tr('start_campaign'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF10B981) 
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF10B981) 
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createReport(String title, SelectionMode mode) async {
    await _repo.create(
      title: title,
      selectionMode: mode,
    );
  }

  void _deleteReport(Report report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            'Delete Campaign', 
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            )
          ),
          content: Text(
            'Delete "${report.title}"? This cannot be undone.',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'CANCEL', 
                style: TextStyle(
                  color: Color(0xFF64748B), 
                  fontWeight: FontWeight.w800
                )
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _repo.delete(report.id);
    }
  }

  void _openReport(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(reportId: report.id),
      ),
    );
  }
}
