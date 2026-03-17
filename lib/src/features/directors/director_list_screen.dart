import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/models/director.dart';
import '../../core/models/user.dart';
import '../../core/services/preference_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/text_utils.dart';
import 'add_director_sheet.dart';
import 'advanced_export_sheet.dart';
import 'removed_directors_screen.dart';
import '../../core/utils/director_migration_helper.dart';
import '../biometrics/biometric_scanner_sheet.dart';

enum DirectorFilter {
  all,
  noDin,
  addressMismatch,
  activeOnly,
  inactiveOnly,
  hasIdbiAccount,
  noIdbiAccount,
  hasEmudhraAccount,
  noEmudhraAccount,
  hasEmail,
  noEmail,
  hasPan,
  noPan,
}

enum ViewMode { card, table }

// Column configuration for table view
class TableColumn {
  final String id;
  final String label;
  final double minWidth;
  bool visible;
  
  TableColumn({
    required this.id,
    required this.label,
    required this.minWidth,
    this.visible = true,
  });
}

class DirectorListScreen extends StatefulWidget {
  final DirectorFilter filter;
  
  const DirectorListScreen({super.key, this.filter = DirectorFilter.all});

  @override
  State<DirectorListScreen> createState() => _DirectorListScreenState();
}

class _DirectorListScreenState extends State<DirectorListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _repo = DirectorRepository();
  final _prefs = PreferenceService();
  final _scrollController = ScrollController();
  final _horizontalScrollController = ScrollController();
  
  String _searchQuery = '';
  DirectorFilter _currentFilter = DirectorFilter.all;
  String? _alphabetFilter; // null means all, otherwise 'A' to 'Z'
  bool _sortAscending = true; // true = A-Z, false = Z-A
  ViewMode _viewMode = ViewMode.card;
  late AnimationController _animController;
  
  // Table columns configuration - initialize at declaration
  final List<TableColumn> _columns = [
    TableColumn(id: 'serial', label: 'S.No', minWidth: 60),
    TableColumn(id: 'name', label: 'Name', minWidth: 160),
    TableColumn(id: 'din', label: 'DIN', minWidth: 100),
    TableColumn(id: 'pan', label: 'PAN', minWidth: 120),
    TableColumn(id: 'email', label: 'Email', minWidth: 200),
    TableColumn(id: 'status', label: 'Status', minWidth: 90),
    TableColumn(id: 'companies', label: 'Companies', minWidth: 250, visible: false),
    TableColumn(id: 'bankPhone', label: 'Bank Phone', minWidth: 130),
    TableColumn(id: 'aadhaarPhone', label: 'Aadhaar Phone', minWidth: 130, visible: false),
    TableColumn(id: 'emailPhone', label: 'Email Phone', minWidth: 130, visible: false),
    TableColumn(id: 'aadhaar', label: 'Aadhaar No.', minWidth: 140, visible: false),
    TableColumn(id: 'aadhaarAddress', label: 'Aadhaar Address', minWidth: 250, visible: false),
    TableColumn(id: 'residentialAddress', label: 'Residential Address', minWidth: 250, visible: false),
    TableColumn(id: 'idbiAccount', label: 'IDBI Account', minWidth: 200, visible: false),
    TableColumn(id: 'emudhraAccount', label: 'eMudhra Account', minWidth: 200, visible: false),
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _loadPreferences();
    
    _repo.loadAll().then((_) {
      if (mounted) {
        setState(() {});
        _animController.forward();
      }
    });

    // Automatically check if migration is needed? 
    // For now, we provide a manual button.
  }

  Future<void> _loadPreferences() async {
    final mode = await _prefs.getViewMode();
    final sort = await _prefs.getSortAscending();
    final visibleCols = await _prefs.getVisibleColumns();

    if (mounted) {
      setState(() {
        _viewMode = mode == 'table' ? ViewMode.table : ViewMode.card;
        _sortAscending = sort;
        if (visibleCols != null) {
          for (var col in _columns) {
            col.visible = visibleCols.contains(col.id);
          }
        }
      });
    }
  }

  void _saveVisibleColumns() {
    final visibleIds = _columns
        .where((c) => c.visible)
        .map((c) => c.id)
        .toList();
    _prefs.saveVisibleColumns(visibleIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String get _filterTitle {
    String baseTitle;
    switch (_currentFilter) {
      case DirectorFilter.noDin:
        baseTitle = 'No DIN / Proposal';
        break;
      case DirectorFilter.addressMismatch:
        baseTitle = 'Address Mismatch';
        break;
      case DirectorFilter.activeOnly:
        baseTitle = 'Active Directors';
        break;
      case DirectorFilter.inactiveOnly:
        baseTitle = 'Inactive Directors';
        break;
      case DirectorFilter.hasIdbiAccount:
        baseTitle = 'Has IDBI Account';
        break;
      case DirectorFilter.noIdbiAccount:
        baseTitle = 'No IDBI Account';
        break;
      case DirectorFilter.hasEmudhraAccount:
        baseTitle = 'Has eMudhra Account';
        break;
      case DirectorFilter.noEmudhraAccount:
        baseTitle = 'No eMudhra Account';
        break;
      case DirectorFilter.hasEmail:
        baseTitle = 'Has Email';
        break;
      case DirectorFilter.noEmail:
        baseTitle = 'No Email';
        break;
      case DirectorFilter.hasPan:
        baseTitle = 'Has PAN';
        break;
      case DirectorFilter.noPan:
        baseTitle = 'No PAN';
        break;
      default:
        baseTitle = localizationService.tr('all_directors');
    }
    
    // Add alphabet indicator if active
    if (_alphabetFilter != null) {
      return '$baseTitle ($_alphabetFilter)';
    }
    return baseTitle;
  }

  List<Director> _applyFilter(List<Director> directors) {
    switch (_currentFilter) {
      case DirectorFilter.noDin:
        return directors.where((d) => d.hasNoDin).toList();
      case DirectorFilter.addressMismatch:
        return directors.where((d) => d.hasAddressMismatch).toList();
      case DirectorFilter.activeOnly:
        return directors.where((d) => d.status.toLowerCase() == 'active').toList();
      case DirectorFilter.inactiveOnly:
        return directors.where((d) => d.status.toLowerCase() != 'active').toList();
      case DirectorFilter.hasIdbiAccount:
        return directors.where((d) => d.idbiAccountDetails.isNotEmpty).toList();
      case DirectorFilter.noIdbiAccount:
        return directors.where((d) => d.idbiAccountDetails.isEmpty).toList();
      case DirectorFilter.hasEmudhraAccount:
        return directors.where((d) => d.emudhraAccountDetails.isNotEmpty).toList();
      case DirectorFilter.noEmudhraAccount:
        return directors.where((d) => d.emudhraAccountDetails.isEmpty).toList();
      case DirectorFilter.hasEmail:
        return directors.where((d) => d.email.isNotEmpty).toList();
      case DirectorFilter.noEmail:
        return directors.where((d) => d.email.isEmpty).toList();
      case DirectorFilter.hasPan:
        return directors.where((d) => d.pan.isNotEmpty).toList();
      case DirectorFilter.noPan:
        return directors.where((d) => d.pan.isEmpty).toList();
      default:
        return directors;
    }
  }

  Color get _filterColor {
    switch (_currentFilter) {
      case DirectorFilter.noDin:
      case DirectorFilter.noIdbiAccount:
      case DirectorFilter.noEmudhraAccount:
      case DirectorFilter.noEmail:
      case DirectorFilter.noPan:
        return AppTheme.error;
      case DirectorFilter.addressMismatch:
      case DirectorFilter.inactiveOnly:
        return AppTheme.warning;
      case DirectorFilter.activeOnly:
      case DirectorFilter.hasIdbiAccount:
      case DirectorFilter.hasEmudhraAccount:
      case DirectorFilter.hasEmail:
      case DirectorFilter.hasPan:
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  IconData get _filterIcon {
    switch (_currentFilter) {
      case DirectorFilter.noDin:
        return Icons.badge_outlined;
      case DirectorFilter.addressMismatch:
        return Icons.location_off_rounded;
      case DirectorFilter.activeOnly:
        return Icons.check_circle_rounded;
      case DirectorFilter.inactiveOnly:
        return Icons.cancel_rounded;
      case DirectorFilter.hasIdbiAccount:
      case DirectorFilter.noIdbiAccount:
        return Icons.account_balance_rounded;
      case DirectorFilter.hasEmudhraAccount:
      case DirectorFilter.noEmudhraAccount:
        return Icons.security_rounded;
      case DirectorFilter.hasEmail:
      case DirectorFilter.noEmail:
        return Icons.email_rounded;
      case DirectorFilter.hasPan:
      case DirectorFilter.noPan:
        return Icons.credit_card_rounded;
      default:
        return Icons.people_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StreamBuilder<AppUser?>(
      stream: AuthService().userStream,
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        final currentRole = currentUser?.role ?? UserRole.director;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
          body: StreamBuilder<List<Director>>(
            stream: _repo.directorsStream,
            builder: (context, snapshot) {
              final allDirectors = snapshot.data ?? _repo.all;
              var filteredDirectors = _applyFilter(allDirectors);
              
              // Apply alphabet filter
              if (_alphabetFilter != null) {
                filteredDirectors = filteredDirectors.where((d) => 
                  d.name.isNotEmpty && d.name[0].toUpperCase() == _alphabetFilter
                ).toList();
              }
              
              var directors = _searchQuery.isEmpty 
                ? filteredDirectors 
                : filteredDirectors.where((d) =>
                    d.name.contains(_searchQuery) ||
                    d.din.contains(_searchQuery) ||
                    d.email.contains(_searchQuery) ||
                    d.pan.contains(_searchQuery)
                  ).toList();
              
              // Apply sorting
              directors.sort((a, b) {
                final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                return _sortAscending ? comparison : -comparison;
              });

              return CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Modern App Bar
                  _buildAppBar(directors.length),
                  
                  // Search & Filter Section with View Toggle
                  SliverToBoxAdapter(
                    child: _buildSearchSection(directors.length),
                  ),
                  
                  // Content based on view mode
                  snapshot.connectionState == ConnectionState.waiting && allDirectors.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizationService.tr('loading'),
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : directors.isEmpty 
                      ? SliverFillRemaining(
                          child: _buildEmptyState(),
                        )
                      : _viewMode == ViewMode.table
                        ? SliverToBoxAdapter(
                            child: _buildTableView(directors, currentRole),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final d = directors[index];
                                  return _buildDirectorCard(context, d, index, currentRole);
                                },
                                childCount: directors.length,
                              ),
                            ),
                          ),
                ],
              );
            },
          ),
          floatingActionButton: currentRole != UserRole.director ? _buildFAB() : null,
        );
      },
    );
  }

  void _handleExport() {
    // Get currently filtered directors for export
    final allDirectors = _repo.all;
    var filteredDirectors = _applyFilter(allDirectors);
    if (_alphabetFilter != null) {
      filteredDirectors = filteredDirectors
          .where((d) => d.name.toUpperCase().startsWith(_alphabetFilter!))
          .toList();
    }
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text;
      filteredDirectors = filteredDirectors.where((d) =>
        d.name.contains(query) ||
        d.din.contains(query) ||
        d.email.contains(query) ||
        d.pan.contains(query)
      ).toList();
    }
    showAdvancedExportSheet(context, filteredDirectors, filterName: _filterTitle);
  }

  Widget _buildAppBar(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : AppTheme.background;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary;
    final textTertiary = isDark ? const Color(0xFF94A3B8) : AppTheme.textTertiary;
    
    return SliverAppBar(
      expandedHeight: 115,
      floating: true,
      pinned: true,
      stretch: true,
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      leading: _currentFilter != DirectorFilter.all 
        ? IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          )
        : null,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Icon + Title
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(_filterIcon, color: const Color(0xFF6366F1), size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _filterTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count ${localizationService.tr('records_found')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right: Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Polished Trash / Removed Button
                        StreamBuilder<List<Director>>(
                          stream: _repo.removedDirectorsStream,
                          builder: (context, snapshot) {
                            final removedCount = snapshot.data?.length ?? 0;
                            return GestureDetector(
                              onTap: _navigateToRemovedDirectors,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECDD3), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 20),
                                    if (removedCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF43F5E),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$removedCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        // Sync Button
                        _buildSyncButton(),
                        const SizedBox(width: 12),
                        // Premium Gold Export Button
                        _buildExportButton(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: localizationService.tr('search_directors'),
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 24),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          
          const SizedBox(height: 14),
          
          // Compact Actions Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none, // Allow shadows to be visible
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Segmented Toggle (Cards/Table)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewToggleButton(
                        icon: Icons.grid_view_rounded,
                        isSelected: _viewMode == ViewMode.card,
                        onTap: () {
                          setState(() => _viewMode = ViewMode.card);
                          _prefs.saveViewMode('card');
                        },
                        label: localizationService.tr('cards'),
                      ),
                      const SizedBox(width: 4),
                      _buildViewToggleButton(
                        icon: Icons.list_alt_rounded,
                        isSelected: _viewMode == ViewMode.table,
                        onTap: () {
                          setState(() => _viewMode = ViewMode.table);
                          _prefs.saveViewMode('table');
                        },
                        label: localizationService.tr('table'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Compact Sort
                _buildActionChip(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _prefs.saveSortAscending(_sortAscending);
                    });
                  },
                  icon: Icons.sort_rounded,
                  label: _sortAscending ? 'A-Z' : 'Z-A',
                  color: const Color(0xFF6366F1),
                  isActive: true,
                ),
                
                const SizedBox(width: 8),
                
                // Compact Columns (Table only)
                if (_viewMode == ViewMode.table) ...[
                  _buildActionChip(
                    onTap: _showColumnSettings,
                    icon: Icons.view_column_rounded,
                    label: localizationService.tr('cols'),
                    color: const Color(0xFF64748B),
                    isActive: false,
                  ),
                  const SizedBox(width: 8),
                ],

                // Compact Filter
                _buildActionChip(
                  onTap: _showFilterSheet,
                  icon: Icons.tune_rounded,
                  label: localizationService.tr('filter'),
                  color: _currentFilter != DirectorFilter.all ? _filterColor : const Color(0xFF475569),
                  isActive: _currentFilter != DirectorFilter.all,
                  showBadge: _currentFilter != DirectorFilter.all,
                ),
                const SizedBox(width: 8),
                
                // Removed Directors
                StreamBuilder<List<Director>>(
                  stream: _repo.removedDirectorsStream,
                  builder: (context, snapshot) {
                    final removedCount = snapshot.data?.length ?? 0;
                    return _buildActionChip(
                      onTap: _navigateToRemovedDirectors,
                      icon: Icons.delete_outline_rounded,
                      label: 'Removed',
                      color: AppTheme.error,
                      isActive: false,
                      showBadge: removedCount > 0,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    bool isActive = false,
    bool showBadge = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Color mapping to match screenshot specifically for A-Z
    Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    Color iconColor = color;

    if (label == 'A-Z' || label == 'Z-A') {
      bgColor = const Color(0xFFEEF2FF);
      textColor = const Color(0xFF6366F1);
      iconColor = const Color(0xFF6366F1);
    } else if (isActive) {
      bgColor = color.withOpacity(0.1);
      textColor = color;
      iconColor = color;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (label == 'A-Z' || label == 'Z-A') 
                ? const Color(0xFFC7D2FE) 
                : (isActive ? color.withOpacity(0.3) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            width: 1.2,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
          
          final count = await DirectorMigrationHelper.migrateDirectorCompanies();
          
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully synced $count director records.'),
                backgroundColor: AppTheme.success,
              ),
            );
            // Refresh local cache via stream or reload
            await _repo.loadAll();
            setState(() {});
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error syncing data: $e'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1), // Indigo color
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.sync_rounded, 
          size: 20, 
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _handleExport();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBBF24),
              Color(0xFFF59E0B),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.ios_share_rounded, 
          size: 20, 
          color: Color(0xFF451A03),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8)
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TABLE VIEW
  Widget _buildTableView(List<Director> directors, UserRole role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleColumns = _columns.where((c) => c.visible).toList();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalScrollController,
          physics: const BouncingScrollPhysics(),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1a1a2e)),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 60,
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              ...visibleColumns.map((col) => DataColumn(
                label: Container(
                  constraints: BoxConstraints(minWidth: col.minWidth - 36),
                  child: Text(col.label),
                ),
              )),
              const DataColumn(label: Text('Actions')),
            ],
            rows: directors.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              final hasIssue = d.hasNoDin || d.hasAddressMismatch;
              
              return DataRow(
                color: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppTheme.primary.withOpacity(isDark ? 0.1 : 0.05);
                  }
                  if (hasIssue) {
                    return isDark 
                        ? const Color(0xFF451A03).withOpacity(0.3)
                        : const Color(0xFFFFF8E1);
                  }
                  return index.isEven 
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : (isDark ? const Color(0xFF0F172A).withOpacity(0.3) : const Color(0xFFF8FAFC));
                }),
                cells: [
                  ...visibleColumns.map((col) => DataCell(
                    _buildTableCell(d, col.id, index),
                    onTap: () => _showDirectorDetail(d, role),
                  )),
                  DataCell(_buildActionCell(d, role)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(Director d, String columnId, int displayIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (columnId) {
      case 'serial':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${displayIndex + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              fontSize: 12,
            ),
          ),
        );
      case 'name':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: d.hasNoDin || d.hasAddressMismatch
                    ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                d.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'din':
        return d.hasNoDin
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'No DIN',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            )
          : Text(
              d.din,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            );
      case 'pan':
        return Text(
          d.pan.isNotEmpty ? d.pan : '-',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            fontFamily: 'monospace',
            color: d.pan.isEmpty 
                ? (isDark ? const Color(0xFF64748B) : AppTheme.textTertiary)
                : (isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary),
          ),
        );
      case 'email':
        return Text(
          d.email.isNotEmpty ? d.email : '-',
          style: TextStyle(
            fontSize: 12,
            color: d.email.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        );
      case 'status':
        final isActive = d.status.toLowerCase() == 'active';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive 
              ? AppTheme.success.withOpacity(0.1) 
              : AppTheme.textTertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            d.status,
            style: TextStyle(
              color: isActive ? AppTheme.success : AppTheme.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        );
      case 'bankPhone':
        return Text(
          d.bankLinkedPhone.isNotEmpty ? d.bankLinkedPhone : '-',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: d.bankLinkedPhone.isEmpty 
                ? (isDark ? const Color(0xFF64748B) : AppTheme.textTertiary)
                : (isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary),
          ),
        );
      case 'aadhaarPhone':
        return Text(
          d.aadhaarPanLinkedPhone.isNotEmpty ? d.aadhaarPanLinkedPhone : '-',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: d.aadhaarPanLinkedPhone.isEmpty ? AppTheme.textTertiary : AppTheme.textPrimary,
          ),
        );
      case 'emailPhone':
        return Text(
          d.emailLinkedPhone.isNotEmpty ? d.emailLinkedPhone : '-',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: d.emailLinkedPhone.isEmpty ? AppTheme.textTertiary : AppTheme.textPrimary,
          ),
        );
      case 'aadhaar':
        if (d.aadhaarNumber.isEmpty) {
          return Text('-', style: TextStyle(color: AppTheme.textTertiary));
        }
        // Mask aadhaar number
        final masked = d.aadhaarNumber.length >= 4 
          ? 'XXXX-XXXX-${d.aadhaarNumber.substring(d.aadhaarNumber.length - 4)}'
          : d.aadhaarNumber;
        return Text(
          masked,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        );
      case 'aadhaarAddress':
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: Text(
            d.aadhaarAddress.isNotEmpty ? d.aadhaarAddress : '-',
            style: TextStyle(
              fontSize: 11,
              color: d.aadhaarAddress.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'residentialAddress':
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: Text(
            d.residentialAddress.isNotEmpty ? d.residentialAddress : '-',
            style: TextStyle(
              fontSize: 11,
              color: d.residentialAddress.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'idbiAccount':
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            d.idbiAccountDetails.isNotEmpty ? d.idbiAccountDetails : '-',
            style: TextStyle(
              fontSize: 11,
              color: d.idbiAccountDetails.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'emudhraAccount':
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            d.emudhraAccountDetails.isNotEmpty ? d.emudhraAccountDetails : '-',
            style: TextStyle(
              fontSize: 11,
              color: d.emudhraAccountDetails.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'companies':
        final companiesStr = d.companies.map((c) => c.companyName).join(', ');
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Text(
            companiesStr.isNotEmpty ? companiesStr : '-',
            style: TextStyle(
              fontSize: 11,
              color: companiesStr.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      default:
        return const Text('-');
    }
  }

  Widget _buildActionCell(Director d, UserRole role) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.visibility_rounded, size: 18, color: AppTheme.primary),
          onPressed: () => _showDirectorDetail(d, role),
          tooltip: 'View',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondary),
          onPressed: () => _editDirector(d),
          tooltip: 'Edit',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppTheme.error),
          onPressed: () => _removeDirector(d),
          tooltip: 'Remove',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // Column Settings Bottom Sheet
  void _showColumnSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: isDark ? const Border(top: BorderSide(color: Color(0xFF334155))) : null,
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.view_column_rounded, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Customize Columns',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Toggle columns visibility in the table view',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Column toggles - scrollable
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: List.generate(_columns.length, (index) {
                        final col = _columns[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: col.visible 
                              ? AppTheme.primary.withOpacity(0.05)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: col.visible
                                ? AppTheme.primary.withOpacity(0.2)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              col.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: col.visible 
                                  ? (isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary) 
                                  : (isDark ? const Color(0xFF64748B) : AppTheme.textTertiary),
                              ),
                            ),
                            value: col.visible,
                            activeColor: AppTheme.primary,
                            onChanged: (value) {
                              setModalState(() {
                                _columns[index].visible = value;
                              });
                              setState(() {});
                              _saveVisibleColumns();
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Reset button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            for (var col in _columns) {
                              col.visible = true;
                            }
                          });
                          setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: AppTheme.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Show All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? const Border(top: BorderSide(color: Color(0xFF334155))) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle & Title (Fixed)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.filter_list_rounded, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Filter Directors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (_currentFilter != DirectorFilter.all || _alphabetFilter != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentFilter = DirectorFilter.all;
                              _alphabetFilter = null;
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Scrollable Filter Options
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // General
                    _buildFilterCategory('General', [
                      _buildFilterChip(DirectorFilter.all, 'All Directors', Icons.people_rounded, AppTheme.primary),
                    ]),
                    
                    // Status
                    _buildFilterCategory('Status', [
                      _buildFilterChip(DirectorFilter.activeOnly, 'Active', Icons.check_circle_rounded, AppTheme.success),
                      _buildFilterChip(DirectorFilter.inactiveOnly, 'Inactive', Icons.cancel_rounded, AppTheme.warning),
                    ]),
                    
                    // Issues
                    _buildFilterCategory('Issues', [
                      _buildFilterChip(DirectorFilter.noDin, 'No DIN', Icons.badge_outlined, AppTheme.error),
                      _buildFilterChip(DirectorFilter.addressMismatch, 'Address Mismatch', Icons.location_off_rounded, AppTheme.warning),
                    ]),
                    
                    // Bank Accounts
                    _buildFilterCategory('Bank Accounts', [
                      _buildFilterChip(DirectorFilter.hasIdbiAccount, 'Has IDBI', Icons.account_balance_rounded, AppTheme.success),
                      _buildFilterChip(DirectorFilter.noIdbiAccount, 'No IDBI', Icons.account_balance_rounded, AppTheme.error),
                      _buildFilterChip(DirectorFilter.hasEmudhraAccount, 'Has eMudhra', Icons.security_rounded, AppTheme.success),
                      _buildFilterChip(DirectorFilter.noEmudhraAccount, 'No eMudhra', Icons.security_rounded, AppTheme.error),
                    ]),
                    
                    // Contact Info
                    _buildFilterCategory('Contact Info', [
                      _buildFilterChip(DirectorFilter.hasEmail, 'Has Email', Icons.email_rounded, AppTheme.success),
                      _buildFilterChip(DirectorFilter.noEmail, 'No Email', Icons.email_rounded, AppTheme.error),
                      _buildFilterChip(DirectorFilter.hasPan, 'Has PAN', Icons.credit_card_rounded, AppTheme.success),
                      _buildFilterChip(DirectorFilter.noPan, 'No PAN', Icons.credit_card_rounded, AppTheme.error),
                    ]),
                    
                    // Alphabet Filter
                    _buildAlphabetFilterSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCategory(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFilterChip(DirectorFilter filter, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentFilter = filter);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.15) 
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? color 
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textTertiary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? color 
                    : (isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondary),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlphabetFilterSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Alphabet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (_alphabetFilter != null)
              GestureDetector(
                onTap: () {
                  setState(() => _alphabetFilter = null);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_rounded, size: 14, color: AppTheme.error),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: alphabet.split('').map((letter) {
            final isSelected = _alphabetFilter == letter;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _alphabetFilter = letter);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppTheme.primary 
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                      ? AppTheme.primary 
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _filterIcon,
              size: 48,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No directors found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
              ? 'Try adjusting your search'
              : 'Add your first director to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorCard(BuildContext context, Director d, int index, UserRole currentRole) {
    final hasIssue = d.hasNoDin || d.hasAddressMismatch;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 30).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasIssue 
            ? Border.all(color: AppTheme.warning.withOpacity(0.3))
            : (isDark ? Border.all(color: const Color(0xFF334155)) : null),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDirectorDetail(d, currentRole),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasIssue
                          ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              textUtils.format(d.name),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                              ),
                            ),
                            if (d.fingerprintTemplate != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.fingerprint_rounded, color: Colors.green, size: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (d.hasNoDin)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'No DIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.error,
                                  ),
                                ),
                              )
                            else
                              Text(
                                'DIN: ${d.din}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : AppTheme.textTertiary,
                                ),
                              ),
                            if (d.hasAddressMismatch) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Mismatch',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Biometric Enrollment Button
                  if (currentRole == UserRole.admin || currentRole == UserRole.officeTeam)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _enrollFingerprint(d),
                      icon: Icon(
                        d.fingerprintTemplate != null ? Icons.fingerprint_rounded : Icons.add_fingerprint_rounded,
                        color: d.fingerprintTemplate != null ? Colors.green : (isDark ? Colors.white24 : Colors.grey.withOpacity(0.5)),
                        size: 20,
                      ),
                      tooltip: d.fingerprintTemplate != null ? 'Re-enroll' : 'Enroll',
                    ),
                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasIssue 
                        ? AppTheme.warning.withOpacity(0.1)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: hasIssue 
                          ? AppTheme.warning 
                          : (isDark ? const Color(0xFF94A3B8) : AppTheme.textTertiary),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddDirectorSheet(
            onSave: () {
              setState(() {});
            },
          ),
        );
      },
      backgroundColor: AppTheme.primary,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Add Director',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showDirectorDetail(Director d, UserRole role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: isDark ? const Border(top: BorderSide(color: Color(0xFF334155))) : null,
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: d.hasNoDin || d.hasAddressMismatch
                                ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                                : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textUtils.format(d.name),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: d.status.toLowerCase() == 'active'
                                        ? AppTheme.success.withOpacity(0.1)
                                        : AppTheme.textTertiary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      d.status,
                                      style: TextStyle(
                                        color: d.status.toLowerCase() == 'active'
                                          ? AppTheme.success
                                          : AppTheme.textTertiary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (role != UserRole.director) ...[
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _editDirector(d);
                            },
                            icon: Icon(Icons.edit_rounded, color: AppTheme.primary),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _removeDirector(d);
                            },
                            icon: Icon(Icons.remove_circle_outline_rounded, color: AppTheme.error),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Details
                    _buildDetailSection('Basic Information', [
                      _buildDetailRow('DIN', d.hasNoDin ? 'No DIN / Proposal' : d.din, isError: d.hasNoDin),
                      _buildDetailRow('PAN', d.pan.isNotEmpty ? d.pan : '-'),
                      _buildDetailRow('Email', d.email.isNotEmpty ? d.email : '-'),
                      _buildDetailRow('Aadhaar No.', d.aadhaarNumber.isNotEmpty 
                        ? _maskAadhaar(d.aadhaarNumber) 
                        : '-'),
                    ]),
                    
                    _buildDetailSection('Contact Numbers', [
                      _buildDetailRow('Bank Linked', d.bankLinkedPhone.isNotEmpty ? d.bankLinkedPhone : '-'),
                      _buildDetailRow('Aadhaar/PAN Linked', d.aadhaarPanLinkedPhone.isNotEmpty ? d.aadhaarPanLinkedPhone : '-'),
                      _buildDetailRow('Email Linked', d.emailLinkedPhone.isNotEmpty ? d.emailLinkedPhone : '-'),
                    ]),
                    
                    _buildDetailSection('Addresses', [
                      _buildDetailRow('Aadhaar Address', d.aadhaarAddress.isNotEmpty ? d.aadhaarAddress : '-'),
                      _buildDetailRow('Residential Address', d.residentialAddress.isNotEmpty ? d.residentialAddress : '-'),
                      if (d.hasAddressMismatch)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_rounded, color: AppTheme.warning, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Address Mismatch Detected',
                                  style: TextStyle(
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ]),
                    
                    _buildDetailSection('Bank Accounts', [
                      _buildDetailRow('IDBI Account', d.idbiAccountDetails.isNotEmpty ? d.idbiAccountDetails : '-'),
                      _buildDetailRow('eMudhra Account', d.emudhraAccountDetails.isNotEmpty ? d.emudhraAccountDetails : '-'),
                    ]),

                    if (d.companies.isNotEmpty)
                      _buildDetailSection('Associated Companies', [
                        ...d.companies.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.companyName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${c.designation} • Joined: ${c.appointmentDate}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              if (d.companies.indexOf(c) != d.companies.length - 1)
                                Divider(height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ],
                          ),
                        )).toList(),
                      ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _maskAadhaar(String aadhaar) {
    if (aadhaar.length >= 4) {
      return 'XXXX-XXXX-${aadhaar.substring(aadhaar.length - 4)}';
    }
    return aadhaar;
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isError 
                    ? AppTheme.error 
                    : (isDark ? const Color(0xFFF8FAFC) : AppTheme.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editDirector(Director d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDirectorSheet(
        director: d,
        onSave: () {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _removeDirector(Director d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.remove_circle_outline_rounded, color: AppTheme.warning),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remove Director?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove "${d.name}"?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can restore this director later from "Removed Directors"',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.remove(d.id);
        if (mounted) {
          HapticFeedback.mediumImpact();
          // Clear any existing snackbars first
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${d.name} has been removed',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              dismissDirection: DismissDirection.horizontal,
              showCloseIcon: true,
              closeIconColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () async {
                  await _repo.restore(d.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${d.name} has been restored'),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove director: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _navigateToRemovedDirectors() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RemovedDirectorsScreen()),
    );
  }

  void _enrollFingerprint(Director director) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BiometricScannerSheet(
        mode: BiometricMode.enroll,
        onEnrolled: (template) async {
          try {
            final updatedDirector = director.copyWith(fingerprintTemplate: template);
            await _repo.update(updatedDirector);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fingerprint enrolled successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Enrollment failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
