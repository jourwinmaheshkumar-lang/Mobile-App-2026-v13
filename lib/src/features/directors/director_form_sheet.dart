import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DirectorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? director;
  final bool isViewOnly;

  const DirectorFormSheet({super.key, this.director, this.isViewOnly = false});

  @override
  State<DirectorFormSheet> createState() => _DirectorFormSheetState();
}

class _DirectorFormSheetState extends State<DirectorFormSheet> {
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = !widget.isViewOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.person_rounded, 'Personal Information'),
                  _buildTextField('Full Name', 'Mahesh Kumar', Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('DIN Number', '01234567', Icons.badge_outlined)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown('Status', 'Active')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader(Icons.cake_rounded, 'Date of Birth'),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Official DOB', '15/05/1985', Icons.calendar_today_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Original DOB', '15/05/1985', Icons.event_rounded)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader(Icons.location_on_rounded, 'Address Details'),
                  _buildTextField('Aadhaar Address', '123, Indigo Street, Tech Park, Bangalore', Icons.home_rounded, maxLines: 2),
                  const SizedBox(height: 16),
                  _buildTextField('Current Address', '123, Indigo Street, Tech Park, Bangalore', Icons.map_rounded, maxLines: 2),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader(Icons.contact_phone_rounded, 'Contact & Verification'),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Official Mobile', '+91 9876543210', Icons.phone_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('PAN Number', 'ABCDE1234F', Icons.credit_card_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Official Email', 'mahesh.k@company.com', Icons.email_rounded),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader(Icons.account_balance_rounded, 'Banking & Accounts'),
                  _buildTextField('IDBI Details', 'Acc: 123456789012\nCIF: 98765432', Icons.account_balance_rounded, maxLines: 2),
                  const SizedBox(height: 16),
                  _buildTextField('eMudhra Details', 'Acc: 0987654321\nBank: HDFC Bank', Icons.security_rounded, maxLines: 2),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.director == null 
                        ? Icons.person_add_rounded 
                        : Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.director == null 
                      ? 'New Director' 
                      : (_isEditing ? 'Edit Profile' : 'Director Profile'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              crossAxisAlignment: maxLines > 1 
                ? CrossAxisAlignment.start 
                : CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppTheme.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isEditing)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _isEditing = true),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.edit_rounded, size: 20, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.border),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
