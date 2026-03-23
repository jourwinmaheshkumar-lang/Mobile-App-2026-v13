import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme.dart';
import '../../core/repositories/director_repository.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  String _searchQuery = '';
  final Set<String> _revealedPasswords = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: Text(
          'User Management', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 20)
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }
                
                final docs = snapshot.data!.docs;
                final users = docs.map((doc) => AppUser.fromDoc(doc)).toList();
                
                final filteredUsers = users.where((u) => 
                  u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (u.mobile?.contains(_searchQuery) ?? false)
                ).toList();

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by DIN or Mobile',
            hintStyle: GoogleFonts.inter(color: AppTheme.hintText, fontSize: 14),
            border: InputBorder.none,
            icon: const Icon(Icons.search_rounded, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = user.uid == _authService.currentUser?.uid;

    final directorRepo = DirectorRepository();
    String displayTitle = user.displayName ?? '';
    if (displayTitle.isEmpty) {
      final match = directorRepo.all.where((d) => d.din == user.username || (user.directorId != null && d.id == user.directorId)).firstOrNull;
      if (match != null && match.name.isNotEmpty) {
        displayTitle = match.name;
      } else {
        displayTitle = user.username;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
        children: [
          CircleAvatar(
            backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
              child: Text(
              displayTitle.isNotEmpty ? displayTitle[0].toUpperCase() : 'U',
              style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                ),
                Text(
                  (displayTitle != user.username) 
                      ? '${user.username} | ${user.mobile ?? 'No Mobile'}' 
                      : (user.mobile ?? 'No Mobile'),
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text(
                        _revealedPasswords.contains(user.uid) 
                            ? (user.password ?? 'Password Not Found') 
                            : '••••••••',
                        style: TextStyle(
                          color: _revealedPasswords.contains(user.uid) 
                              ? (user.password != null ? AppTheme.primary : Colors.red) 
                              : Colors.grey,
                          fontSize: 12,
                          fontFamily: _revealedPasswords.contains(user.uid) ? null : 'monospace',
                          fontWeight: _revealedPasswords.contains(user.uid) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_revealedPasswords.contains(user.uid)) {
                              _revealedPasswords.remove(user.uid);
                            } else {
                              _revealedPasswords.add(user.uid);
                            }
                          });
                        },
                        child: Icon(
                          _revealedPasswords.contains(user.uid) ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildRoleBadge(user.role),
          if (!isMe)
            IconButton(
              onPressed: () => _showRoleSwitchDialog(user),
              icon: Icon(Icons.shield_outlined, color: isDark ? Colors.white60 : Colors.black45),
              tooltip: 'Manage Access',
            ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.person_pin_circle_rounded, color: AppTheme.primary, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return AppTheme.primary;
      case UserRole.officeTeam: return const Color(0xFF3498DB);
      case UserRole.director: return const Color(0xFFF39C12);
    }
  }

  void _showRoleSwitchDialog(AppUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: isDark ? Border(top: BorderSide(color: Colors.white.withOpacity(0.1))) : null,
        ),
        child: SingleChildScrollView(
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
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Manage Access Level',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update permissions for ${user.displayName ?? user.username}',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 24),
              _buildRoleOption(user, UserRole.director, 'Director', 'Standard access to view director records', Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildRoleOption(user, UserRole.officeTeam, 'Office Team', 'Management access to edit and update records', Icons.manage_accounts_outlined),
              const SizedBox(height: 12),
              _buildRoleOption(user, UserRole.admin, 'Super Admin', 'Full system control and user management', Icons.shield_rounded),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _showSetPasswordDialog(user);
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.orange),
                ),
                title: const Text('Set New Password', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Manually set login credentials for this user', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetPasswordDialog(AppUser user) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Password for ${user.username}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a new password that this user will use to log in.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Minimum 6 characters',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
              obscureText: false, // Admins should see what they are setting
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                return;
              }
              Navigator.pop(context);
              await _authService.setUserPassword(user.uid, controller.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password set for ${user.username}'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('SET PASSWORD'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(AppUser user, UserRole role, String title, String desc, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = user.role == role;
    final roleColor = _getRoleColor(role);
    
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await _authService.promoteUser(user.uid, role);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access updated: ${user.username} is now a $title'),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? roleColor.withOpacity(0.1) 
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? roleColor : (isDark ? Colors.white10 : Colors.transparent),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: roleColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      color: isDark ? Colors.white : Colors.black,
                    )
                  ),
                  Text(
                    desc, 
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? Colors.white38 : Colors.grey,
                    )
                  ),
                ],
              ),
            ),
            if (isSelected) 
              Icon(Icons.check_circle_rounded, color: roleColor),
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
          Icon(Icons.group_off_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No users found', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
