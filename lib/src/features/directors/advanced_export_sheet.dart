import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/models/director.dart';
import 'director_export_service.dart';
import 'pdf_preview_screen.dart';
import '../../core/services/localization_service.dart';

class AdvancedExportSheet extends StatefulWidget {
  final List<Director> directors;
  final String filterName;

  const AdvancedExportSheet({
    super.key,
    required this.directors,
    this.filterName = 'All Directors',
  });

  @override
  State<AdvancedExportSheet> createState() => _AdvancedExportSheetState();
}

class _AdvancedExportSheetState extends State<AdvancedExportSheet> {
  late ExportOptions _options;
  bool _isExporting = false;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  
  // Director selection state
  late Map<String, bool> _selectedDirectors;
  bool _showDirectorSelection = false;
  String _searchQuery = '';
  
  final _fileNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _reportTitleController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _options = ExportOptions(
      fields: DirectorExportService.getAvailableFields(),
      reportTitle: widget.filterName,
    );
    _fileNameController.text = 'directors_export';
    _reportTitleController.text = widget.filterName;
    
    // Initialize all directors as selected
    _selectedDirectors = {
      for (var director in widget.directors) director.id: true
    };
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _companyNameController.dispose();
    _reportTitleController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Get selected directors list
  List<Director> get _directorsToExport {
    return widget.directors
        .where((d) => _selectedDirectors[d.id] == true)
        .toList();
  }
  
  // Get selected count
  int get _selectedCount {
    return _selectedDirectors.values.where((v) => v).length;
  }
  
  // Check if all selected
  bool get _allSelected {
    return _selectedCount == widget.directors.length;
  }
  
  // Toggle all selection
  void _toggleSelectAll() {
    setState(() {
      final newValue = !_allSelected;
      for (var director in widget.directors) {
        _selectedDirectors[director.id] = newValue;
      }
    });
  }
  
