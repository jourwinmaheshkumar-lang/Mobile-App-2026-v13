import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/project.dart';
import '../../core/repositories/project_repository.dart';
import 'create_project_screen.dart';
import 'package:intl/intl.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;
  final bool canEdit;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.canEdit,
  });

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Project?>(
      stream: projectRepository.projectStream(project.id),
      initialData: project,
      builder: (context, snapshot) {
        final currentProject = snapshot.data ?? project;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final gradientColors = _getCategoryGradient(currentProject.category);
        final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                stretch: true,
                backgroundColor: gradientColors[0],
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (canEdit) ...[
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateProjectScreen(project: currentProject),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          gradientColors[0],
                          gradientColors[1],
                          gradientColors[0].withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background icon watermark
                        Positioned(
                          right: -30,
                          bottom: -20,
                          child: Opacity(
                            opacity: 0.08,
                            child: Icon(
                              _getCategoryIcon(currentProject.category),
                              size: 200,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Content
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Category badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(currentProject.category),
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentProject.category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Title
                                Text(
                                  currentProject.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Date
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateFormat.format(currentProject.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Project Details Section
                    _buildSection(
                      context: context,
                      title: 'Project Details',
                      icon: Icons.description_rounded,
                      iconColor: gradientColors[0],
                      isDark: isDark,
                      child: Text(
                        currentProject.details.isNotEmpty
                            ? currentProject.details
                            : 'No details provided.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    // Project Locations
                    if (currentProject.locations.isNotEmpty) ...[
                      _buildSection(
                        context: context,
                        title: 'Project Locations',
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        isDark: isDark,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentProject.locations.map((location) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF06B6D4)),
                                  const SizedBox(width: 8),
                                  Text(
                                    location,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Info Row
                    _buildInfoRow(isDark, currentProject, gradientColors),

                    const SizedBox(height: 20),

                    // Project Team Section (Unified)
                    if (currentProject.directors.isNotEmpty)
                      _buildTeamSection(
                        context: context,
                        project: currentProject,
                        isDark: isDark,
                      ),

                    if (currentProject.directors.isEmpty)
                      _buildSection(
                        context: context,
                        title: 'Directors',
                        icon: Icons.people_rounded,
                        iconColor: const Color(0xFF94A3B8),
                        isDark: isDark,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 40,
                                  color: isDark ? Colors.white24 : Colors.black12,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No directors assigned',
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.black38,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(bool isDark, Project currentProject, List<Color> gradientColors) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.groups_rounded,
            label: 'Total Directors',
            value: '${currentProject.directors.length}',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        if (currentProject.projectValue != null && currentProject.projectValue!.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.currency_rupee_rounded,
              label: 'Project Value (INR)',
              value: currentProject.formattedValue,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTeamSection({
    required BuildContext context,
    required Project project,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Team',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${project.directors.length} Members involved',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Sections for different roles
          _buildTeamGroup(
            'Special Directors',
            project.specialDirectors,
            const Color(0xFFEF4444),
            Icons.stars_rounded,
            isDark,
          ),
          _buildTeamGroup(
            'Leading Directors',
            project.leadingDirectors,
            const Color(0xFF6366F1),
            Icons.workspace_premium_rounded,
            isDark,
          ),
          _buildTeamGroup(
            'Project Support',
            project.normalDirectors,
            const Color(0xFF10B981),
            Icons.assignment_ind_rounded,
            isDark,
            showDetails: true,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTeamGroup(
    String title,
    List<ProjectDirector> directors,
    Color color,
    IconData icon,
    bool isDark, {
    bool showDetails = false,
  }) {
    if (directors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.15), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: directors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final director = directors[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Row(
                children: [
                  // Avatar with Glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        director.directorName.isNotEmpty ? director.directorName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          director.directorName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (director.designation != null && director.designation!.isNotEmpty)
                              _buildPill(
                                director.designation!,
                                color,
                                isDark,
                              ),
                            if (showDetails && director.posting != null && director.posting!.isNotEmpty) ...[
                              if (director.designation != null) const SizedBox(width: 8),
                              _buildPill(
                                director.posting!,
                                const Color(0xFF64748B),
                                isDark,
                                icon: Icons.location_on_rounded,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPill(String text, Color color, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
