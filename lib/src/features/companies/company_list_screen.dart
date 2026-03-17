import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/theme.dart';
import '../../core/models/company.dart';
import '../../core/utils/company_data.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/models/director.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final List<Company> _companies = CompanyData.companies;
  final TextEditingController _searchController = TextEditingController();
  final DirectorRepository _directorRepo = DirectorRepository();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  List<Director> _allDirectors = [];

  @override
  void initState() {
    super.initState();
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
    return _allDirectors.where((d) => 
      d.companies.any((c) => c.companyName == companyName)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);

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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.05 : 0.6),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, 
                  color: isDark ? Colors.white : const Color(0xFF1E293B), 
                  size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Abstract Background Shapes
            Positioned(
              top: -50,
              right: -50,
              child: _buildBlurCircle(primary.withOpacity(0.15), 200),
            ),
            Positioned(
              bottom: 20,
              left: -30,
              child: _buildBlurCircle(primary.withOpacity(0.1), 150),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: primary, size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              'VERIFIED DATABASE',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Company\nRegistry',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: 'Search Enterprise Data...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(Icons.manage_search_rounded, 
                color: primary, size: 24),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black45),
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
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStatItem('TOTAL', '${_companies.length}', Icons.layers_rounded, primary, isDark),
          const SizedBox(width: 12),
          _buildStatItem('ACTIVE', '100%', Icons.bolt_rounded, const Color(0xFF10B981), isDark),
          const SizedBox(width: 12),
          _buildStatItem('LOCATIONS', '12', Icons.place_rounded, const Color(0xFFF59E0B), isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            )),
            Text(label, style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCompanyCard(Company company, int index, bool isDark, Color primary) {
    final isBirthday = company.isBirthdayThisMonth;
    final companyDirectors = _getDirectorsForCompany(company.companyName);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isBirthday ? const Color(0xFF4A00E0).withOpacity(0.2) : primary.withOpacity(isDark ? 0.05 : 0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: isBirthday 
                  ? const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
                color: !isBirthday ? (isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.9)) : null,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isBirthday ? Colors.white.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showProfessionalDetails(company, isDark, primary, companyDirectors),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isBirthday ? Colors.white.withOpacity(0.2) : primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                                boxShadow: isBirthday ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 10,
                                  )
                                ] : null,
                              ),
                              child: Icon(
                                isBirthday ? Icons.cake_rounded : Icons.business_rounded, 
                                color: isBirthday ? Colors.white : primary, 
                                size: 24
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    company.companyName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isBirthday ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'CIN: ${company.cin}',
                                    style: TextStyle(
                                      color: isBirthday ? Colors.white70 : primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(color: isBirthday ? Colors.white24 : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniInfo('DIRECTORS', '${companyDirectors.length}', isDark, isBirthday),
                            _buildMiniInfo('AGE', '${company.age} Years', isDark, isBirthday),
                            _buildMiniInfo('INCORPORATED', company.dateOfIncorporation, isDark, isBirthday),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, bool isDark, bool isBirthday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          color: isBirthday ? Colors.white60 : (isDark ? Colors.white38 : Colors.black38),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        )),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          color: isBirthday ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        )),
      ],
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
                      _buildDetailSection('Board of Directors (${directors.length})', [
                        if (directors.isEmpty)
                          const Text('No directors listed for this company.')
                        else
                          ...directors.map((d) => _buildDirectorRow(d, isDark, primary)),
                      ], isDark),
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

  Widget _buildDirectorRow(Director director, bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primary.withOpacity(0.1),
            radius: 16,
            child: Text(
              director.name.isNotEmpty ? director.name[0] : 'D',
              style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  director.displayDin.isNotEmpty ? 'DIN: ${director.displayDin}' : 'No DIN',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        )),
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