  // Filter directors by search
  List<Director> get _filteredDirectors {
    if (_searchQuery.isEmpty) return widget.directors;
    return widget.directors.where((d) {
      return d.name.contains(_searchQuery) ||
             d.din.contains(_searchQuery) ||
             d.email.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.file_download_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizationService.tr('export_directors'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showDirectorSelection = !_showDirectorSelection),
                            child: Row(
                              children: [
                                  Text(
                                    localizationService.tr('directors_selected', args: {
                                      'count': _selectedCount.toString(),
                                      'total': widget.directors.length.toString(),
                                    }),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _selectedCount == 0 
                                          ? const Color(0xFFEF4444) 
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showDirectorSelection 
                                      ? Icons.keyboard_arrow_up_rounded 
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: const Color(0xFF6366F1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: const Color(0xFFF1F5F9), height: 1),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Director Selection Section (Collapsible)
                      _buildDirectorSelectionSection(),
                      
                       // Export Format Section
                      _buildSectionHeader(localizationService.tr('export_format'), Icons.description_outlined, iconColor: const Color(0xFF6366F1)),
                      const SizedBox(height: 16),
                      _buildFormatGrid(),
                      
                      const SizedBox(height: 28),
                      
                       // Document Settings
                      _buildSectionHeader(localizationService.tr('document_settings'), Icons.edit_document, iconColor: const Color(0xFF10B981)),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _reportTitleController,
                        label: localizationService.tr('report_title'),
                        hint: localizationService.tr('enter_report_title'),
                        icon: Icons.text_fields_rounded,
                        iconColor: const Color(0xFF6366F1),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _companyNameController,
                        label: localizationService.tr('company_name_optional'),
                        hint: localizationService.tr('enter_company_name'),
                        icon: Icons.business_rounded,
                        iconColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _fileNameController,
                        label: localizationService.tr('file_name'),
                        hint: localizationService.tr('enter_file_name'),
                        icon: Icons.insert_drive_file_rounded,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                      
                      const SizedBox(height: 28),
                      
                       // Options
                      _buildSectionHeader(localizationService.tr('options'), Icons.tune_rounded, iconColor: const Color(0xFF8B5CF6)),
                      const SizedBox(height: 16),
                       _buildOptionTile(
                        localizationService.tr('include_header'),
                        localizationService.tr('add_title_metadata'),
                        _options.includeHeader,
                        (v) => setState(() => _options.includeHeader = v),
                      ),
                       _buildOptionTile(
                        localizationService.tr('include_timestamp'),
                        localizationService.tr('add_generation_date'),
                        _options.includeTimestamp,
                        (v) => setState(() => _options.includeTimestamp = v),
                      ),
                       _buildOptionTile(
                        localizationService.tr('include_summary'),
                        localizationService.tr('add_stats_end'),
                        _options.includeSummary,
                        (v) => setState(() => _options.includeSummary = v),
                      ),
                      
                      const SizedBox(height: 20),
                      
                       // Aadhaar Masking Section
                      _buildSectionHeader(localizationService.tr('privacy'), Icons.security_rounded, iconColor: const Color(0xFFEF4444)),
                      const SizedBox(height: 16),
                      _buildAadhaarMaskingOption(),
                      
                      const SizedBox(height: 28),
                      
                       // Field Selection
                      _buildSectionHeader(localizationService.tr('select_fields'), Icons.checklist_rtl_rounded, iconColor: const Color(0xFFEF4444)),
                      const SizedBox(height: 8),
                       Text(
                        localizationService.tr('choose_fields_export'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldSelectionGrid(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Export Button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildExportButton(),
          ),
        ],
      ),
    ),
    );
  }
  
  Widget _buildExportButton() {
    final canExport = _selectedCount > 0;
    return GestureDetector(
      onTap: _isExporting || !canExport ? null : _performExport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isExporting || !canExport
            ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)])
            : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isExporting || !canExport
                ? Colors.grey.withOpacity(0.3) 
                : const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isExporting) ...[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 12),
               Text(
                localizationService.tr('exporting'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ] else ...[
              const Icon(Icons.file_download_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
               Text(
                canExport 
                    ? localizationService.tr('export_count_directors', args: {'count': _selectedCount.toString()}) 
                    : localizationService.tr('select_directors_to_export'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorSelectionSection() {
    if (!_showDirectorSelection) {
      return Column(
        children: [
          _buildSectionHeader(localizationService.tr('select_directors'), Icons.people_alt_rounded, iconColor: const Color(0xFF10B981)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _showDirectorSelection = true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedCount == widget.directors.length 
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _selectedCount == widget.directors.length 
                          ? Icons.check_circle_rounded 
                          : Icons.filter_list_rounded,
                      color: _selectedCount == widget.directors.length 
                          ? const Color(0xFF10B981) 
                          : const Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          _selectedCount == widget.directors.length 
                              ? localizationService.tr('all_directors_selected')
                              : localizationService.tr('directors_selected', args: {
                                  'count': _selectedCount.toString(),
                                  'total': widget.directors.length.toString(),
                                }),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          localizationService.tr('tap_choose_specific'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      );
    }
    
    // Expanded Selection Panel
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizationService.tr('select_directors'), Icons.people_alt_rounded, iconColor: const Color(0xFF10B981)),
        const SizedBox(height: 12),
        
        // Search and Select All Row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(fontSize: 14),
                   decoration: InputDecoration(
                    hintText: localizationService.tr('search_directors'),
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleSelectAll,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _allSelected 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _allSelected 
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: _allSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                     Text(
                      localizationService.tr('all'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _allSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Director List
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredDirectors.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: const Color(0xFFE2E8F0)),
              itemBuilder: (context, index) {
                final director = _filteredDirectors[index];
                final isSelected = _selectedDirectors[director.id] == true;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDirectors[director.id] = !isSelected;
                    });
                  },
                  child: Container(
                    color: isSelected 
                        ? const Color(0xFF10B981).withOpacity(0.05) 
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected 
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                director.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (director.din.isNotEmpty || director.email.isNotEmpty)
                                Text(
                                  director.din.isNotEmpty ? 'DIN: ${director.din}' : director.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                             child: Text(
                              localizationService.tr('selected'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Collapse Button
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _showDirectorSelection = false),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: const Color(0xFF6366F1)),
              const SizedBox(width: 4),
               Text(
                localizationService.tr('hide_selection'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildAadhaarMaskingOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.visibility_off_rounded, size: 18, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 12),
               Expanded(
                child: Text(
                  localizationService.tr('aadhaar_privacy'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
               Expanded(
                child: _buildMaskChoice(
                  label: localizationService.tr('unmasked'),
                  subtitle: localizationService.tr('show_full_number'),
                  isSelected: !_options.maskAadhaar,
                  onTap: () => setState(() => _options.maskAadhaar = false),
                  icon: Icons.visibility_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMaskChoice(
                  label: localizationService.tr('masked'),
                  subtitle: localizationService.tr('hide_digits'),
                  isSelected: _options.maskAadhaar,
                  onTap: () => setState(() => _options.maskAadhaar = true),
                  icon: Icons.vpn_key_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaskChoice({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final color = isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? iconColor}) {
    final color = iconColor ?? const Color(0xFF6366F1);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatGrid() {
    final formats = [
      {'format': ExportFormat.pdf, 'icon': Icons.picture_as_pdf_rounded, 'label': 'PDF', 'color': const Color(0xFFEF4444)},
      {'format': ExportFormat.csv, 'icon': Icons.table_chart_rounded, 'label': 'CSV', 'color': const Color(0xFF10B981)},
      {'format': ExportFormat.json, 'icon': Icons.data_object_rounded, 'label': 'JSON', 'color': const Color(0xFFF59E0B)},
      {'format': ExportFormat.clipboard, 'icon': Icons.content_copy_rounded, 'label': 'Copy', 'color': const Color(0xFF6366F1)},
    ];

    return Row(
      children: formats.map((f) {
        final isSelected = _selectedFormat == f['format'];
        final color = f['color'] as Color;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedFormat = f['format'] as ExportFormat),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(f['icon'] as IconData, color: isSelected ? color : const Color(0xFF94A3B8), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color? iconColor,
  }) {
    final color = iconColor ?? const Color(0xFF6366F1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSelectionGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.fields.map((field) {
        return FilterChip(
          label: Text(field.label),
          selected: field.isSelected,
          onSelected: (selected) {
            setState(() => field.isSelected = selected);
          },
          selectedColor: const Color(0xFF6366F1).withOpacity(0.15),
          checkmarkColor: const Color(0xFF6366F1),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: field.isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
          ),
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: field.isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _performExport() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Please select at least one director to export'),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    setState(() => _isExporting = true);
    
    final directorsToExport = _directorsToExport;
    
    try {
      _options.format = _selectedFormat;
      _options.fileName = _fileNameController.text;
      _options.companyName = _companyNameController.text;
      _options.reportTitle = _reportTitleController.text;
      
      String message = '';
      
      switch (_selectedFormat) {
        case ExportFormat.pdf:
          final pdfBytes = await DirectorExportService.exportToPdf(directorsToExport, _options);
          if (mounted) {
            Navigator.pop(context); // Close export sheet first
            showPdfPreview(
              context, 
              pdfBytes, 
              _options.reportTitle,
              subtitle: '${directorsToExport.length} directors',
            );
          }
          return; // Early return since we're navigating
          
        case ExportFormat.csv:
          final path = await DirectorExportService.exportToCsv(directorsToExport, _options);
          await DirectorExportService.shareFile(path, _options.reportTitle);
          message = 'CSV file exported successfully (${directorsToExport.length} directors)';
          break;
          
        case ExportFormat.json:
          final path = await DirectorExportService.exportToJson(directorsToExport, _options);
          await DirectorExportService.shareFile(path, _options.reportTitle);
          message = 'JSON file exported successfully (${directorsToExport.length} directors)';
          break;
          
        case ExportFormat.clipboard:
        case ExportFormat.whatsapp:
          await DirectorExportService.copyToClipboard(directorsToExport, _options);
          message = 'Copied ${directorsToExport.length} directors to clipboard!';
          break;
          
        default:
          message = 'Export completed';
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

// Show Export Screen Helper - Full Page
void showAdvancedExportSheet(BuildContext context, List<Director> directors, {String filterName = 'All Directors'}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AdvancedExportSheet(directors: directors, filterName: filterName),
    ),
  );
}

