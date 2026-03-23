import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../core/theme.dart';
import '../../core/models/company.dart';
import '../../core/utils/company_data.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/models/director.dart';

class CompanyListScreen extends StatefulWidget {
  final String? initialSearchQuery;
  const CompanyListScreen({super.key, this.initialSearchQuery});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final List<Company> _companies = CompanyData.companies;
  late final TextEditingController _searchController;
  final DirectorRepository _directorRepo = DirectorRepository();
  late String _searchQuery;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  List<Director> _allDirectors = [];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    _loadDirectors();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  Future<void> _loadDirectors() async {
    await _directorRepo.loadAll();
    setState(() {
      _allDirectors = _directorRepo.all;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Company> get _filteredCompanies {
    if (_searchQuery.isEmpty) return _companies;
    return _companies.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.companyName.toLowerCase().contains(query) ||
             c.cin.toLowerCase().contains(query) ||
             c.registrationNumber.toLowerCase().contains(query);
    }).toList();
  }

  List<Director> _getDirectorsForCompany(String companyName) {
    final searchName = companyName.trim().toLowerCase();
    final list = _allDirectors.where((d) => 
      d.companies.any((c) => c.companyName.trim().toLowerCase() == searchName)
    ).toList();
    
    // Board-specific sorting
    list.sort((a, b) {
      final aDetail = a.companies.firstWhere((c) => c.companyName.trim().toLowerCase() == searchName);
      final bDetail = b.companies.firstWhere((c) => c.companyName.trim().toLowerCase() == searchName);
      return aDetail.boardOrder.compareTo(bDetail.boardOrder);
    });
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primary;
    final scaffoldBg = AppTheme.background;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFF), const Color(0xFFEEF2FF), const Color(0xFFF8FAFF)],
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(isDark, primaryColor),
              
              // Stats / Quick Info Section
              SliverToBoxAdapter(
                child: _buildQuickStats(isDark, primaryColor),
              ),

