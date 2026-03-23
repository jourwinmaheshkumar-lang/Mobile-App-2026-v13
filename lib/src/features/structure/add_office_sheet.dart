import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/office.dart';
import '../../core/repositories/office_repository.dart';
import '../../core/theme.dart';

class AddOfficeSheet extends StatefulWidget {
  final Office? office;
  final VoidCallback onSave;

  const AddOfficeSheet({super.key, this.office, required this.onSave});

  @override
  State<AddOfficeSheet> createState() => _AddOfficeSheetState();
}

class _AddOfficeSheetState extends State<AddOfficeSheet> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  String _selectedType = 'Branch Office';
  bool _saving = false;

  final List<String> _officeTypes = [
    'Head Office',
    'Corporate Office',
    'Branch Office',
    'Regional Office',
    'Virtual Office'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.office?.name);
    _locationController = TextEditingController(text: widget.office?.location);
    _addressController = TextEditingController(text: widget.office?.address);
    _phoneController = TextEditingController(text: widget.office?.phone);
    if (widget.office != null && _officeTypes.contains(widget.office!.type)) {
      _selectedType = widget.office!.type;
    } else if (widget.office != null) {
      _selectedType = widget.office!.type;
      if (!_officeTypes.contains(_selectedType)) {
        _officeTypes.insert(0, _selectedType);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Location are required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    final office = Office(
      id: widget.office?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _selectedType,
      location: _locationController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    try {
      if (widget.office == null) {
        await OfficeRepository().addOffice(office);
      } else {
        await OfficeRepository().updateOffice(office);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.office == null ? 'New Office Hub' : 'Edit Office Hub',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                   _buildSectionLabel('OFFICE NAME'),
                   _buildTextField(_nameController, 'e.g. Head Office, Dubai Branch', Icons.edit_rounded),
                   const SizedBox(height: 20),
                   
                   _buildSectionLabel('OFFICE TYPE'),
                   _buildDropdown(),
                   const SizedBox(height: 20),

                   _buildSectionLabel('LOCATION (CITY/REGION)'),
                   _buildTextField(_locationController, 'e.g. Chennai, London, Remote', Icons.location_on_rounded),
                   const SizedBox(height: 20),

                   _buildSectionLabel('FULL ADDRESS'),
                   _buildTextField(_addressController, 'Detailed office address...', Icons.map_rounded, maxLines: 2),
                   const SizedBox(height: 20),

                   _buildSectionLabel('CONTACT PHONE'),
                   _buildTextField(_phoneController, '+1 234 567 890', Icons.phone_rounded, keyboardType: TextInputType.phone),
                   
                   const SizedBox(height: 40),
                   _buildSaveButton(),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[600], letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6366F1)),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
          items: _officeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
        ),
        child: _saving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.office == null ? 'CREATE OFFICE' : 'UPDATE OFFICE',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
              ),
      ),
    );
  }
}
