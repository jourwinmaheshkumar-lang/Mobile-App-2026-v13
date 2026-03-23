import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/director.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/theme.dart';
import '../../../utils/app_icons.dart';

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

              return Container(
                color: AppTheme.background,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(director),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (director.isSpecial) ...[
                              _buildSectionTitle('Special Status'),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEAB308).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            director.specialRole ?? 'Special Director',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            'Core Management Group Member',
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(0.8),
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
                              const SizedBox(height: 24),
                            ],

                            _buildSectionTitle('Organizational Placement'),
                            _buildInfoCard([
                              _buildInfoTile('Office', director.officeName ?? 'Not Assigned', Icons.business_rounded),
                              _buildInfoTile('Posting', director.officePosting ?? 'Not Assigned', Icons.work_outline_rounded),
                            ]),
                            const SizedBox(height: 24),

                            _buildSectionTitle('Personal Information'),
                            _buildInfoCard([
                              _buildInfoTile('DIN', director.din, Icons.fingerprint_rounded),
                              _buildInfoTile('Aadhaar', director.aadhaarNumber, Icons.badge_outlined),
                              _buildInfoTile('PAN', director.pan, Icons.assignment_ind_outlined),
                              _buildInfoTile('Email', director.email, Icons.email_outlined),
                            ]),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Contact Details'),
                            _buildInfoCard([
                              _buildInfoTile('Bank Phone', director.bankLinkedPhone, Icons.phone_android_rounded),
                              _buildInfoTile('Aadhaar Phone', director.aadhaarPanLinkedPhone, Icons.phone_iphone_rounded),
                              _buildInfoTile('Secondary Phone', director.emailLinkedPhone, Icons.contact_phone_outlined),
                            ]),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Addresses'),
                            _buildInfoCard([
                              _buildInfoTile('Aadhaar Address', director.aadhaarAddress, Icons.location_on_outlined),
                              _buildInfoTile('Residential Address', director.residentialAddress, Icons.home_outlined),
                            ]),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Company Assignments'),
                            if (director.companies.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('No companies assigned.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                              )
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
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(Director director) {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: false,
      floating: true,
      snap: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.premiumGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.account_circle_rounded, size: 200, color: Colors.white),
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
                        border: Border.all(color: AppTheme.warning, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          director.name.isNotEmpty ? director.name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      director.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Official Director Portfolio',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(), 
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, 
                    fontSize: 9, 
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  )
                ),
                Text(
                  value.isEmpty ? 'Not Provided' : value,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600, 
                    fontSize: 14,
                  ),
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
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.companyName, 
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  )
                ),
                Text(
                  '${company.designation} • Since ${company.appointmentDate}',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, 
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Request Detail Change',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