              // Company List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: _filteredCompanies.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState(isDark))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final company = _filteredCompanies[index];
                          return _buildPremiumCompanyCard(company, index, isDark, primaryColor);
                        },
                        childCount: _filteredCompanies.length,
                      ),
                    ),
              ),

              // Unassigned Directors Section
              _buildUnassignedDirectorsSection(isDark, primaryColor),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // Floating Top Navbar Glow Effect
          if (_isScrolled)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(bool isDark, Color primary) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          onPressed: () {}, // Future: Filter/Search functionality
          icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white70 : Colors.black54),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48), // Increased bottom padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Company Inventory',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enterprise Registry • Secure Records',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
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
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _buildGlassSearchBar(isDark, primary),
        ),
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGlassSearchBar(bool isDark, Color primary) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: primary,
        decoration: InputDecoration(
          hintText: 'Search by Company, CIN...',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.hintText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search_rounded, 
            color: primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStatItem(
            'TOTAL', 
            '${_companies.length}', 
            Icons.layers_rounded, 
            [const Color(0xFFFF7B89), const Color(0xFF8A5082)], // Berry Pink to Vintage Purple
            isDark,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'ACTIVE', 
            '100%', 
            Icons.bolt_rounded, 
            [const Color(0xFF438BD3), const Color(0xFF705F93)], // Azure to Deep Lavender
            isDark,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'LOCATIONS', 
            '12', 
            Icons.place_rounded, 
            [const Color(0xFFF59E0B), const Color(0xFFFF7B89)], // Sunset Orange to Soft Coral
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, IconData icon, List<Color> colors, bool isDark) {
    final leadColor = colors.first;
    return Expanded(
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: leadColor.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Sub-decorative Glass Overlay
            Positioned(
              right: -10,
              top: -10,
              child: Opacity(
                opacity: 0.15,
                child: Icon(icon, size: 90, color: Colors.white),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // White-Tinted Icon Container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  // High-Luminance Typography
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        val,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCompanyCard(Company company, int index, bool isDark, Color primary) {
    final isBirthday = company.isBirthdayThisMonth;
    final companyDirectors = _getDirectorsForCompany(company.companyName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showProfessionalDetails(company, isDark, primary, companyDirectors),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBirthday 
                  ? primary.withOpacity(0.4) 
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                width: isBirthday ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isBirthday ? const Color(0xFF8B5CF6) : primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isBirthday ? Icons.cake_rounded : Icons.business_rounded, 
                        color: isBirthday ? const Color(0xFF8B5CF6) : primary, 
                        size: 22
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  company.companyName,
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (companyDirectors.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: primary.withOpacity(0.2), width: 0.5),
                                  ),
                                  child: Text(
                                    '${companyDirectors.length}',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'CIN: ${company.cin}',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isBirthday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ANNIVERSARY',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF8B5CF6),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.1) : Colors.grey[50], 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      _buildColorfulSegment(
                        'DIRECTORS', 
                        '${companyDirectors.length}', 
                        const Color(0xFF6366F1), // Indigo
                        isDark,
                      ),
                      _buildColorfulSegment(
                        'AGE', 
                        '${company.age} Years', 
                        const Color(0xFF10B981), // Emerald
                        isDark,
                      ),
                      _buildColorfulSegment(
                        'INCORPORATED', 
                        company.formattedIncorporationDate, 
                        const Color(0xFF3B82F6), // Sapphire
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorfulSegment(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [color.withOpacity(0.12), color.withOpacity(0.02)]
              : [color.withOpacity(0.06), color.withOpacity(0.01)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color.withOpacity(0.7),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.manrope(
                color: isDark ? Colors.white : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showProfessionalDetails(Company company, bool isDark, Color primary, List<Director> directors) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scroll) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.95) : Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: company.isBirthdayThisMonth 
                              ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)])
                              : LinearGradient(colors: [primary, primary.withOpacity(0.8)]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (company.isBirthdayThisMonth ? const Color(0xFF4A00E0) : primary).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            company.isBirthdayThisMonth ? Icons.cake_rounded : Icons.business_rounded, 
                            color: Colors.white, 
                            size: 40
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        company.companyName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                      if (company.isBirthdayThisMonth) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Happy ${company.age} Anniversary!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8E2DE2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildDetailSection('Registration Metadata', [
                        _buildDetailRow('Corporate ID (CIN)', company.cin, Icons.badge_rounded, primary, isDark),
                        _buildDetailRow('Registration #', company.registrationNumber, Icons.confirmation_number_rounded, primary, isDark),
                        _buildDetailRow('Incorporation Date', company.dateOfIncorporation, Icons.event_available_rounded, primary, isDark),
                        _buildDetailRow('Company Age', '${company.age} Years', Icons.history_rounded, primary, isDark),
                      ], isDark),
                      const SizedBox(height: 24),
                      StatefulBuilder(
                        builder: (context, setModalState) {
                          return _BoardSearchableList(
                            company: company,
                            isDark: isDark,
                            primary: primary,
                            directors: directors,
                            onUpdate: () => setModalState(() {}),
                            getDirectorsForCompany: _getDirectorsForCompany,
                            updateBoardOrder: _updateBoardOrder,
                            showDirectorAssociations: _showDirectorAssociations,
                            showDirectorAssignmentSheet: _showDirectorAssignmentSheet,
                            loadDirectors: _loadDirectors,
                            buildDirectorRow: _buildDirectorRow,
                          );
                        }
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection('Registered Presence', [
                        _buildDetailRow('Principal Address', company.address, Icons.location_on_rounded, primary, isDark),
                      ], isDark),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: primary.withOpacity(0.5),
                          ),
                          child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
    );
  }

  Widget _buildDirectorRow(Director director, bool isDark, Color primary, Company company, int index, Function? refreshModal, {Key? key}) {
    final association = director.companies.firstWhere(
      (c) => c.companyName.trim().toLowerCase() == company.companyName.trim().toLowerCase(),
      orElse: () => CompanyDetail(companyName: company.companyName, designation: 'Director', appointmentDate: ''),
    );

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDirectorAssociations(director, isDark, primary),
          borderRadius: BorderRadius.circular(16),
          child: ReorderableDelayedDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        director.name.isNotEmpty ? director.name[0] : 'D',
                        style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          director.name,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${association.designation} • Joined: ${association.appointmentDate.isNotEmpty ? association.appointmentDate : 'Pending'}',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeDirectorFromCompany(director, company, refreshModal: refreshModal),
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateBoardOrder(List<Director> sortedList, String companyName) async {
    final searchName = companyName.trim().toLowerCase();
    final updates = <Future>[];
    
    for (int i = 0; i < sortedList.length; i++) {
      final director = sortedList[i];
      final newCompanies = director.companies.map((c) {
        if (c.companyName.trim().toLowerCase() == searchName) {
          return c.copyWith(boardOrder: i);
        }
        return c;
      }).toList();
      
      updates.add(_directorRepo.update(director.copyWith(companies: newCompanies)));
    }
    
    await Future.wait(updates);
  }

  void _showDirectorAssociations(Director director, bool isDark, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Associated Companies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Board portfolio for ${director.name}',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: director.companies.length,
                  itemBuilder: (context, index) {
                    final assoc = director.companies[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                        boxShadow: isDark ? null : [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          assoc.companyName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${assoc.designation} • Joined: ${assoc.appointmentDate}',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black45,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.business_center_rounded, color: primary, size: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children, bool isDark, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title.toUpperCase(), style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            )),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color primary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedDirectorsSection(bool isDark, Color primary) {
    final unassigned = _allDirectors.where((d) => d.companies.isEmpty).toList();
    if (unassigned.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Unassigned Directors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${unassigned.length}',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...unassigned.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                    radius: 18,
                    child: Text(
                      d.name.isNotEmpty ? d.name[0] : 'D',
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('DIN: ${d.displayDin.isNotEmpty ? d.displayDin : 'PENDING'}', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.warning_amber_rounded, color: const Color(0xFFEF4444).withOpacity(0.5), size: 20),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _showDirectorAssignmentSheet(Company company, bool isDark, Color primary) {
    final available = _allDirectors.where((d) => 
      !d.companies.any((c) => c.companyName.trim().toLowerCase() == company.companyName.trim().toLowerCase())
    ).toList();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Assign Director', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('Connect director to ${company.companyName}', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final d = available[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: primary.withOpacity(0.1),
                      child: Text(d.name[0], style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('DIN: ${d.displayDin}', style: const TextStyle(fontSize: 12)),
                    trailing: Icon(Icons.add_circle_outline_rounded, color: primary),
                    onTap: () {
                      Navigator.pop(context);
                      _assignDirectorToCompany(d, company);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )
    );
  }

  Future<void> _assignDirectorToCompany(Director director, Company company) async {
    final newCompanies = List<CompanyDetail>.from(director.companies);
    newCompanies.add(CompanyDetail(
      companyName: company.companyName,
      designation: 'Director',
      appointmentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    ));

    final updatedDirector = director.copyWith(companies: newCompanies);
    await _directorRepo.update(updatedDirector);
    _loadDirectors(); // Refresh local list
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${director.name} assigned to ${company.companyName}'))
      );
      // If we are currently showing details, we might want to refresh that UI too.
      // Since it's a modal, we might need to close and reopen or use a stateful modal.
      // For now, closing the modal is simplest or telling the user to re-open.
      Navigator.pop(context); // Close details modal to refresh
    }
  }

  Future<void> _removeDirectorFromCompany(Director director, Company company, {Function? refreshModal}) async {
    final searchName = company.companyName.trim().toLowerCase();
    final removedAssociation = director.companies.firstWhere((c) => c.companyName.trim().toLowerCase() == searchName);
    final newCompanies = director.companies.where((c) => c.companyName.trim().toLowerCase() != searchName).toList();
    final updatedDirector = director.copyWith(companies: newCompanies);
    
    await _directorRepo.update(updatedDirector);
    await _loadDirectors();
    if (refreshModal != null) refreshModal(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('${director.name} removed from ${company.companyName}'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFFF59E0B),
            onPressed: () async {
              // Restore the association
              final restoredCompanies = List<CompanyDetail>.from(updatedDirector.companies);
              restoredCompanies.add(removedAssociation);
              await _directorRepo.update(updatedDirector.copyWith(companies: restoredCompanies));
              await _loadDirectors();
              if (refreshModal != null) refreshModal(() {});
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text('No matches found', style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}

class _BoardSearchableList extends StatefulWidget {
  final Company company;
  final bool isDark;
  final Color primary;
  final List<Director> directors;
  final VoidCallback onUpdate;
  final List<Director> Function(String) getDirectorsForCompany;
  final Future<void> Function(List<Director>, String) updateBoardOrder;
  final void Function(Director, bool, Color) showDirectorAssociations;
  final Future<void> Function(Company, bool, Color) showDirectorAssignmentSheet;
  final VoidCallback loadDirectors;
  final Widget Function(Director, bool, Color, Company, int, Function?, {Key? key}) buildDirectorRow;

  const _BoardSearchableList({
    required this.company,
    required this.isDark,
    required this.primary,
    required this.directors,
    required this.onUpdate,
    required this.getDirectorsForCompany,
    required this.updateBoardOrder,
    required this.showDirectorAssociations,
    required this.showDirectorAssignmentSheet,
    required this.loadDirectors,
    required this.buildDirectorRow,
  });

  @override
  State<_BoardSearchableList> createState() => _BoardSearchableListState();
}

class _BoardSearchableListState extends State<_BoardSearchableList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FRESH FETCH: Always get current board state from repo
    final currentDirectors = widget.getDirectorsForCompany(widget.company.companyName);
    
    final filtered = _query.isEmpty 
      ? currentDirectors 
      : currentDirectors.where((d) => d.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Board of Directors (${currentDirectors.length})',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                await widget.showDirectorAssignmentSheet(widget.company, widget.isDark, widget.primary);
                widget.onUpdate();
              },
              icon: Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search inside modal
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _query = val),
            style: GoogleFonts.inter(fontSize: 13, color: widget.isDark ? Colors.white : AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filter directors...',
              hintStyle: TextStyle(fontSize: 12, color: AppTheme.hintText),
              prefixIcon: Icon(Icons.search, size: 16, color: widget.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: _query.isNotEmpty ? IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ) : null,
            ),
          ),
        ),
        if (_query.isEmpty)
          const Text(
            'Hold and drag handle to reorder',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          Text(
            'Showing ${filtered.length} matches',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No matching directors.', style: TextStyle(fontSize: 13, color: Colors.grey))),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              if (_query.isNotEmpty) return; // Disable reorder during search for safety
              
              final items = List<Director>.from(currentDirectors);
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              
              await widget.updateBoardOrder(items, widget.company.companyName);
              widget.loadDirectors();
              setState(() {});
            },
            itemBuilder: (context, index) {
              final d = filtered[index];
              return widget.buildDirectorRow(
                d, 
                widget.isDark, 
                widget.primary, 
                widget.company, 
                index, 
                () => setState(() {}), 
                key: ValueKey('dr-${d.id}')
              );
            },
          ),
      ],
    );
  }
}
