import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/models/report.dart';
import '../../core/models/director.dart';
import '../../core/repositories/report_repository.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/utils/text_utils.dart';
import '../../core/services/localization_service.dart';
import 'report_export_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _reportRepo = ReportRepository();
  final _directorRepo = DirectorRepository();
  
  Report? _report;
  List<Director> _allDirectors = [];
  bool _isLoading = true;
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load directors from Firebase
      final directors = await _directorRepo.loadAll();
      debugPrint('Loaded ${directors.length} directors');
      
      // Load report
      final report = await _reportRepo.getById(widget.reportId);
      debugPrint('Loaded report: ${report?.title}');
      
      if (mounted) {
        setState(() {
          _allDirectors = directors.where((d) => d.status == 'Active').toList();
          _report = report;
          _isLoading = false;
        });
        debugPrint('State updated: ${_allDirectors.length} active directors ready');
      }
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  // Get directors not assigned to any category
  List<Director> get _unassignedDirectors {
    if (_report == null) return [];
    final assignedIds = _report!.allAssignedDirectorIds;
    return _allDirectors.where((d) => !assignedIds.contains(d.id)).toList();
  }

  // Get directors for a specific category
  List<Director> _getDirectorsForCategory(ReportCategory category) {
    return _allDirectors.where((d) => category.directorIds.contains(d.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
          title: Text(localizationService.tr('loading'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_report == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : AppTheme.primary,
          title: Text(localizationService.tr('report_not_found'), style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            localizationService.tr('report_not_found_desc'),
            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondary),
          ),
        ),
      );
    }

    final report = _report!;
    final unassigned = _unassignedDirectors;
    
    // Premium gradient colors based on selection mode
    final primaryGradient = report.selectionMode == SelectionMode.single
        ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
        : [const Color(0xFF11998E), const Color(0xFF38EF7D)];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            titleSpacing: 0,
            centerTitle: false,
            title: Text(
              report.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showExportOptions,
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildPremiumStatItem(
                      localizationService.tr('categories'),
                      '${report.categories.length}',
                      Icons.grid_view_rounded,
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.12),
                    ),
                  ),
                  Expanded(
                    child: _buildPremiumStatItem(
                      localizationService.tr('assigned'),
                      '${_allDirectors.length - unassigned.length}',
                      Icons.check_circle_rounded,
                      AppTheme.success,
                      AppTheme.success.withOpacity(0.12),
                    ),
                  ),
                  Expanded(
                    child: _buildPremiumStatItem(
                      localizationService.tr('pending'),
                      '${unassigned.length}',
                      Icons.pending_actions_rounded,
                      AppTheme.error,
                      AppTheme.error.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Unified Premium Analytics Dashboard
          SliverToBoxAdapter(
            child: _buildUnifiedAnalyticsCard(report, unassigned),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Categories Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localizationService.tr('categories'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showAddCategorySheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            localizationService.tr('add_category'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Category Cards
          if (report.categories.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 48,
                      color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizationService.tr('no_categories_yet'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizationService.tr('add_category_start'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverReorderableList(
              itemCount: report.categories.length,
              itemBuilder: (context, index) {
                final category = report.categories[index];
                return _buildCategoryCard(category, report, index);
              },
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                
                final categories = List<ReportCategory>.from(report.categories);
                final item = categories.removeAt(oldIndex);
                categories.insert(newIndex, item);
                
                // Update order index for all categories
                final orderedCategories = categories.asMap().entries.map((entry) {
                  return entry.value.copyWith(order: entry.key);
                }).toList();
                
                // Update locally first for immediate feedback
                setState(() {
                  _report = report.copyWith(categories: orderedCategories);
                });
                
                // Save to Firebase
                await _reportRepo.saveCategoriesOrder(widget.reportId, orderedCategories);
              },
            ),

          // Not Answered Section
          if (unassigned.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildNotAnsweredSection(unassigned),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedAnalyticsCard(Report report, List<Director> unassigned) {
    final assigned = _allDirectors.length - unassigned.length;
    final total = _allDirectors.length;
    final completionPercentage = total > 0 ? (assigned / total) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium Status Colors
    final completionColor = completionPercentage < 0.3 
        ? const Color(0xFFF43F5E) // Premium Rose-Red
        : completionPercentage < 0.7 
            ? const Color(0xFFF59E0B) 
            : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppTheme.primary.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          // Header with Glass Accent
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Insights Dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total TOTAL',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Premium Credit-Style Gauge Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: SizedBox(
                height: 130,
                width: 220,
                child: Stack(
                  children: [
                    // Segmented Gauge Base
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GaugeChartPainter(percentage: completionPercentage),
                      ),
                    ),
                    // Central Readout (Re-engineered for Zero Overlap)
                    Positioned(
                      bottom: 12, // Anchored for breathing room
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$assigned OF $total DIRECTORS',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withOpacity(0.3),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(completionPercentage * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Quality Status: ${completionPercentage < 0.3 ? "POOR" : completionPercentage < 0.7 ? "AVERAGE" : "EXCELLENT"}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: completionColor.withOpacity(0.9),
                                letterSpacing: 0.5,
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
          // Sub-footer for Gauge Info (arranged better)
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Last Updated: ${DateFormat('dd MMM yyyy').format(report.updatedAt)}',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: AppTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category Breakdown & Horizontal Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Segmented Scale Footers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScaleLabel("0%", Colors.white30),
                      _buildScaleLabel("25%", const Color(0xFFEF4444)),
                      _buildScaleLabel("50%", const Color(0xFFF97316)),
                      _buildScaleLabel("75%", const Color(0xFFF59E0B)),
                      _buildScaleLabel("100%", const Color(0xFF10B981)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // The Segmented Scale Bar with Current Level Indicator
                SizedBox(
                  height: 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The Base Segments (Equally balanced 25% each)
                      Center(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: Container(color: const Color(0xFFEF4444).withOpacity(0.8))),
                              const SizedBox(width: 1),
                              Expanded(flex: 1, child: Container(color: const Color(0xFFF97316).withOpacity(0.8))),
                              const SizedBox(width: 1),
                              Expanded(flex: 1, child: Container(color: const Color(0xFFF59E0B).withOpacity(0.8))),
                              const SizedBox(width: 1),
                              Expanded(flex: 1, child: Container(color: const Color(0xFF10B981).withOpacity(0.8))),
                            ],
                          ),
                        ),
                      ),
                      // The Small Current Level Indicator Dot
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: completionPercentage.clamp(0.01, 1.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: completionColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: completionColor.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Premium Interactive Pills
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ...report.categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final directors = _getDirectorsForCategory(category);
                        if (directors.isEmpty) return const SizedBox.shrink();
                        
                        final colorPalette = [
                          const Color(0xFF818CF8),
                          const Color(0xFF34D399),
                          const Color(0xFF60A5FA),
                          const Color(0xFFC084FC),
                          const Color(0xFFFB7185),
                          const Color(0xFF2DD4BF),
                        ];
                        
                        final color = colorPalette[index % colorPalette.length];
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 9, 
                                    fontWeight: FontWeight.w700, 
                                    color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.textPrimary, 
                                    letterSpacing: 0.2
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '${directors.length}/${_allDirectors.length}',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.2),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (unassigned.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF43F5E),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.3), blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pending', 
                                style: TextStyle(
                                  fontSize: 9, 
                                  fontWeight: FontWeight.w700, 
                                  color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.textPrimary, 
                                  letterSpacing: 0.2
                                )
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF43F5E).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '${unassigned.length}/${_allDirectors.length}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFF43F5E), letterSpacing: -0.2),
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
    );
  }

  Widget _buildScaleLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: color.withOpacity(0.8),
      ),
    );
  }

  Widget _buildDistributionStatRow(String label, int value, int? total, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (total != null) ...[
          const SizedBox(width: 4),
          Text(
            '/ $total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumStatItem(String label, String value, IconData icon, Color color, Color bgColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ReportCategory category, Report report, int index) {
    final directors = _getDirectorsForCategory(category);
    final isExpanded = _expandedCategoryId == category.id;
    final totalDirectors = _allDirectors.length;
    final percentage = totalDirectors > 0 ? directors.length / totalDirectors : 0.0;
    
    // Category Premium Color Palette
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
    ];
    
    final color = colors[index % colors.length];
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ReorderableDelayedDragStartListener(
      key: ValueKey(category.id),
      index: index,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with refined gradient
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Reorder Handle
                      Icon(
                        Icons.reorder_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      // Tappable area for expand/collapse
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _expandedCategoryId = isExpanded ? null : category.id;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full category name (no truncation)
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Add Director Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showAddDirectorSheet(category);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // More options
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        onSelected: (value) {
                          if (value == 'add') {
                            _showAddDirectorSheet(category);
                          } else if (value == 'delete') {
                            _deleteCategory(category);
                          } else if (value == 'rename') {
                            _renameCategory(category);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add',
                            child: Row(
                              children: [
                                Icon(Icons.person_add_rounded, size: 20, color: Colors.blue),
                                SizedBox(width: 10),
                                Text('Add Directors', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                 const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                                 const SizedBox(width: 10),
                                 Text(localizationService.tr('rename')),
                               ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 10),
                                Text(localizationService.tr('delete'), style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Expand/collapse indicator
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedCategoryId = isExpanded ? null : category.id;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Directors List (Expanded)
            if (isExpanded)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: directors.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          localizationService.tr('no_directors_in_category'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: directors.length,
                        itemBuilder: (context, index) {
                          final director = directors[index];
                          return _buildDirectorTile(director, category);
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorTile(Director director, ReportCategory category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withOpacity(0.5)
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              director.name.isNotEmpty ? director.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textUtils.format(director.name),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (director.din.isNotEmpty)
                  Text(
                    'DIN: ${director.din}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeDirectorFromCategory(director, category),
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: Colors.red.withOpacity(0.7),
              size: 22,
            ),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildNotAnsweredSection(List<Director> unassigned) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF7F1D1D).withOpacity(0.1) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF991B1B).withOpacity(0.3) : const Color(0xFFFECACA)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF87171), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Not Answered (${unassigned.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bar
                Builder(
                  builder: (context) {
                    final total = _allDirectors.length;
                    final percentage = total > 0 ? unassigned.length / total : 0.0;
                    return Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: unassigned.length,
            itemBuilder: (context, index) {
              final director = unassigned[index];
              return Container(
                padding: EdgeInsets.fromLTRB(16, index == 0 ? 6 : 10, 16, 10),
                decoration: BoxDecoration(
                  border: index < unassigned.length - 1
                      ? const Border(bottom: BorderSide(color: Color(0xFFFECACA)))
                      : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                      child: Text(
                        director.name.isNotEmpty ? director.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB91C1C),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        textUtils.format(director.name),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategorySheet() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? Border(top: BorderSide(color: const Color(0xFF334155))) : null,
        ),
        padding: EdgeInsets.fromLTRB(
          24, 8, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
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
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(
                color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Category name',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  
                  Navigator.pop(context);
                  
                  final newCategory = ReportCategory(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: controller.text.trim(),
                    order: _report!.categories.length,
                  );
                  
                  await _reportRepo.addCategory(widget.reportId, newCategory);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDirectorSheet(ReportCategory category) {
    debugPrint('=== _showAddDirectorSheet CALLED ===');
    debugPrint('Category: ${category.name}');
    debugPrint('_allDirectors count: ${_allDirectors.length}');
    debugPrint('_report: ${_report?.title}');
    
    // Safety checks
    if (_report == null) {
      debugPrint('ERROR: Report is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report not loaded yet')),
      );
      return;
    }
    
    // Use filtered directors from repository as fallback
    List<Director> directorsToUse = _allDirectors;
    if (directorsToUse.isEmpty) {
      directorsToUse = _directorRepo.all.where((d) => d.status == 'Active').toList();
      debugPrint('Using filtered directors from repo: ${directorsToUse.length}');
    }
    
    if (directorsToUse.isEmpty) {
      debugPrint('ERROR: No directors available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No directors available. Please check your connection.')),
      );
      return;
    }
    
    debugPrint('Opening director selection with ${directorsToUse.length} directors');
    
    // Use Navigator.push instead of showModalBottomSheet for reliability
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _DirectorSelectionPage(
          category: category,
          report: _report!,
          allDirectors: directorsToUse,
          reportRepo: _reportRepo,
          reportId: widget.reportId,
        ),
      ),
    ).then((_) {
      // Refresh data when returning
      _loadData();
    });
  }

  void _deleteCategory(ReportCategory category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Delete Category?',
          style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary),
        ),
        content: Text(
          'Delete "${category.name}" and unassign all directors?',
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel', 
              style: TextStyle(color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary)
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reportRepo.deleteCategory(widget.reportId, category.id);
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _renameCategory(ReportCategory category) {
    final controller = TextEditingController(text: category.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Rename Category',
          style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Category name',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel', 
              style: TextStyle(color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary)
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              
              final updated = category.copyWith(name: controller.text.trim());
              await _reportRepo.updateCategory(widget.reportId, updated);
              _loadData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeDirectorFromCategory(Director director, ReportCategory category) {
    HapticFeedback.mediumImpact();
    _reportRepo.removeDirector(
      reportId: widget.reportId,
      categoryId: category.id,
      directorId: director.id,
    ).then((_) => _loadData());
  }

  void _showExportOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? Border(top: BorderSide(color: const Color(0xFF334155))) : null,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            // PDF Option
            ListTile(
              onTap: () async {
                Navigator.pop(context);
                await ReportExportService.exportToPdf(
                  _report!,
                  _allDirectors,
                  _unassignedDirectors,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF exported successfully!')),
                  );
                }
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              ),
              title: Text(
                'Export as PDF',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Save report as PDF file',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : AppTheme.textTertiary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // WhatsApp Option
            ListTile(
              onTap: () async {
                Navigator.pop(context);
                await ReportExportService.shareToWhatsApp(
                  _report!,
                  _allDirectors,
                  _unassignedDirectors,
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              ),
              title: Text(
                'Share via WhatsApp',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Copy formatted text for WhatsApp',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : AppTheme.textTertiary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF64748B) : AppTheme.textTertiary,
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Separate StatefulWidget for director selection
class _DirectorSelectionSheet extends StatefulWidget {
  final ReportCategory category;
  final Report report;
  final List<Director> allDirectors;
  final ReportRepository reportRepo;
  final String reportId;
  final VoidCallback onUpdate;

  const _DirectorSelectionSheet({
    required this.category,
    required this.report,
    required this.allDirectors,
    required this.reportRepo,
    required this.reportId,
    required this.onUpdate,
  });

  @override
  State<_DirectorSelectionSheet> createState() => _DirectorSelectionSheetState();
}

class _DirectorSelectionSheetState extends State<_DirectorSelectionSheet> {
  late Report _currentReport;
  
  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  List<Director> get _availableDirectors {
    if (_currentReport.selectionMode == SelectionMode.single) {
      final assignedIds = _currentReport.allAssignedDirectorIds;
      return widget.allDirectors.where((d) => !assignedIds.contains(d.id)).toList();
    } else {
      final cat = _currentReport.categories.firstWhere(
        (c) => c.id == widget.category.id,
        orElse: () => widget.category,
      );
      return widget.allDirectors.where((d) => !cat.directorIds.contains(d.id)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableDirectors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          'Add to "${widget.category.name}"',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                        Text(
                          '${available.length} directors available',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          
          // List
          Expanded(
            child: available.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 64, color: Colors.green[400]),
                        const SizedBox(height: 16),
                        const Text('All directors assigned!', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: available.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final director = available[index];
                      return Material(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        shape: isDark ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ) : null,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            
                            await widget.reportRepo.assignDirector(
                              reportId: widget.reportId,
                              categoryId: widget.category.id,
                              directorId: director.id,
                              mode: _currentReport.selectionMode,
                            );
                            
                            final updated = await widget.reportRepo.getById(widget.reportId);
                            if (updated != null && mounted) {
                              setState(() => _currentReport = updated);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  child: Text(
                                    director.name.isNotEmpty ? director.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        textUtils.format(director.name),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (director.din.isNotEmpty)
                                        Text(
                                          'DIN: ${director.din}',
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.add_circle_rounded, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Full-screen page for selecting directors (more reliable than bottom sheet)
class _DirectorSelectionPage extends StatefulWidget {
  final ReportCategory category;
  final Report report;
  final List<Director> allDirectors;
  final ReportRepository reportRepo;
  final String reportId;

  const _DirectorSelectionPage({
    required this.category,
    required this.report,
    required this.allDirectors,
    required this.reportRepo,
    required this.reportId,
  });

  @override
  State<_DirectorSelectionPage> createState() => _DirectorSelectionPageState();
}

class _DirectorSelectionPageState extends State<_DirectorSelectionPage> {
  late Report _currentReport;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Director> get _availableDirectors {
    List<Director> directors;
    if (_currentReport.selectionMode == SelectionMode.single) {
      final assignedIds = _currentReport.allAssignedDirectorIds;
      directors = widget.allDirectors.where((d) => !assignedIds.contains(d.id)).toList();
    } else {
      final cat = _currentReport.categories.firstWhere(
        (c) => c.id == widget.category.id,
        orElse: () => widget.category,
      );
      directors = widget.allDirectors.where((d) => !cat.directorIds.contains(d.id)).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      directors = directors.where((d) => 
        d.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        d.din.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Sort A-Z
    directors.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    return directors;
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableDirectors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [AppTheme.primary, AppTheme.primary.withBlue(220)],
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          localizationService.tr('add_to_category', args: {'category': widget.category.name}),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                localizationService.tr('done'), 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Polished Search Bar Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                    ? [const Color(0xFF0F172A), const Color(0xFF0F172A).withOpacity(0)]
                    : [AppTheme.primary.withBlue(220), AppTheme.primary.withOpacity(0)],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: localizationService.tr('search_hint_name_din'),
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded, 
                          color: isDark ? const Color(0xFF94A3B8) : AppTheme.primary,
                          size: 24,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: Icon(
                                Icons.cancel_rounded, 
                                color: isDark ? const Color(0xFF64748B) : Colors.grey[400], 
                                size: 22
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizationService.tr('directors_available_count', args: {'count': available.length.toString()}),
                    style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: available.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 80, color: Colors.green[400]),
                        const SizedBox(height: 16),
                        Text(
                          localizationService.tr('all_directors_assigned'),
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFF8FAFC) : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizationService.tr('no_more_to_add'),
                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final director = available[index];
                      return Card(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        elevation: isDark ? 0 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isDark ? BorderSide(color: const Color(0xFF334155)) : BorderSide.none,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            
                            await widget.reportRepo.assignDirector(
                              reportId: widget.reportId,
                              categoryId: widget.category.id,
                              directorId: director.id,
                              mode: _currentReport.selectionMode,
                            );
                            
                            final updated = await widget.reportRepo.getById(widget.reportId);
                            if (updated != null && mounted) {
                              setState(() => _currentReport = updated);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(localizationService.tr('added_success', args: {'name': director.name})),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: isDark ? const Color(0xFF334155) : null,
                                ),
                              );
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: Text(
                              director.name.isNotEmpty ? director.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFF8FAFC) : AppTheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            textUtils.format(director.name),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFF8FAFC) : Colors.black,
                            ),
                          ),
                          subtitle: director.din.isNotEmpty
                              ? Text(
                                  'DIN: ${director.din}',
                                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                                )
                              : null,
                          trailing: Icon(Icons.add_circle, color: AppTheme.primary, size: 28),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<ReportCategory> categories;
  final List<Director> Function(ReportCategory) getDirectorsForCategory;
  final int unassignedCount;
  final int totalCount;

  _PieChartPainter({
    required this.categories,
    required this.getDirectorsForCategory,
    required this.unassignedCount,
    required this.totalCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCount == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Background track (Very subtle)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(center, radius, trackPaint);

    double startAngle = -3.14159 / 2; // Start from top

    final categoryColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
    ];

    // Premium Color Palette
    final colorPalette = [
      [const Color(0xFF818CF8), const Color(0xFF4F46E5)], // Indigo
      [const Color(0xFF34D399), const Color(0xFF059669)], // Emerald
      [const Color(0xFF60A5FA), const Color(0xFF2563EB)], // Sapphire
      [const Color(0xFFC084FC), const Color(0xFF7C3AED)], // Purple
      [const Color(0xFFFB7185), const Color(0xFFE11D48)], // Rose
      [const Color(0xFF2DD4BF), const Color(0xFF0D9488)], // Teal
    ];

    // Paint categories
    for (int i = 0; i < categories.length; i++) {
      final directors = getDirectorsForCategory(categories[i]);
      if (directors.isEmpty) continue;

      final sweepAngle = (directors.length / totalCount) * 2 * 3.14159;
      final colors = colorPalette[i % colorPalette.length];
      
      // Arc Shadow/Glow
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = colors[0].withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawArc(rect, startAngle + 0.04, sweepAngle - 0.08, false, shadowPaint);

      // Main Arc with Multi-stop Gradient
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [colors[0], colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);

      canvas.drawArc(rect, startAngle + 0.04, sweepAngle - 0.08, false, paint);
      
      startAngle += sweepAngle;
    }

    // Paint unassigned (Pending) - Luxury Crimson Gradient
    if (unassignedCount > 0) {
      final sweepAngle = (unassignedCount / totalCount) * 2 * 3.14159;
      
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF43F5E).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(rect, startAngle + 0.04, sweepAngle - 0.08, false, shadowPaint);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);

      canvas.drawArc(rect, startAngle + 0.04, sweepAngle - 0.08, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}

class _SegmentedBarGlowPainter extends CustomPainter {
  final List<ReportCategory> categories;
  final List<Director> Function(ReportCategory) getDirectorsForCategory;
  final int unassignedCount;
  final int totalCount;

  _SegmentedBarGlowPainter({
    required this.categories,
    required this.getDirectorsForCategory,
    required this.unassignedCount,
    required this.totalCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCount == 0) return;

    double currentX = 0;
    final colorPalette = [
      const Color(0xFF818CF8),
      const Color(0xFF34D399),
      const Color(0xFF60A5FA),
      const Color(0xFFC084FC),
      const Color(0xFFFB7185),
      const Color(0xFF2DD4BF),
    ];

    // Paint category glows
    for (int i = 0; i < categories.length; i++) {
      final directors = getDirectorsForCategory(categories[i]);
      if (directors.isEmpty) continue;

      final width = (directors.length / totalCount) * size.width;
      final color = colorPalette[i % colorPalette.length];

      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX + 4, 0, width - 8, 8),
          const Radius.circular(6),
        ),
        paint,
      );

      currentX += width;
    }

    // Paint unassigned (Pending) glow
    if (unassignedCount > 0) {
      final width = (unassignedCount / totalCount) * size.width;
      const color = Color(0xFFF43F5E);

      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX + 4, 0, width - 8, 8),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GaugeChartPainter extends CustomPainter {
  final double percentage;

  _GaugeChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    // Elevate center to provide room for text below
    final center = Offset(size.width / 2, size.height - 40);
    final radius = size.width / 2 - 25;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Segment Configuration
    const segments = 4;
    const totalAngle = 3.14159; // 180 degrees
    const gap = 0.14; // Compensates for rounded caps to show separation
    const segmentAngle = (totalAngle - (gap * (segments - 1))) / segments;

    final colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Green
    ];

    // Background Shadow Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round; // Restored: Premium rounded look

    // Draw Segments
    for (int i = 0; i < segments; i++) {
      final start = 3.14159 + (i * (segmentAngle + gap));
      
      // Draw background segment
      canvas.drawArc(rect, start, segmentAngle, false, trackPaint);

      // Draw active/filled segment
      final segmentProgress = (percentage * segments) - i;
      if (segmentProgress > 0) {
        final fillAngle = segmentAngle * segmentProgress.clamp(0.0, 1.0);
        final paint = Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round;
        
        canvas.drawArc(rect, start, fillAngle, false, paint);
      }
    }

    // Accurate mapping: percentage to segments + gaps
    int fullSegments = (percentage * segments).floor();
    double fractional = (percentage * segments) - fullSegments;
    if (fullSegments == segments) {
      fullSegments = segments - 1;
      fractional = 1.0;
    }
    
    final handleAngleValue = 3.14159 + 
        (fullSegments * (segmentAngle + gap)) + 
        (fractional * segmentAngle);

    final handlePos = Offset(
      center.dx + radius * cos(handleAngleValue),
      center.dy + radius * sin(handleAngleValue),
    );

    // Handle Glow
    final color = _getColorForPercentage(percentage);
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(handlePos, 10, glowPaint);

    // Handle Luxury White Outer
    canvas.drawCircle(handlePos, 8, Paint()..color = Colors.white);
    
    // Handle Colored Center
    canvas.drawCircle(handlePos, 5, Paint()..color = color);
  }

  Color _getColorForPercentage(double p) {
    if (p < 0.25) return const Color(0xFFEF4444);
    if (p < 0.5) return const Color(0xFFF97316);
    if (p < 0.75) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
