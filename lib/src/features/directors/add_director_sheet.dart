import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/models/director.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/services/localization_service.dart';

class AddDirectorSheet extends StatefulWidget {
  final Director? director;
  final VoidCallback onSave;

  const AddDirectorSheet({super.key, this.director, required this.onSave});

  @override
  State<AddDirectorSheet> createState() => _AddDirectorSheetState();
}

class _AddDirectorSheetState extends State<AddDirectorSheet>
    with SingleTickerProviderStateMixin {
  // Basic Info
  late TextEditingController _nameController;
  late TextEditingController _dinController;
  late TextEditingController _emailController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarNumberController;
  
  // Address
  late TextEditingController _aadhaarAddressController;
  late TextEditingController _residentialAddressController;
  
  // Phone Numbers
  late TextEditingController _bankLinkedPhoneController;
  late TextEditingController _aadhaarPanPhoneController;
  late TextEditingController _emailPhoneController;
  
  // Bank Details
  late TextEditingController _idbiAccountDetailsController;
  late TextEditingController _emudhraAccountDetailsController;
  
  String _status = 'Active';
  bool _saving = false;
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.director?.name);
    _dinController = TextEditingController(text: widget.director?.din);
    _emailController = TextEditingController(text: widget.director?.email);
    _panController = TextEditingController(text: widget.director?.pan);
    _aadhaarNumberController = TextEditingController(text: widget.director?.aadhaarNumber);
    _aadhaarAddressController = TextEditingController(text: widget.director?.aadhaarAddress);
    _residentialAddressController = TextEditingController(text: widget.director?.residentialAddress);
    _bankLinkedPhoneController = TextEditingController(text: widget.director?.bankLinkedPhone);
    _aadhaarPanPhoneController = TextEditingController(text: widget.director?.aadhaarPanLinkedPhone);
    _emailPhoneController = TextEditingController(text: widget.director?.emailLinkedPhone);
    _idbiAccountDetailsController = TextEditingController(text: widget.director?.idbiAccountDetails);
    _emudhraAccountDetailsController = TextEditingController(text: widget.director?.emudhraAccountDetails);
    _status = widget.director?.status ?? 'Active';
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dinController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _aadhaarNumberController.dispose();
    _aadhaarAddressController.dispose();
    _residentialAddressController.dispose();
    _bankLinkedPhoneController.dispose();
    _aadhaarPanPhoneController.dispose();
    _emailPhoneController.dispose();
    _idbiAccountDetailsController.dispose();
    _emudhraAccountDetailsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(localizationService.tr('name_required')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    final director = Director(
      id: widget.director?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      serialNo: widget.director?.serialNo ?? 0,
      name: _nameController.text,
      din: _dinController.text,
      email: _emailController.text,
      pan: _panController.text,
      aadhaarNumber: _aadhaarNumberController.text,
      aadhaarAddress: _aadhaarAddressController.text,
      residentialAddress: _residentialAddressController.text,
      bankLinkedPhone: _bankLinkedPhoneController.text,
      aadhaarPanLinkedPhone: _aadhaarPanPhoneController.text,
      emailLinkedPhone: _emailPhoneController.text,
      idbiAccountDetails: _idbiAccountDetailsController.text,
      emudhraAccountDetails: _emudhraAccountDetailsController.text,
      status: _status,
    );

    try {
      if (widget.director == null) {
        await DirectorRepository().add(director);
      } else {
        await DirectorRepository().update(director);
      }
      
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      widget.onSave();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(widget.director == null 
                ? localizationService.tr('director_created_synced') 
                : localizationService.tr('director_updated_synced')),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Error saving: $e')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Theme.of(context).brightness == Brightness.dark 
              ? const Border(top: BorderSide(color: Color(0xFF334155))) 
              : null,
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF475569) 
                    : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.primaryShadow,
                    ),
                    child: Icon(
                      widget.director == null 
                        ? Icons.person_add_rounded 
                        : Icons.edit_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.director == null 
                            ? localizationService.tr('add_director') 
                            : localizationService.tr('edit_director'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFFF8FAFC) 
                                : AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.director == null 
                            ? localizationService.tr('create_new_record')
                            : localizationService.tr('update_info'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFF94A3B8) 
                                : AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Close Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF334155) 
                              : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF94A3B8) 
                              : AppTheme.textTertiary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              height: 1,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF334155) 
                  : AppTheme.borderLight,
            ),
            
            // Scrollable form
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // IDENTIFICATION
                    _buildSectionHeader(localizationService.tr('identification'), Icons.badge_rounded),
                    _buildInputField(
                      label: localizationService.tr('full_name'),
                      hint: localizationService.tr('enter_full_name'),
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: localizationService.tr('din_number'),
                      hint: localizationService.tr('enter_din'),
                      controller: _dinController,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: localizationService.tr('pan_number'),
                            hint: 'ABCDE1234F',
                            controller: _panController,
                            icon: Icons.credit_card_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: localizationService.tr('aadhaar_number'),
                            hint: '1234 5678 9012',
                            controller: _aadhaarNumberController,
                            icon: Icons.fingerprint_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    
                    // CONTACT
                    _buildSectionHeader(localizationService.tr('contact_info'), Icons.phone_rounded),
                    _buildInputField(
                      label: localizationService.tr('email_id'),
                      hint: 'email@example.com',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: localizationService.tr('bank_linked_phone'),
                      hint: localizationService.tr('enter_phone'),
                      controller: _bankLinkedPhoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: localizationService.tr('aadhaar_pan_phone'),
                            hint: localizationService.tr('phone_number'),
                            controller: _aadhaarPanPhoneController,
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: localizationService.tr('email_linked_phone'),
                            hint: localizationService.tr('phone_number'),
                            controller: _emailPhoneController,
                            icon: Icons.phone_iphone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    
                    // ADDRESS
                    _buildSectionHeader(localizationService.tr('address_info'), Icons.location_on_rounded),
                    _buildMultiLineField(
                      label: localizationService.tr('aadhaar_address'),
                      hint: localizationService.tr('enter_address_aadhaar'),
                      controller: _aadhaarAddressController,
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildMultiLineField(
                      label: localizationService.tr('residential_address'),
                      hint: localizationService.tr('enter_residential_address'),
                      controller: _residentialAddressController,
                      icon: Icons.location_on_outlined,
                    ),
                    
                    // BANK DETAILS
                    _buildSectionHeader(localizationService.tr('idbi_bank_details'), Icons.account_balance_rounded),
                    _buildMultiLineField(
                      label: localizationService.tr('account_details'),
                      hint: localizationService.tr('enter_account_details_idbi'),
                      controller: _idbiAccountDetailsController,
                      icon: Icons.credit_card_outlined,
                    ),
                    
                    _buildSectionHeader(localizationService.tr('emudhra_details'), Icons.account_balance_wallet_rounded),
                    _buildMultiLineField(
                      label: localizationService.tr('account_details'),
                      hint: localizationService.tr('enter_account_details_emudhra'),
                      controller: _emudhraAccountDetailsController,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    
                    // STATUS
                    _buildSectionHeader(localizationService.tr('status_label'), Icons.toggle_on_rounded),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusChip(localizationService.tr('active'), AppTheme.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusChip(localizationService.tr('inactive'), AppTheme.error),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    _buildSaveButton(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF64748B) 
                  : AppTheme.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFFCBD5E1) 
                    : AppTheme.textSecondary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF0F172A) 
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF334155) 
                  : AppTheme.borderLight,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFF8FAFC) 
                  : AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 20, color: AppTheme.primary),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiLineField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFCBD5E1) 
                : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF0F172A) 
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF334155) 
                  : AppTheme.borderLight,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFF8FAFC) 
                  : AppTheme.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    final isSelected = _status == status;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _status = status);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: _saving ? null : AppTheme.primaryGradient,
        color: _saving ? AppTheme.primary.withOpacity(0.7) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: _saving ? null : AppTheme.primaryShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saving ? null : _save,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.director == null 
                          ? Icons.add_rounded 
                          : Icons.save_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.director == null 
                          ? localizationService.tr('create_director') 
                          : localizationService.tr('update_director'),
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
      ),
    );
  }
}
