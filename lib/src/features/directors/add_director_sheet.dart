import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/models/director.dart';
import '../../core/repositories/director_repository.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/company_data.dart';
import 'package:director_management/src/core/models/office.dart';
import 'package:director_management/src/core/repositories/office_repository.dart';

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
  List<CompanyDetail> _assignedCompanies = [];
  
  // New organizational fields
  String? _selectedOfficeId;
  String? _selectedOfficeName;
  late TextEditingController _officePostingController;
  bool _isSpecial = false;
  String? _specialRole;

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
    _assignedCompanies = List.from(widget.director?.companies ?? []);
    
    _selectedOfficeId = widget.director?.officeId;
    _selectedOfficeName = widget.director?.officeName;
    _officePostingController = TextEditingController(text: widget.director?.officePosting);
    _isSpecial = widget.director?.isSpecial ?? false;
    _specialRole = widget.director?.specialRole;
    
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
    _officePostingController.dispose();
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
      companies: _assignedCompanies,
      officeId: _selectedOfficeId,
      officeName: _selectedOfficeName,
      officePosting: _officePostingController.text,
      isSpecial: _isSpecial,
      specialRole: _specialRole,
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

  void _addCompany() {
    String? selectedCompany;
    final manualCompanyController = TextEditingController();
    final designationController = TextEditingController();
    final appointmentDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add Company Assignment', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SELECT COMPANY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF999999), letterSpacing: 1.0)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCompany,
                      hint: const Text('Select from 17 companies', style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFE8524A)),
                      items: CompanyData.companies.map((c) => DropdownMenuItem(
                        value: c.companyName,
                        child: Text(c.companyName, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
                      )).toList(),
                      onChanged: (val) => setDialogState(() {
                        selectedCompany = val;
                        manualCompanyController.clear();
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('OR MANUALLY ENTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF999999), letterSpacing: 1.0)),
                const SizedBox(height: 10),
                _buildSimpleField('Company Name', manualCompanyController),
                const SizedBox(height: 16),
                _buildSimpleField('Designation', designationController),
                const SizedBox(height: 16),
                _buildSimpleField('Appointment Date (DD MMM YYYY)', appointmentDateController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              onPressed: () {
                final name = selectedCompany ?? manualCompanyController.text;
                if (name.isNotEmpty) {
                  setState(() {
                    _assignedCompanies.add(CompanyDetail(
                      companyName: name,
                      designation: designationController.text,
                      appointmentDate: appointmentDateController.text,
                    ));
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8524A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8524A), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Requirements specify white background, so we don't use isDark here for the base colors
    // as per "White background" in "Overall Modal / Card" section.
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8524A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.director == null ? Icons.person_add_rounded : Icons.edit_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.director == null 
                            ? 'Add Director'
                            : 'Edit Director',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.director == null 
                            ? 'Create a new director record'
                            : 'Update director information',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // IDENTIFICATION
                    _buildSectionHeader('IDENTIFICATION', Icons.badge_rounded),
                    _buildInputField(
                      label: 'Full Name',
                      hint: 'Enter full name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'DIN Number',
                      hint: 'Enter 7-8 digit DIN',
                      controller: _dinController,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    
                    // COMPANY ASSIGNMENT
                    _buildSectionHeader('COMPANY ASSIGNMENT', Icons.business_center_rounded),
                    if (_assignedCompanies.isNotEmpty) ...[
                      ..._assignedCompanies.asMap().entries.map((entry) {
                        final index = entry.key;
                        final c = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.business_rounded, color: Color(0xFFE8524A), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A))),
                                    Text('${c.designation} (${c.appointmentDate})', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE8524A), size: 18),
                                onPressed: () => setState(() => _assignedCompanies.removeAt(index)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                    
                    TextButton.icon(
                      onPressed: _addCompany,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        foregroundColor: const Color(0xFFE8524A),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text(
                        'Add Company Assignment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'PAN Number',
                            hint: 'ABCDE1234F',
                            controller: _panController,
                            icon: Icons.credit_card_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: 'Aadhaar Number',
                            hint: '1234 5678 9012',
                            controller: _aadhaarNumberController,
                            icon: Icons.fingerprint_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    
                    // CONTACT
                    _buildSectionHeader('CONTACT INFORMATION', Icons.phone_rounded),
                    _buildInputField(
                      label: 'Email ID',
                      hint: 'email@example.com',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Bank Linked Phone',
                      hint: 'Enter phone number',
                      controller: _bankLinkedPhoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Aadhaar/PAN Phone',
                            hint: 'Phone number',
                            controller: _aadhaarPanPhoneController,
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: 'Email Linked Phone',
                            hint: 'Phone number',
                            controller: _emailPhoneController,
                            icon: Icons.phone_iphone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    
                    // ADDRESS
                    _buildSectionHeader('ADDRESS INFORMATION', Icons.location_on_rounded),
                    _buildMultiLineField(
                      label: 'Aadhaar Address',
                      hint: 'Enter address as per Aadhaar',
                      controller: _aadhaarAddressController,
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildMultiLineField(
                      label: 'Residential Address',
                      hint: 'Enter current residential address',
                      controller: _residentialAddressController,
                      icon: Icons.location_on_outlined,
                    ),
                    
                    // BANK DETAILS
                    _buildSectionHeader('IDBI BANK DETAILS', Icons.account_balance_rounded),
                    _buildMultiLineField(
                      label: 'Account Details',
                      hint: 'Enter account number, customer ID, etc.',
                      controller: _idbiAccountDetailsController,
                      icon: Icons.credit_card_outlined,
                    ),
                    
                    _buildSectionHeader('eMUDHRA ACCOUNT DETAILS', Icons.account_balance_wallet_rounded),
                    _buildMultiLineField(
                      label: 'Account Details',
                      hint: 'Enter A/c number, bank name, IFSC, branch',
                      controller: _emudhraAccountDetailsController,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    
                    // STATUS
                    _buildSectionHeader('STATUS', Icons.toggle_on_rounded),
                    Row(
                      children: [
                        Expanded(child: _buildStatusChip('Active', const Color(0xFF4CAF50))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatusChip('Inactive', const Color(0xFFE8524A))),
                      ],
                    ),

                    // ORGANIZATIONAL ROLE
                    _buildSectionHeader('ORGANIZATIONAL ROLE', Icons.stars_rounded),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFEAB308), size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Mark as Special Director',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A)),
                            ),
                          ),
                          Switch(
                            value: _isSpecial,
                            onChanged: (val) => setState(() => _isSpecial = val),
                            activeColor: const Color(0xFFEAB308),
                          ),
                        ],
                      ),
                    ),
                    if (_isSpecial) ...[
                      const SizedBox(height: 16),
                      const Text('SPECIAL ROLE / DESIGNATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF999999), letterSpacing: 1.0)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _specialRole,
                            hint: const Text('Select Role', style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFE8524A)),
                            items: [
                              'Chairman', 'Corporate Secretary', 'Dejour Group Charman', 
                              'Matrix Group Chairman', 'Jourwrin Group Charman', 'Group Advisor'
                            ].map((role) => DropdownMenuItem<String>(
                              value: role,
                              child: Text(role, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
                            )).toList(),
                            onChanged: (val) => setState(() => _specialRole = val),
                          ),
                        ),
                      ),
                    ],

                    // OFFICE ASSIGNMENT
                    _buildSectionHeader('OFFICE ASSIGNMENT', Icons.business_rounded),
                    const Text('ASSIGN TO OFFICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF999999), letterSpacing: 1.0)),
                    const SizedBox(height: 10),
                    StreamBuilder<List<Office>>(
                      stream: OfficeRepository().officesStream,
                      builder: (context, snapshot) {
                        final offices = snapshot.data ?? [];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedOfficeId,
                              hint: const Text('Select Office', style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFE8524A)),
                              items: offices.map((o) => DropdownMenuItem<String>(
                                value: o.id,
                                child: Text(o.name, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
                              )).toList(),
                              onChanged: (val) {
                                final office = offices.firstWhere((o) => o.id == val);
                                setState(() {
                                  _selectedOfficeId = val;
                                  _selectedOfficeName = office.name;
                                });
                              },
                            ),
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Office Posting / Designation',
                      hint: 'e.g. Senior Manager, Accountant',
                      controller: _officePostingController,
                      icon: Icons.work_outline_rounded,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFDECEA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFE8524A), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF999999),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 2),
              const Text('*', style: TextStyle(color: Color(0xFFE8524A), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFFE8524A)),
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8524A), width: 1.5),
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 30), // Align icon with top of multi-line
              child: Icon(icon, size: 20, color: const Color(0xFFE8524A)),
            ),
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8524A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _status = status);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            status,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF666666),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8524A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8524A).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ), // fixed comma
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : Text(
              widget.director == null ? 'Create Director' : 'Update Director',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
}
