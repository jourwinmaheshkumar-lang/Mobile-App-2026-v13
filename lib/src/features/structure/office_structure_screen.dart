import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/models/office.dart';
import '../../core/models/director.dart';
import '../../core/repositories/office_repository.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import 'add_office_sheet.dart';
import '../directors/add_director_sheet.dart';

class OfficeStructureScreen extends StatefulWidget {
  const OfficeStructureScreen({super.key});

  @override
  State<OfficeStructureScreen> createState() => _OfficeStructureScreenState();
}

class _OfficeStructureScreenState extends State<OfficeStructureScreen> with TickerProviderStateMixin {
  final _officeRepo = OfficeRepository();
  final _directorRepo = DirectorRepository();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _officeRepo.initializeDefaults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<AppUser?>(
      stream: AuthService().userStream,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final canManage = user?.role == UserRole.admin || user?.role == UserRole.officeTeam;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFB),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                       _buildTabButtons(isDark),
                       const SizedBox(height: 32),
                       _buildContent(isDark, canManage),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: canManage && _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddOfficeSheet(context),
                  backgroundColor: const Color(0xFF4C1D95),
                  icon: const Icon(Icons.add_business_rounded, color: Colors.white),
                  label: Text('NEW OFFICE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.white)),
                )
              : null,
        );
      }
    );
  }

  void _showAddOfficeSheet(BuildContext context, {Office? office}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddOfficeSheet(
        office: office,
        onSave: () => setState(() {}),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF4C1D95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.7, 1.0],
              colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF6D28D9)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Corporate Architecture',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DESIGNING THE FUTURE PHUKET STRUCTURE',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
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

  Widget _buildTabButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Leadership', Icons.stars_rounded, isDark),
          _buildTabItem(1, 'Offices', Icons.business_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon, bool isDark) {
    final isActive = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabController.index = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive 
                ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF4C1D95)) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive ? [
              BoxShadow(
                color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF4C1D95)).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.black45), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, bool canManage) {
    return _tabController.index == 0 
      ? _buildLeadershipTab(isDark, canManage) 
      : _buildOfficesTab(isDark, canManage);
  }

  Widget _buildLeadershipTab(bool isDark, bool canManage) {
    return StreamBuilder<List<Director>>(
      stream: _directorRepo.directorsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final directors = snapshot.data!;
        if (directors.isEmpty) return const Center(child: Text('No directors found.'));
        
        final chairmanList = directors.where((d) => d.specialRole?.toLowerCase() == 'chairman').toList();
        final hasRealChairman = chairmanList.isNotEmpty;
        final chairman = hasRealChairman ? chairmanList.first : Director(id: 'dummy', name: 'T.Saravanamuthu @PaulSaravanan', serialNo: 0, din: '', email: '', status: 'Active');
        
        final specialOnes = directors.where((d) => 
          (d.isSpecial == true || (d.specialRole != null && d.specialRole!.isNotEmpty)) && 
          d.specialRole?.toLowerCase() != 'chairman'
        ).toList()..sort((a,b) => a.serialNo.compareTo(b.serialNo));

        return Column(
          children: [
             _buildChairmanNode(chairman, isDark, canManage),
             _buildConnectingBridge(isDark),
             
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 40),
               child: Text(
                 '“Operates under the direct authority of the Chairman with direct reporting responsibility.”',
                 textAlign: TextAlign.center,
                 style: GoogleFonts.inter(
                   fontSize: 11,
                   fontWeight: FontWeight.w600,
                   fontStyle: FontStyle.italic,
                   letterSpacing: 0.2,
                   color: isDark ? Colors.white38 : Colors.black38,
                 ),
               ),
             ),
             _buildConnectingBridge(isDark),
             
             ReorderableListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: specialOnes.length,
               proxyDecorator: (child, index, animation) => Material(
                 elevation: 10,
                 borderRadius: BorderRadius.circular(20),
                 color: isDark ? const Color(0xFF334155) : Colors.white,
                 child: child,
               ),
               onReorder: (oldIndex, newIndex) async {
                 if (newIndex > oldIndex) newIndex -= 1;
                 if (oldIndex == newIndex) return;
                 
                 final items = List<Director>.from(specialOnes);
                 final item = items.removeAt(oldIndex);
                 items.insert(newIndex, item);
                 
                 // Update serial numbers locally for immediate feedback
                 setState(() {
                   // We trust the stream to catch up
                 });

                 // Bulk update serial numbers in repository
                 for (int i = 0; i < items.length; i++) {
                   int newSerial = i + 1;
                   if (items[i].serialNo != newSerial) {
                     await _directorRepo.update(items[i].copyWith(serialNo: newSerial));
                   }
                 }
               },
               itemBuilder: (context, index) => _buildReportingNode(specialOnes[index], isDark, canManage, key: ValueKey(specialOnes[index].id)),
             ),
             if (canManage) ...[
                const SizedBox(height: 24),
                _buildAddSpecialButton(context),
                const SizedBox(height: 60),
             ],
          ],
        );
      },
    );
  }

  Widget _buildAddSpecialButton(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4C1D95).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _showDirectorPicker(context, isForSpecialRole: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4C1D95),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'ASSIGN BOARD DIRECTOR',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDirectorPicker(BuildContext context, {Office? office, bool isForSpecialRole = false}) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Text(
                        isForSpecialRole ? 'Assign Special Role' : 'Add to ${office?.name}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (val) => setModalState(() => searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search directors...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Director>>(
                    stream: _directorRepo.directorsStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      var directors = snapshot.data!.where((d) => d.status == 'Active').toList();
                      directors.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                      if (searchQuery.isNotEmpty) {
                        directors = directors.where((d) => d.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                      }
                      if (isForSpecialRole) {
                        directors = directors.where((d) => !d.isSpecial).toList();
                      } else if (office != null) {
                        directors = directors.where((d) => d.officeId != office.id).toList();
                      }
                      
                      if (directors.isEmpty) {
                        return Center(child: Text('No active directors found', style: GoogleFonts.inter(color: Colors.grey)));
                      }
                      
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: directors.length,
                        itemBuilder: (context, index) {
                          final d = directors[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(d.name.isNotEmpty ? d.name[0] : '?')),
                            title: Text(d.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(d.officeName ?? 'No Office', style: GoogleFonts.inter(fontSize: 12)),
                            onTap: () async {
                              Navigator.pop(context);
                              if (isForSpecialRole) {
                                _editDirectorRole(d, forceSpecial: true);
                              } else if (office != null) {
                                await _directorRepo.update(d.copyWith(officeId: office.id, officeName: office.name));
                                setState(() {});
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChairmanNode(Director chairman, bool isDark, bool canManage) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF4C1D95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle corner accent
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(100)),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    chairman.name.isNotEmpty ? chairman.name[0] : 'T',
                    style: GoogleFonts.inter(color: const Color(0xFF4C1D95), fontWeight: FontWeight.w900, fontSize: 32),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'T.Saravanamuthu @PaulSaravanan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'CHAIRMAN',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
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

  Widget _buildConnectingBridge(bool isDark) {
    return Container(
      width: 2,
      height: 48,
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  Widget _buildReportingNode(Director director, bool isDark, bool canManage, {required Key key}) {
    final roleColor = _getRoleColor(director.specialRole);
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDirectorDetail(director),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: roleColor.withOpacity(0.1),
                child: Text(
                  director.name[0],
                  style: GoogleFonts.inter(color: roleColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      director.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 12, color: roleColor),
                        const SizedBox(width: 6),
                        Text(
                          (director.specialRole ?? 'Staff').toUpperCase(),
                          style: GoogleFonts.inter(
                            color: roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                ReorderableDragStartListener(
                  index: 0, // Not really used here index-wise in this builder pattern but good for UI
                  child: Icon(Icons.drag_indicator_rounded, color: Colors.grey.withOpacity(0.5)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 26),
                  onPressed: () => _editDirectorRole(director),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editDirectorRole(Director d, {bool forceSpecial = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DirectorRoleEditor(
        director: d,
        forceSpecial: forceSpecial,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _showDirectorDetail(Director d) {
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
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: const Color(0xFF6366F1).withOpacity(0.1), child: Text(d.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)))),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(d.specialRole ?? d.officePosting ?? 'Team Member', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailTile('DIN Number', d.din, Icons.fingerprint_rounded),
              _buildDetailTile('Email', d.email.isEmpty ? 'Not Provided' : d.email, Icons.email_outlined),
              _buildDetailTile('Phone', d.bankLinkedPhone.isEmpty ? 'Not Provided' : d.bankLinkedPhone, Icons.phone_android_rounded),
              _buildDetailTile('Office Hub', d.officeName ?? 'Not Assigned', Icons.business_rounded),
              _buildDetailTile('Posting', d.officePosting ?? 'Not Assigned', Icons.work_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6366F1)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficesTab(bool isDark, bool canManage) {
    return StreamBuilder<List<Office>>(
      stream: _officeRepo.officesStream,
      builder: (context, officeSnapshot) {
        return StreamBuilder<List<Director>>(
          stream: _directorRepo.directorsStream,
          builder: (context, directorSnapshot) {
            if (!officeSnapshot.hasData || !directorSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final offices = officeSnapshot.data!;
            final directors = directorSnapshot.data!;
            return Column(
              children: [
                const SizedBox(height: 10),
                ...offices.map((office) {
                  final officeStaff = directors.where((d) => d.officeId == office.id).toList();
                  return _buildOfficeCollapsibleCard(office, officeStaff, isDark, canManage);
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOfficeCollapsibleCard(Office office, List<Director> staff, bool isDark, bool canManage) {
    final typeColor = _getOfficeTypeColor(office.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: typeColor.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: typeColor,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(office.type.toLowerCase().contains('head') ? Icons.account_balance_rounded : Icons.location_city_rounded, color: typeColor, size: 24),
        ),
        title: Text(office.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        trailing: canManage 
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) async {
                if (val == 'edit') {
                  _showAddOfficeSheet(context, office: office);
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Office Hub?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE'))]));
                  if (confirm == true) { await _officeRepo.deleteOffice(office.id); setState(() {}); }
                }
              },
              itemBuilder: (context) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), const PopupMenuItem(value: 'delete', child: Text('Delete'))],
            )
          : null,
        subtitle: Text(office.location, style: const TextStyle(fontSize: 11)),
        children: [
          const Divider(indent: 20, endIndent: 20),
          if (staff.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Text('No employees assigned yet.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)))
          else
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(children: staff.map((d) => _buildStaffItem(d, isDark, canManage)).toList())),
          if (canManage) Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildAssignSmallButton(office)),
        ],
      ),
    );
  }

  Widget _buildStaffItem(Director d, bool isDark, bool canManage) {
    return GestureDetector(
      onTap: () => _showDirectorDetail(d),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: const Color(0xFF6366F1).withOpacity(0.1), child: Text(d.name.isNotEmpty ? d.name[0] : '?', style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.bold))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)), Text(d.officePosting ?? 'Associate', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11))])),
            if (canManage) IconButton(icon: const Icon(Icons.edit_note_rounded, size: 18), onPressed: () => _editDirectorRole(d)),
          ],
        ),
      ),
    );
  }

  Color _getOfficeTypeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('head')) return const Color(0xFF4C1D95);
    if (t.contains('corporate')) return const Color(0xFF0D9488);
    return const Color(0xFF6366F1);
  }

  Widget _buildVerticalBridge(bool isDark, {double height = 50}) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFACC15).withOpacity(0.8),
            const Color(0xFF6366F1).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 10),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    if (role == null) return const Color(0xFF6366F1);
    final r = role.toLowerCase();
    if (r.contains('chairman')) return const Color(0xFFEAB308);
    if (r.contains('secretary')) return const Color(0xFF0D9488);
    if (r.contains('advisor')) return const Color(0xFF6366F1);
    return const Color(0xFF8B5CF6);
  }

  Widget _buildAssignSmallButton(Office office) {
    return TextButton.icon(
      onPressed: () => _assignNewEmployeeToOffice(office),
      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
      label: const Text('ADD EMPLOYEE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _assignNewEmployeeToOffice(Office office) {
    _showDirectorPicker(context, office: office);
  }
}

class _DirectorRoleEditor extends StatefulWidget {
  final Director director;
  final bool forceSpecial;
  final VoidCallback onSave;
  const _DirectorRoleEditor({required this.director, this.forceSpecial = false, required this.onSave});
  @override
  State<_DirectorRoleEditor> createState() => _DirectorRoleEditorState();
}

class _DirectorRoleEditorState extends State<_DirectorRoleEditor> {
  late TextEditingController _postingController;
  late TextEditingController _specialRoleController;
  late bool _isSpecial;
  final _directorRepo = DirectorRepository();

  @override
  void initState() {
    super.initState();
    _postingController = TextEditingController(text: widget.director.officePosting);
    _specialRoleController = TextEditingController(text: widget.director.specialRole);
    // If forced or already special, set to true
    _isSpecial = widget.forceSpecial || widget.director.isSpecial;
    // Default special role if forced but empty
    if (widget.forceSpecial && (_specialRoleController.text.isEmpty)) {
      _specialRoleController.text = 'Director';
    }
  }

  @override
  void dispose() {
    _postingController.dispose();
    _specialRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.director;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, -10)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 32),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(d.name[0], style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Current: ${d.officePosting ?? d.specialRole ?? 'No Role Assigned'}', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Special Toggle Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSpecial ? const Color(0xFF6366F1).withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isSpecial ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: _isSpecial ? const Color(0xFF6366F1) : Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text('Leadership / Special Role', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                      const Spacer(),
                      Switch.adaptive(
                        value: _isSpecial,
                        activeColor: const Color(0xFF6366F1),
                        onChanged: (val) => setState(() => _isSpecial = val),
                      ),
                    ],
                  ),
                  if (_isSpecial) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _specialRoleController,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Leadership Title',
                        hintText: 'e.g. Director, Secretary, Advisor',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text('OFFICE ASSIGNMENT & POSTING', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            TextField(
              controller: _postingController,
              decoration: InputDecoration(
                hintText: 'e.g. Associate, General Manager',
                labelText: 'Job Role / Posting',
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
              ),
            ),
            
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context, 
                        builder: (context) => AlertDialog(
                          title: const Text('Unassign?'),
                          content: const Text('Remove from current hierarchy position?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('REMOVE')),
                          ],
                        )
                      );
                      if (confirm == true) {
                        await _directorRepo.update(d.copyWith(
                          clearOffice: true,
                          clearSpecial: true,
                        ));
                        if (mounted) { Navigator.pop(context); widget.onSave(); }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('UNASSIGN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _directorRepo.update(d.copyWith(
                        officePosting: _postingController.text,
                        isSpecial: _isSpecial,
                        specialRole: _isSpecial ? _specialRoleController.text : null,
                      ));
                      if (mounted) { Navigator.pop(context); widget.onSave(); }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('SAVE CHANGES', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

