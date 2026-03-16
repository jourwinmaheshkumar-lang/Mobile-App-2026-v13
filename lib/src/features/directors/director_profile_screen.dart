import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/director.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/theme.dart';
import '../../utils/app_icons.dart';

class DirectorProfileScreen extends StatefulWidget {
  const DirectorProfileScreen({super.key});

  @override
  State<DirectorProfileScreen> createState() => _DirectorProfileScreenState();
}

class _DirectorProfileScreenState extends State<DirectorProfileScreen> {
  final _repo = DirectorRepository();
  final _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendRequest(Director director, AppUser user) async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('admin_requests').add({
        'directorId': director.id,
        'directorName': director.name,
        'din': director.din,
        'userId': user.uid,
        'message': _messageController.text.trim(),
        'status': 'pending',
        'type': 'profile_update',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _messageController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request sent to administrator successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showRequestDialog(Director director, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Request Details Change',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Specify which details you want to update or add.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ex: Please update my residential address to...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : () => _sendRequest(director, user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Request', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: StreamBuilder<AppUser?>(
        stream: AuthService().userStream,
        builder: (context, authSnapshot) {
          if (!authSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = authSnapshot.data!;

          return StreamBuilder<List<Director>>(
            stream: _repo.directorsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Find the director record linked to this user
              final director = snapshot.data?.firstWhere(
                (d) => d.id == user.directorId,
                orElse: () => Director(id: 'none', name: 'Unknown'),
              );

              if (director == null || director.id == 'none') {
                return const Center(child: Text('No director profile linked to this account.'));
              }

              return CustomScrollView(
                slivers: [
                  _buildHeader(director),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Personal Information'),
                          _buildInfoCard([
                            _buildInfoTile('DIN', director.din, AppIcons.iconInfo),
                            _buildInfoTile('Aadhaar', director.aadhaarNumber, AppIcons.iconDocument),
                            _buildInfoTile('PAN', director.pan, AppIcons.iconDocument),
                            _buildInfoTile('Email', director.email, AppIcons.iconNotification),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Contact Details'),
                          _buildInfoCard([
                            _buildInfoTile('Bank Linked Phone', director.bankLinkedPhone, AppIcons.iconSearch),
                            _buildInfoTile('Aadhaar/PAN Linked', director.aadhaarPanLinkedPhone, AppIcons.iconSearch),
                            _buildInfoTile('Email Linked Phone', director.emailLinkedPhone, AppIcons.iconSearch),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Addresses'),
                          _buildInfoCard([
                            _buildInfoTile('Aadhaar Address', director.aadhaarAddress, AppIcons.iconHome),
                            _buildInfoTile('Residential Address', director.residentialAddress, AppIcons.iconHome),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Company Assignments'),
                          if (director.companies.isEmpty)
                            const Text('No companies assigned.')
                          else
                            ...director.companies.map((c) => _buildCompanyCard(c)),
                          const SizedBox(height: 40),
                          _buildRequestButton(director, user),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(Director director) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF1a1a2e),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset('assets/icons/profile_3d.png', width: 200, height: 200),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          director.name.isNotEmpty ? director.name[0] : '?',
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      director.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Director Profile',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(String label, String value, String iconPath) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(iconPath, width: 24, height: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  value.isEmpty ? 'Not Provided' : value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(CompanyDetail company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_rounded, color: AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${company.designation} • Joined: ${company.appointmentDate}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(Director director, AppUser user) {
    return Center(
      child: GestureDetector(
        onTap: () => _showRequestDialog(director, user),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Request Detail Change',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
