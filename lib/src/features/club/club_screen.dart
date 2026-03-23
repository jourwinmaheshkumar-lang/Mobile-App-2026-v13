import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/club_member.dart';
import '../../core/models/director.dart';
import '../../core/models/user.dart';
import '../../core/repositories/club_repository.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _directorRepo = DirectorRepository();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        final currentUser = authSnapshot.data;
        final isAdminOrOffice = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.officeTeam;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F4F6),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(isDark, isAdminOrOffice),
            ],
            body: Column(
              children: [
                _buildCustomTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: ClubLevel.values.map((level) => _buildClubTab(level, isDark, isAdminOrOffice)).toList(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: isAdminOrOffice ? _buildFAB(isDark) : null,
        );
      },
    );
  }

  Widget _buildAppBar(bool isDark, bool canManage) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF5C1228),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          clipBehavior: Clip.none,
          children: [
            // Multi-stop gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5C1228),
                    Color(0xFF8B1F45),
                    Color(0xFFC03060),
                    Color(0xFFFA425A),
                    Color(0xFFF6753A),
                    Color(0xFFF37950),
                  ],
                  stops: [0.0, 0.18, 0.38, 0.62, 0.82, 1.0],
                ),
              ),
            ),
            // Diagonal texture
            Positioned.fill(
              child: Opacity(
                opacity: 0.022,
                child: CustomPaint(painter: DiagonalTexturePainter()),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -30,
              right: 30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: -10,
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            // Content row (Perfectly centered vertically)
            Positioned(
              top: 10,
              bottom: 0,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Icon box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  // Title + subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Exclusive Clubs',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Elite Management Positions',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.68),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Edit Button (Integrated check as existing logic)
                  if (canManage)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _isEditing = !_isEditing);
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _isEditing ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Icon(_isEditing ? Icons.check_rounded : Icons.edit_note_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            // White curved arc at bottom
            Positioned(
              bottom: -28,
              left: -12,
              right: -12,
              child: Container(
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F4F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(200)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 2, left: 16, right: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(0xFF813563).withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Row(
            children: ClubLevel.values.map((level) {
              final index = level.index;
              final isSelected = _tabController.index == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _tabController.animateTo(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFA425A), Color(0xFFF37950)]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: const Color(0xFFFA425A).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
                          )
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                    child: Text(
                      level.displayName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFFB09AB0),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildClubTab(ClubLevel level, bool isDark, bool canManage) {
    return StreamBuilder<List<ClubMember>>(
      stream: clubRepository.getMembersAtLevel(level),
      builder: (context, snapshot) {
        final members = snapshot.data ?? [];
        final memberCount = members.length;

        Color accentColor;
        IconData tabIcon;
        String clubDesc = "Elite Positions";
        switch (level) {
          case ClubLevel.royal:
            accentColor = const Color(0xFFFA425A);
            tabIcon = Icons.star_rounded;
            clubDesc = "Highest tier — exclusive positions";
            break;
          case ClubLevel.diamond:
            accentColor = const Color(0xFF3498DB);
            tabIcon = Icons.diamond_rounded;
            clubDesc = "Premium tier — leadership roles";
            break;
          case ClubLevel.platinum:
            accentColor = const Color(0xFF813563);
            tabIcon = Icons.workspace_premium_rounded;
            clubDesc = "Strategic tier — advisory positions";
            break;
          case ClubLevel.gold:
            accentColor = const Color(0xFFC9920A);
            tabIcon = Icons.emoji_events_rounded;
            clubDesc = "Foundation tier — essential management";
            break;
        }

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: accentColor, width: 4)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFA425A), Color(0xFFF37950)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tabIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.displayName,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D1B2E)),
                      ),
                      Text(
                        clubDesc,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFFB09AB0)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEE9EC), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '$memberCount Members',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFFA425A)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : members.isEmpty
                      ? _buildEmptyState(level, isDark)
                      : _isEditing && canManage
                          ? ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: members.length,
                              onReorder: (oldIndex, newIndex) {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final items = List<ClubMember>.from(members);
                                final item = items.removeAt(oldIndex);
                                items.insert(newIndex, item);
                                clubRepository.reorderMembers(items);
                              },
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return _buildMemberCard(member, isDark, canManage, key: ValueKey(member.id));
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return _buildMemberCard(member, isDark, canManage);
                              },
                            ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberCard(ClubMember member, bool isDark, bool canManage, {Key? key}) {
    final gradient = member.level.gradient;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [gradient[0].withOpacity(0.2), gradient[1].withOpacity(0.1)]), shape: BoxShape.circle),
          child: Center(
            child: Text(
              member.directorName.isNotEmpty ? member.directorName[0].toUpperCase() : '?',
              style: TextStyle(color: gradient[0], fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        title: Text(member.directorName, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(member.level.displayNameTamil, style: TextStyle(color: gradient[0], fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                const SizedBox(width: 6),
                Text('Joined ${DateFormat('MMM yyyy').format(member.joinedAt)}', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: canManage && _isEditing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.person_remove_rounded, color: Color(0xFFEF4444), size: 18),
                    ),
                    onPressed: () => _confirmRemove(member),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.drag_indicator_rounded, color: isDark ? Colors.white24 : Colors.black12, size: 24),
                ],
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: gradient[0].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.verified_rounded, color: gradient[0], size: 18),
              ),
      ),
    );
  }

  Widget _buildEmptyState(ClubLevel level, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Outer dashed ring
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [const Color(0xFFFA425A).withOpacity(0.10), const Color(0xFFF37950).withOpacity(0.08)]),
              border: Border.all(
                color: const Color(0xFFFA425A).withOpacity(0.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [const Color(0xFFFA425A).withOpacity(0.15), const Color(0xFFF37950).withOpacity(0.12)]),
                ),
                child: Icon(Icons.group_rounded, color: const Color(0xFFFA425A).withOpacity(0.6), size: 26),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No members yet',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D1B2E)),
          ),
          const SizedBox(height: 6),
          Text(
            '${level.displayName} has no members assigned.\nTap below to add the first member.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFB09AB0), height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFEE9EC), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFFFA425A), size: 14),
                SizedBox(width: 5),
                Text(
                  'Add first member',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFFA425A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddMemberPicker(isDark),
      backgroundColor: Colors.transparent,
      elevation: 0,
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFA425A), Color(0xFFF37950)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFA425A).withOpacity(0.40), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Add Member',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMemberPicker(bool isDark) async {
    final level = ClubLevel.values[_tabController.index];
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DirectorPickerModal(
        level: level,
        isDark: isDark,
        onSelected: (director) async {
          await clubRepository.addMember(directorId: director.id, directorName: director.name, level: level);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _confirmRemove(ClubMember member) async {
    HapticFeedback.heavyImpact();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Remove ${member.directorName} from ${member.level.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );

    if (confirm == true) {
      await clubRepository.removeMember(member.id);
    }
  }
}

class DiagonalTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    const spacing = 12.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DirectorPickerModal extends StatefulWidget {
  final ClubLevel level;
  final bool isDark;
  final Function(Director) onSelected;

  const _DirectorPickerModal({required this.level, required this.isDark, required this.onSelected});

  @override
  State<_DirectorPickerModal> createState() => _DirectorPickerModalState();
}

class _DirectorPickerModalState extends State<_DirectorPickerModal> {
  String searchQuery = '';
  final _directorRepo = DirectorRepository();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(color: widget.isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: widget.isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: widget.level.gradient[0].withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.person_add_rounded, color: widget.level.gradient[0], size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Text('Add to ${widget.level.displayName}', style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: widget.isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
              child: TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(hintText: 'Search directors...', hintStyle: TextStyle(color: widget.isDark ? Colors.white30 : Colors.black26), prefixIcon: Icon(Icons.search_rounded, color: widget.isDark ? Colors.white30 : Colors.black26, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<Director>>(
              stream: _directorRepo.directorsStream,
              builder: (context, snapshot) {
                final allDirectors = snapshot.data ?? [];
                var filtered = allDirectors.where((d) {
                  if (searchQuery.isEmpty) return true;
                  return d.name.toLowerCase().contains(searchQuery.toLowerCase()) || d.din.contains(searchQuery.toLowerCase());
                }).toList()
                  ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                if (filtered.isEmpty) return const Center(child: Text('No directors found'));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      leading: CircleAvatar(backgroundColor: widget.level.gradient[0].withOpacity(0.12), child: Text(d.name[0].toUpperCase(), style: TextStyle(color: widget.level.gradient[0], fontWeight: FontWeight.bold))),
                      title: Text(d.name, style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                      subtitle: Text('DIN: ${d.din}', style: const TextStyle(fontSize: 12)),
                      trailing: Icon(Icons.add_circle_outline_rounded, color: widget.level.gradient[0]),
                      onTap: () => widget.onSelected(d),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
