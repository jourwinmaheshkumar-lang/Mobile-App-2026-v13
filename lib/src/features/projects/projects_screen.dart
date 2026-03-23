import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/models/project.dart';
import '../../core/models/user.dart';
import '../../core/repositories/project_repository.dart';
import '../../core/services/auth_service.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import 'package:intl/intl.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with TickerProviderStateMixin {
  final _repo = ProjectRepository();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'All',
    'Infrastructure',
    'Technology',
    'Marketing',
    'Finance',
    'Operations',
    'HR',
    'Legal',
    'Research',
    'Other',
  ];

  // Category icons mapping
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Infrastructure':
        return Icons.construction_rounded;
      case 'Technology':
        return Icons.computer_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      case 'Finance':
        return Icons.account_balance_rounded;
      case 'Operations':
        return Icons.settings_rounded;
      case 'HR':
        return Icons.people_rounded;
      case 'Legal':
        return Icons.gavel_rounded;
      case 'Research':
        return Icons.science_rounded;
      case 'Other':
        return Icons.folder_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  // Category color mapping
  List<Color> _getCategoryGradient(String category) {
    switch (category) {
      case 'Infrastructure':
        return const [Color(0xFFEF4444), Color(0xFFF97316)];
      case 'Technology':
        return const [Color(0xFF3B82F6), Color(0xFF6366F1)];
      case 'Marketing':
        return const [Color(0xFFF59E0B), Color(0xFFF97316)];
      case 'Finance':
        return const [Color(0xFF10B981), Color(0xFF14B8A6)];
      case 'Operations':
        return const [Color(0xFF8B5CF6), Color(0xFFA855F7)];
      case 'HR':
        return const [Color(0xFFEC4899), Color(0xFFF43F5E)];
      case 'Legal':
        return const [Color(0xFF6366F1), Color(0xFF8B5CF6)];
      case 'Research':
        return const [Color(0xFF06B6D4), Color(0xFF3B82F6)];
      case 'Other':
        return const [Color(0xFF64748B), Color(0xFF94A3B8)];
      default:
        return const [Color(0xFF6366F1), Color(0xFF8B5CF6)];
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<AppUser?>(
      stream: AuthService().userStream,
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAdmin = currentUser.role == UserRole.admin;
        final isOffice = currentUser.role == UserRole.officeTeam;
        final canEdit = isAdmin || isOffice;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDark, canEdit),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildSearchBar(isDark),
                          const SizedBox(height: 20),
                          _buildCategoryFilter(isDark),
                          const SizedBox(height: 24),
                          _buildProjectsList(isDark, canEdit, currentUser),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: canEdit
              ? _buildFAB(isDark, currentUser)
              : null,
        );
      },
    );
  }

  Widget _buildAppBar(bool isDark, bool canEdit) {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
        ],
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -15,
                top: -10,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.work_rounded, size: 140, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title + Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Projects',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Manage and track projects',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search projects...',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.hintText,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          final gradientColors = cat == 'All'
              ? const [Color(0xFF6366F1), Color(0xFF8B5CF6)]
              : _getCategoryGradient(cat);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected
                    ? null
                    : isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat != 'All') ...[
                    Icon(
                      _getCategoryIcon(cat),
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.white54
                              : Colors.black45,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: GoogleFonts.poppins(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectsList(bool isDark, bool canEdit, AppUser currentUser) {
    return StreamBuilder<List<Project>>(
      stream: _repo.projectsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        final allProjects = snapshot.data ?? [];

        // Apply filters
        List<Project> projects = allProjects;
        if (_selectedCategory != 'All') {
          projects = projects.where((p) => p.category == _selectedCategory).toList();
        }
        if (_searchQuery.isNotEmpty) {
          projects = _repo.search(projects, _searchQuery);
        }

        if (projects.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            _buildStatsRow(isDark, allProjects),
            const SizedBox(height: 20),
            // Projects
            ...List.generate(projects.length, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 80)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildProjectCard(projects[index], isDark, canEdit, currentUser),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(bool isDark, List<Project> allProjects) {
    final categories = <String, int>{};
    for (final p in allProjects) {
      categories[p.category] = (categories[p.category] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.folder_rounded,
            value: '${allProjects.length}',
            label: 'Total',
            color: AppTheme.primary,
            isDark: isDark,
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
          _buildStatItem(
            icon: Icons.category_rounded,
            value: '${categories.length}',
            label: 'Categories',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
          _buildStatItem(
            icon: Icons.people_rounded,
            value: '${allProjects.fold<int>(0, (sum, p) => sum + p.directors.length)}',
            label: 'Directors',
            color: const Color(0xFFE67E22),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project, bool isDark, bool canEdit, AppUser currentUser) {
    final gradientColors = _getCategoryGradient(project.category);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProjectDetailScreen(
                  project: project,
                  canEdit: canEdit,
                ),
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
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category icon badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(project.category),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                           Wrap(
                             spacing: 8,
                             runSpacing: 6,
                             crossAxisAlignment: WrapCrossAlignment.center,
                             children: [
                               Container(
                                 padding: const EdgeInsets.symmetric(
                                   horizontal: 10,
                                   vertical: 4,
                                 ),
                                 decoration: BoxDecoration(
                                   color: gradientColors[0].withOpacity(0.12),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Text(
                                   project.category,
                                   style: TextStyle(
                                     color: gradientColors[0],
                                     fontSize: 11,
                                     fontWeight: FontWeight.w700,
                                   ),
                                 ),
                               ),
                               if (project.projectValue != null && project.projectValue!.isNotEmpty) ...[
                                 Container(
                                   padding: const EdgeInsets.symmetric(
                                     horizontal: 8,
                                     vertical: 4,
                                   ),
                                   decoration: BoxDecoration(
                                     color: const Color(0xFF10B981).withOpacity(0.12),
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       const Icon(Icons.currency_rupee_rounded, size: 10, color: Color(0xFF10B981)),
                                       const SizedBox(width: 4),
                                       Text(
                                         project.formattedValue,
                                         style: const TextStyle(
                                           color: Color(0xFF10B981),
                                           fontSize: 10,
                                           fontWeight: FontWeight.w800,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ],
                               Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(
                                     Icons.calendar_today_rounded,
                                     size: 12,
                                     color: isDark ? Colors.white38 : Colors.black26,
                                   ),
                                   const SizedBox(width: 4),
                                   Text(
                                     dateFormat.format(project.createdAt),
                                     style: TextStyle(
                                       color: isDark ? Colors.white38 : Colors.black38,
                                       fontSize: 11,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                        ],
                      ),
                    ),
                    // More action (if can edit)
                    if (canEdit)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDark ? Colors.white38 : Colors.black26,
                          size: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateProjectScreen(
                                  project: project,
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(project);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                if (project.details.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    project.details,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Locations summary
                if (project.locations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF06B6D4).withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Color(0xFF06B6D4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              project.locations.length == 1
                                  ? project.locations[0]
                                  : '${project.locations[0]} +${project.locations.length - 1}',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Directors summary
                if (project.directors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Overlapping avatars
                        SizedBox(
                          width: _getAvatarStackWidth(project.directors.length),
                          height: 32,
                          child: Stack(
                            children: List.generate(
                              project.directors.length.clamp(0, 4),
                              (i) {
                                final roleColors = {
                                  'special': const Color(0xFFEF4444),
                                  'leading': const Color(0xFF6366F1),
                                  'normal': const Color(0xFF10B981),
                                };
                                final color = roleColors[project.directors[i].role] ??
                                    const Color(0xFF94A3B8);

                                return Positioned(
                                  left: i * 22.0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        project.directors[i].directorName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (project.directors.length > 4) ...[
                          const SizedBox(width: 4),
                          Text(
                            '+${project.directors.length - 4}',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Director count badges
                        if (project.specialDirectors.isNotEmpty)
                          _buildDirectorBadge('S', project.specialDirectors.length, const Color(0xFFEF4444), isDark),
                        if (project.leadingDirectors.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _buildDirectorBadge('L', project.leadingDirectors.length, const Color(0xFF6366F1), isDark),
                        ],
                        if (project.normalDirectors.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _buildDirectorBadge('N', project.normalDirectors.length, const Color(0xFF10B981), isDark),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getAvatarStackWidth(int count) {
    final visibleCount = count.clamp(0, 4);
    if (visibleCount == 0) return 0;
    return 32.0 + (visibleCount - 1) * 22.0;
  }

  Widget _buildDirectorBadge(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 48,
                color: const Color(0xFF6366F1).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'No projects found'
                  : 'No projects yet',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'Try adjusting your filters'
                  : 'Create your first project to get started',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(bool isDark, AppUser currentUser) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateProjectScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'New Project',
                  style: TextStyle(
                    color: Colors.white,
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

  void _showDeleteConfirmation(Project project) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Delete Project'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${project.title}"? This action cannot be undone.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _repo.delete(project.id, project.title);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text('Project "${project.title}" deleted'),
                        ],
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}
