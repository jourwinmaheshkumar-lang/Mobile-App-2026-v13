import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _ReportListScreenState extends State<ReportListScreen> with SingleTickerProviderStateMixin {
  final _repo = ReportRepository();
  final _directorRepo = DirectorRepository();
  late AnimationController _animController;
  int _totalDirectors = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Premium light grey
      body: StreamBuilder<List<Report>>(
        stream: _repo.reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
          }

          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) return _buildEmptyState();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Fintech Header
              _buildAppBar(),

              // Content Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        localizationService.tr('RECENT SURVEYS').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.sort_rounded, size: 18, color: const Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              // Report Cards List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = reports[index];
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animController,
                          curve: Interval((index / reports.length).clamp(0, 1), 1.0, curve: Curves.easeOut),
                        ),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: const Color(0xFF7C3AED), // Violet base
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // Soft Fintech Gradient (Purple to Pink tones)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF7C3AED), // Violet
                    Color(0xFFC026D3), // Fuschia
                    Color(0xFFEC4899), // Pink
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Subtle Decorative Pattern
            Positioned(
              right: -30,
              top: -20,
              child: Opacity(
                opacity: 0.12,
                child: Icon(Icons.auto_graph_rounded, size: 200, color: Colors.white),
              ),
            ),

            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
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
                              "MANAGEMENT SUITE",
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
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showCreateReportSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
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
    
    // Dynamic Progress Color
    Color pColor;
    if (progress == 1.0) pColor = const Color(0xFF10B981); // Green
    else if (progress > 0.4) pColor = const Color(0xFFF59E0B); // Orange
    else pColor = const Color(0xFFEF4444); // Red

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _PremiumScaleEffect(
        onTap: () {
          HapticFeedback.selectionClick();
          _openReport(report);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assessment_rounded, color: Color(0xFF7C3AED), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Updated ${DateFormat('MMM dd, yyyy').format(report.updatedAt)}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPillBadge(
                        isSingle ? "Single" : "Multi",
                        isSingle ? const Color(0xFF6366F1) : const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                          onSelected: (value) {
                            if (value == 'delete') _deleteReport(report);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$assignedCount of $_totalDirectors Syncing",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: pColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // More Compact Progress Bar
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.01, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pColor, pColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8), // Modern rounded-rectangle
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showCreateReportSheet() {
    final titleController = TextEditingController();
    SelectionMode selectedMode = SelectionMode.single;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(
              24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                
                Text(
                  localizationService.tr('create_campaign'),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: localizationService.tr('campaign_title'),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.edit_rounded, color: Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    _buildModeSelector(
                      title: "Single Mode",
                      isSelected: selectedMode == SelectionMode.single,
                      onTap: () => setModalState(() => selectedMode = SelectionMode.single),
                    ),
                    const SizedBox(width: 12),
                    _buildModeSelector(
                      title: "Multi Mode",
                      isSelected: selectedMode == SelectionMode.multi,
                      onTap: () => setModalState(() => selectedMode = SelectionMode.multi),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
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
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: const Color(0xFF7C3AED).withOpacity(0.4),
                    ),
                    child: Text(
                      "START ANALYSIS",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2),
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

  Widget _buildModeSelector({required String title, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.report_problem_rounded, size: 80, color: Color(0xFFEF4444)),
            const SizedBox(height: 24),
            Text("Something went wrong", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => setState(() {}), child: const Text("RETRY")),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.assessment_rounded, size: 100, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 32),
          Text("No Reports Found", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text("Let's build your first executive report", style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _showCreateReportSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("CREATE NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _createReport(String title, SelectionMode mode) async => await _repo.create(title: title, selectionMode: mode);

  void _deleteReport(Report report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: Text('This will permanently remove "${report.title}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) await _repo.delete(report.id);
  }

  void _openReport(Report report) => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportDetailScreen(reportId: report.id)));
}

class _PremiumScaleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PremiumScaleEffect({required this.child, required this.onTap});

  @override
  State<_PremiumScaleEffect> createState() => _PremiumScaleEffectState();
}

class _PremiumScaleEffectState extends State<_PremiumScaleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse().then((_) => widget.onTap()),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
