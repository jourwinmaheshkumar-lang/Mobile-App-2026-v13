import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/models/project.dart';
import '../../core/models/user.dart';
import '../../core/models/director.dart';
import '../../core/repositories/project_repository.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/services/auth_service.dart';

class CreateProjectScreen extends StatefulWidget {
  final Project? project; // If provided, we're editing

  const CreateProjectScreen({super.key, this.project});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _valueController = TextEditingController();
  final _repo = ProjectRepository();
  final _directorRepo = DirectorRepository();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Technology';
  bool _isSubmitting = false;

  // Director selections
  List<ProjectDirector> _specialDirectors = [];
  List<ProjectDirector> _leadingDirectors = [];
  List<ProjectDirector> _normalDirectors = [];
  List<String> _locations = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
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

  bool get isEditing => widget.project != null;

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

    // If editing, populate fields
    if (isEditing) {
      final p = widget.project!;
      _titleController.text = p.title;
      _detailsController.text = p.details;
      _valueController.text = p.projectValue ?? '';
      _selectedCategory = p.category;
      _specialDirectors = p.specialDirectors;
      _leadingDirectors = p.leadingDirectors;
      _normalDirectors = p.normalDirectors;
      _locations = List<String>.from(p.locations);
    }

    // Load directors
    _directorRepo.loadAll();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _detailsController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildAppBar(isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Step 1: Project Title
                        _buildSectionHeader(
                          '1',
                          'Project Title',
                          Icons.title_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _titleController,
                          hint: 'Enter project title',
                          icon: Icons.work_outline_rounded,
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Project title is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // Step 2: Project Category
                        _buildSectionHeader(
                          '2',
                          'Project Category',
                          Icons.category_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildCategorySelector(isDark),

                        const SizedBox(height: 28),

                        // Step 3: Project Details
                        _buildSectionHeader(
                          '3',
                          'Project Details',
                          Icons.description_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _detailsController,
                          hint: 'Describe the project objectives, scope, and requirements...',
                          icon: Icons.notes_rounded,
                          isDark: isDark,
                          maxLines: 5,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Project details are required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),
                        
                        // Step 4: Project Value
                        _buildSectionHeader(
                          '4',
                          'Project Value',
                          Icons.currency_exchange_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _valueController,
                          hint: 'Enter project value (e.g. 10000000)',
                          icon: Icons.currency_rupee_rounded,
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 28),

                        // Step 5: Special Director
                        _buildSectionHeader(
                          '5',
                          'Special Director',
                          Icons.star_rounded,
                          isDark,
                          badgeColor: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: Text(
                            'CEO, CFO, and similar key positions',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDirectorSection(
                          directors: _specialDirectors,
                          role: 'special',
                          color: const Color(0xFFEF4444),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 28),

                        // Step 6: Leading Director
                        _buildSectionHeader(
                          '6',
                          'Leading Director',
                          Icons.leaderboard_rounded,
                          isDark,
                          badgeColor: const Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: Text(
                            'Head of this project',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDirectorSection(
                          directors: _leadingDirectors,
                          role: 'leading',
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 28),

                        // Step 7: Other Director with Role & Posting
                        _buildSectionHeader(
                          '7',
                          'Other Director',
                          Icons.people_rounded,
                          isDark,
                          badgeColor: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: Text(
                            'Add directors with role and posting details',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDirectorSection(
                          directors: _normalDirectors,
                          role: 'normal',
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          showRolePosting: true,
                        ),

                        const SizedBox(height: 28),

                        // Step 8: Project Locations
                        _buildSectionHeader(
                          '8',
                          'Project Locations',
                          Icons.location_on_rounded,
                          isDark,
                          badgeColor: const Color(0xFF06B6D4),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: Text(
                            'Add one or more locations where this project will run',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLocationSection(isDark),

                        const SizedBox(height: 36),

                        // Submit Button
                        _buildSubmitButton(isDark),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1a1a2e),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
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
              Positioned(
                right: -30,
                top: -20,
                child: Opacity(
                  opacity: 0.06,
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_circle_rounded,
                    size: 180,
                    color: Colors.white,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isEditing ? Icons.edit_rounded : Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Edit Project' : 'Create Project',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                isEditing
                                    ? 'Update project details'
                                    : 'Fill in all project details',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildSectionHeader(
    String step,
    String title,
    IconData icon,
    bool isDark, {
    Color? badgeColor,
  }) {
    final color = badgeColor ?? const Color(0xFF6366F1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
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
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.black26,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: isDark ? Colors.white30 : Colors.black26, size: 22)
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(color: Color(0xFFEF4444)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: maxLines > 1 ? 20 : 16,
            vertical: maxLines > 1 ? 16 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        final gradientColors = _getCategoryGradient(category);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = category);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: gradientColors)
                  : null,
              color: isSelected
                  ? null
                  : isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? Colors.white54
                          : Colors.black45,
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? Colors.white70
                            : Colors.black54,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDirectorSection({
    required List<ProjectDirector> directors,
    required String role,
    required Color color,
    required bool isDark,
    bool showRolePosting = false,
  }) {
    return Column(
      children: [
        // List of added directors
        ...directors.asMap().entries.map((entry) {
          final index = entry.key;
          final director = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.2),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      director.directorName.isNotEmpty
                          ? director.directorName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        director.directorName,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (director.designation != null && director.designation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                director.designation!,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (director.posting != null && director.posting!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.location_on_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black26),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  director.posting!,
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black45,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else if (director.posting != null && director.posting!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black26),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                director.posting!,
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Remove button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      directors.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Add button
        GestureDetector(
          onTap: () => _showDirectorPicker(directors, role, color, isDark, showRolePosting),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add ${role == 'special' ? 'Special' : role == 'leading' ? 'Leading' : 'Normal'} Director',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDirectorPicker(
    List<ProjectDirector> targetList,
    String role,
    Color color,
    bool isDark,
    bool showRolePosting,
  ) {
    final designationController = TextEditingController();
    final postingController = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person_add_rounded, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Select Director',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (v) => setModalState(() => searchQuery = v),
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search directors...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white30 : Colors.black26,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // Designation / Title field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick-pick chips for special & leading directors
                        if (role == 'special') ...[
                          Text(
                            'Select Title',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['CEO', 'CFO', 'COO', 'CTO', 'CMD', 'CS', 'MD', 'Chairman'].map((title) {
                              final isSelected = designationController.text == title;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    designationController.text = title;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? color : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (role == 'leading') ...[
                          Text(
                            'Select Title',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Project Head', 'Team Lead', 'Coordinator', 'Supervisor', 'Manager'].map((title) {
                              final isSelected = designationController.text == title;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    designationController.text = title;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? color : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Custom designation text field (or role for normal)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: designationController,
                            onChanged: (v) => setModalState(() {}),
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: role == 'special'
                                  ? 'Title (e.g. CEO, CFO or custom)'
                                  : role == 'leading'
                                      ? 'Title (e.g. Project Head or custom)'
                                      : 'Role / Designation',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white30 : Colors.black26,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.badge_rounded,
                                color: isDark ? Colors.white30 : Colors.black26,
                                size: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        // Posting field for normal directors
                        if (showRolePosting) ...[
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: postingController,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Posting',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white30 : Colors.black26,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on_rounded,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                  size: 18,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Director list
                  Expanded(
                    child: StreamBuilder<List<Director>>(
                      stream: _directorRepo.directorsStream,
                      builder: (context, snapshot) {
                        final allDirectors = snapshot.data ?? _directorRepo.all;
                        
                        // Filter out already selected directors (across all groups)
                        final allSelectedIds = [
                          ..._specialDirectors.map((d) => d.directorId),
                          ..._leadingDirectors.map((d) => d.directorId),
                          ..._normalDirectors.map((d) => d.directorId),
                        ];

                        var filteredDirectors = allDirectors.where((d) {
                          return !allSelectedIds.contains(d.id);
                        }).toList()
                          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                        if (searchQuery.isNotEmpty) {
                          final q = searchQuery.toLowerCase();
                          filteredDirectors = filteredDirectors.where((d) {
                            return d.name.toLowerCase().contains(q) ||
                                d.din.contains(q);
                          }).toList();
                        }

                        if (filteredDirectors.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 48,
                                  color: isDark ? Colors.white24 : Colors.black12,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No available directors',
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.black38,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredDirectors.length,
                          separatorBuilder: (_, __) => Divider(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final director = filteredDirectors[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    director.name.isNotEmpty
                                        ? director.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                director.name,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: director.din.isNotEmpty
                                  ? Text(
                                      'DIN: ${director.din}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.add_rounded, color: color, size: 20),
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                final newDirector = ProjectDirector(
                                  directorId: director.id,
                                  directorName: director.name,
                                  role: role,
                                  designation: designationController.text.trim().isNotEmpty
                                      ? designationController.text.trim()
                                      : null,
                                  posting: postingController.text.trim().isNotEmpty
                                      ? postingController.text.trim()
                                      : null,
                                );
                                setState(() {
                                  targetList.add(newDirector);
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
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
          onTap: _isSubmitting ? null : _submitProject,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing ? Icons.save_rounded : Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEditing ? 'Update Project' : 'Create Project',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final allDirectors = [
        ..._specialDirectors,
        ..._leadingDirectors,
        ..._normalDirectors,
      ];

      final currentUser = await AuthService().currentAppUser;

      if (isEditing) {
        final updatedProject = widget.project!.copyWith(
          title: _titleController.text.trim(),
          category: _selectedCategory,
          details: _detailsController.text.trim(),
          projectValue: _valueController.text.trim().isNotEmpty 
              ? _valueController.text.trim() 
              : null,
          directors: allDirectors,
          updatedAt: DateTime.now(),
          locations: _locations,
        );
        await _repo.update(updatedProject);
      } else {
        final newProject = Project(
          id: '',
          title: _titleController.text.trim(),
          category: _selectedCategory,
          details: _detailsController.text.trim(),
          projectValue: _valueController.text.trim().isNotEmpty 
              ? _valueController.text.trim() 
              : null,
          directors: allDirectors,
          createdBy: currentUser?.displayName ?? currentUser?.username ?? 'Admin',
          createdAt: DateTime.now(),
          locations: _locations,
        );
        await _repo.create(newProject);
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
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
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(isEditing ? 'Project updated successfully!' : 'Project created successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildLocationSection(bool isDark) {
    final color = const Color(0xFF06B6D4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // InputField for adding location
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter location name...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.add_location_alt_rounded, color: color, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        _locations.add(value.trim());
                        _locationController.clear();
                      });
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_locationController.text.trim().isNotEmpty) {
                    setState(() {
                      _locations.add(_locationController.text.trim());
                      _locationController.clear();
                    });
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_rounded, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        
        if (_locations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _locations.asMap().entries.map((entry) {
              final index = entry.key;
              final location = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: color),
                    const SizedBox(width: 8),
                    Text(
                      location,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _locations.removeAt(index);
                        });
                      },
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
