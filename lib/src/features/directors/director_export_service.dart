import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/director.dart';
import '../../core/utils/text_utils.dart';
import '../../core/services/localization_service.dart';

// Export Format Options
enum ExportFormat { pdf, excel, csv, json, whatsapp, clipboard }

// Export Field Configuration
class ExportField {
  final String id;
  final String label;
  final String Function(Director) getValue;
  bool isSelected;

  ExportField({
    required this.id,
    required this.label,
    required this.getValue,
    this.isSelected = true,
  });
}

// Export Options Configuration
class ExportOptions {
  ExportFormat format;
  String fileName;
  bool includeHeader;
  bool includeTimestamp;
  bool includeSummary;
  bool maskAadhaar; // true = masked (XXXX-XXXX-1234), false = unmasked (full number)
  String companyName;
  String reportTitle;
  List<ExportField> fields;
  String sortBy;
  bool sortAscending;

  ExportOptions({
    this.format = ExportFormat.pdf,
    this.fileName = 'directors_export',
    this.includeHeader = true,
    this.includeTimestamp = true,
    this.includeSummary = true,
    this.maskAadhaar = false, // Default: Unmasked
    this.companyName = '',
    this.reportTitle = 'Directors Report',
    required this.fields,
    this.sortBy = 'name',
    this.sortAscending = true,
  });
}

// Advanced Export Service
class DirectorExportService {
  // Get all available export fields
  static List<ExportField> getAvailableFields() {
    return [
      ExportField(id: 'serialNo', label: localizationService.tr('s_no'), getValue: (d) => d.serialNo.toString()),
      ExportField(id: 'name', label: localizationService.tr('full_name'), getValue: (d) => textUtils.format(d.name)),
      ExportField(id: 'din', label: localizationService.tr('din_number'), getValue: (d) => d.din.isNotEmpty ? d.din : 'N/A'),
      ExportField(
        id: 'companies', 
        label: 'Associated Companies', 
        getValue: (d) => d.companies.map((c) => '${c.companyName} (${c.designation})').join(', '),
        isSelected: false
      ),
      ExportField(id: 'email', label: localizationService.tr('email_id'), getValue: (d) => d.email.isNotEmpty ? d.email : 'N/A'),
      ExportField(id: 'status', label: localizationService.tr('status'), getValue: (d) => d.status),
      ExportField(id: 'pan', label: localizationService.tr('pan'), getValue: (d) => d.pan.isNotEmpty ? d.pan : 'N/A'),
      ExportField(id: 'aadhaarNumber', label: localizationService.tr('aadhaar_number'), getValue: (d) => d.aadhaarNumber.isNotEmpty ? d.aadhaarNumber : 'N/A'),
      ExportField(id: 'aadhaarAddress', label: localizationService.tr('aadhaar_address'), getValue: (d) => d.aadhaarAddress.isNotEmpty ? d.aadhaarAddress : 'N/A', isSelected: false),
      ExportField(id: 'residentialAddress', label: localizationService.tr('residential_address'), getValue: (d) => d.residentialAddress.isNotEmpty ? d.residentialAddress : 'N/A', isSelected: false),
      ExportField(id: 'idbiAccount', label: localizationService.tr('idbi_account'), getValue: (d) => d.idbiAccountDetails.isNotEmpty ? d.idbiAccountDetails : 'N/A', isSelected: false),
      ExportField(id: 'emudhraAccount', label: localizationService.tr('emudhra_account'), getValue: (d) => d.emudhraAccountDetails.isNotEmpty ? d.emudhraAccountDetails : 'N/A', isSelected: false),
      ExportField(id: 'bankPhone', label: localizationService.tr('bank_phone'), getValue: (d) => d.bankLinkedPhone.isNotEmpty ? d.bankLinkedPhone : 'N/A', isSelected: false),
      ExportField(id: 'aadhaarPhone', label: localizationService.tr('aadhaar_phone'), getValue: (d) => d.aadhaarPanLinkedPhone.isNotEmpty ? d.aadhaarPanLinkedPhone : 'N/A', isSelected: false),
      ExportField(id: 'emailPhone', label: localizationService.tr('email_phone'), getValue: (d) => d.emailLinkedPhone.isNotEmpty ? d.emailLinkedPhone : 'N/A', isSelected: false),
      ExportField(id: 'addressMismatch', label: localizationService.tr('address_mismatch'), getValue: (d) => d.hasAddressMismatch ? localizationService.tr('yes') : localizationService.tr('no'), isSelected: false),
      ExportField(id: 'hasDin', label: localizationService.tr('has_valid_din'), getValue: (d) => d.hasNoDin ? localizationService.tr('no') : localizationService.tr('yes'), isSelected: false),
    ];
  }

  // Mask Aadhaar number (show only last 4 digits)
  static String _maskAadhaar(String aadhaar) {
    if (aadhaar.isEmpty || aadhaar.length < 4) return 'N/A';
    return 'XXXX-XXXX-${aadhaar.substring(aadhaar.length - 4)}';
  }
  
  // Format Aadhaar based on mask option
  static String _formatAadhaar(String aadhaar, bool shouldMask) {
    if (aadhaar.isEmpty) return 'N/A';
    if (shouldMask) {
      return _maskAadhaar(aadhaar);
    }
    // Unmasked - return full number, optionally formatted
    if (aadhaar.length == 12) {
      return '${aadhaar.substring(0, 4)}-${aadhaar.substring(4, 8)}-${aadhaar.substring(8)}';
    }
    return aadhaar;
  }
  
  // Get field value with Aadhaar masking applied
  static String _getFieldValue(ExportField field, Director director, bool maskAadhaar) {
    if (field.id == 'aadhaarNumber') {
      return _formatAadhaar(director.aadhaarNumber, maskAadhaar);
    }
    return field.getValue(director);
  }

  // Export to CSV
  static Future<String> exportToCsv(List<Director> directors, ExportOptions options) async {
    final selectedFields = options.fields.where((f) => f.isSelected).toList();
    
    List<List<dynamic>> rows = [];
    
    // Add header if enabled
    if (options.includeHeader) {
      if (options.companyName.isNotEmpty) {
        rows.add([options.companyName]);
      }
      rows.add([options.reportTitle]);
      if (options.includeTimestamp) {
        rows.add(['${localizationService.tr('generated_at')}: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}']);
      }
      rows.add([]);
    }
    
    // Add column headers
    rows.add(selectedFields.map((f) => f.label).toList());
    
    // Add data rows with Aadhaar masking applied
    for (var director in directors) {
      rows.add(selectedFields.map((f) => _getFieldValue(f, director, options.maskAadhaar)).toList());
    }
    
    // Add summary if enabled
    if (options.includeSummary) {
      rows.add([]);
      rows.add(['--- ${localizationService.tr('summary_section')} ---']);
      rows.add([localizationService.tr('total_directors'), directors.length.toString()]);
      rows.add([localizationService.tr('active'), directors.where((d) => d.status.toLowerCase() == 'active').length.toString()]);
      rows.add([localizationService.tr('no_din'), directors.where((d) => d.hasNoDin).length.toString()]);
      rows.add([localizationService.tr('address_mismatch'), directors.where((d) => d.hasAddressMismatch).length.toString()]);
    }
    
    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/${options.fileName}_$timestamp.csv');
    await file.writeAsString(csv);
    
    return file.path;
  }

  // Export to JSON
  static Future<String> exportToJson(List<Director> directors, ExportOptions options) async {
    final selectedFields = options.fields.where((f) => f.isSelected).toList();
    
    final data = {
      'metadata': {
        'title': options.reportTitle,
        'company': options.companyName,
        'generatedAt': DateTime.now().toIso8601String(),
        'totalRecords': directors.length,
      },
      'directors': directors.map((d) {
        final Map<String, dynamic> record = {};
        for (var field in selectedFields) {
          record[field.id] = _getFieldValue(field, d, options.maskAadhaar);
        }
        return record;
      }).toList(),
      if (options.includeSummary) 'summary': {
        'total': directors.length,
        'active': directors.where((d) => d.status.toLowerCase() == 'active').length,
        'withoutDin': directors.where((d) => d.hasNoDin).length,
        'addressMismatch': directors.where((d) => d.hasAddressMismatch).length,
      },
    };
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/${options.fileName}_$timestamp.json');
    await file.writeAsString(jsonString);
    
    return file.path;
  }

  // Export to PDF
  static Future<Uint8List> exportToPdf(List<Director> directors, ExportOptions options) async {
    final selectedFields = options.fields.where((f) => f.isSelected).toList();
    final pdf = pw.Document();
    
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    
    // Create pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (options.companyName.isNotEmpty)
              pw.Text(
                options.companyName,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              options.reportTitle,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (options.includeTimestamp)
              pw.Text(
                '${localizationService.tr('generated_at')}: ${dateFormat.format(now)}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
        build: (context) {
          final List<pw.Widget> widgets = [];
          
          // Build table
          widgets.add(
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: PdfColors.indigo100),
              headerHeight: 28,
              cellHeight: 24,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headers: selectedFields.map((f) => f.label).toList(),
              data: directors.map((d) => selectedFields.map((f) => _getFieldValue(f, d, options.maskAadhaar)).toList()).toList(),
            ),
          );
          
          // Add summary
          if (options.includeSummary) {
            widgets.add(pw.SizedBox(height: 24));
            widgets.add(pw.Divider(color: PdfColors.grey300));
            widgets.add(pw.SizedBox(height: 12));
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryCard(localizationService.tr('total_directors'), directors.length.toString(), PdfColors.indigo),
                  _buildPdfSummaryCard(localizationService.tr('active'), directors.where((d) => d.status.toLowerCase() == 'active').length.toString(), PdfColors.green),
                  _buildPdfSummaryCard(localizationService.tr('no_din'), directors.where((d) => d.hasNoDin).length.toString(), PdfColors.orange),
                  _buildPdfSummaryCard(localizationService.tr('address_mismatch'), directors.where((d) => d.hasAddressMismatch).length.toString(), PdfColors.red),
                ],
              ),
            );
          }
          
          return widgets;
        },
      ),
    );
    
    return pdf.save();
  }

  static pw.Widget _buildPdfSummaryCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.9),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // Copy to Clipboard (WhatsApp Format)
  static Future<void> copyToClipboard(List<Director> directors, ExportOptions options) async {
    final selectedFields = options.fields.where((f) => f.isSelected).toList();
    final buffer = StringBuffer();
    
    // Sort directors A to Z (Name) - respecting the "Align order A to Z" request
    final sortedDirectors = List<Director>.from(directors);
    sortedDirectors.sort((a, b) => a.name.compareTo(b.name));
    
    // Header
    buffer.writeln('🏢 *${options.reportTitle.toUpperCase()}*');
    if (options.companyName.isNotEmpty) {
      buffer.writeln('🏢 ${options.companyName}');
    }
    if (options.includeTimestamp) {
      buffer.writeln('📅 ${localizationService.tr('generated_at')}:  ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    
    // Directors List
    for (int i = 0; i < sortedDirectors.length; i++) {
      final d = sortedDirectors[i];
      final index = (i + 1).toString().padLeft(2, '0');
      buffer.writeln('*$index. ${textUtils.format(d.name)}*');
      
      for (var field in selectedFields) {
        if (field.id != 'name' && field.id != 'serialNo') {
          // Align labels with spaces for better vertical alignment
          final label = '${field.label}:'.padRight(15);
          buffer.writeln('   ▫️ $label ${_getFieldValue(field, d, options.maskAadhaar)}');
        }
      }
      buffer.writeln('');
    }
    
    // Summary
    if (options.includeSummary) {
      buffer.writeln('');
      buffer.writeln(' *${localizationService.tr('summary_section').toUpperCase()}*');
      buffer.writeln('✅ ${localizationService.tr('active')}: ${sortedDirectors.where((d) => d.status.toLowerCase() == 'active').length}');
      buffer.writeln('🚫 ${localizationService.tr('no_din')}: ${sortedDirectors.where((d) => d.hasNoDin).length}');
      buffer.writeln('📍 ${localizationService.tr('address_mismatch')}: ${sortedDirectors.where((d) => d.hasAddressMismatch).length}');
      buffer.writeln(' *${localizationService.tr('total')}: ${sortedDirectors.length}*');
    }
    
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  // Share File
  static Future<void> shareFile(String filePath, String subject) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
    );
  }

  // Print PDF
  static Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }
}

// JSON Encoder extension
class JsonEncoder {
  final String? indent;
  const JsonEncoder.withIndent(this.indent);
  
  String convert(dynamic data) {
    return _encode(data, 0);
  }
  
  String _encode(dynamic data, int depth) {
    if (data == null) return 'null';
    if (data is bool || data is num) return data.toString();
    if (data is String) return '"${data.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
    
    if (data is List) {
      if (data.isEmpty) return '[]';
      final items = data.map((e) => '${indent! * (depth + 1)}${_encode(e, depth + 1)}').join(',\n');
      return '[\n$items\n${indent! * depth}]';
    }
    
    if (data is Map) {
      if (data.isEmpty) return '{}';
      final entries = data.entries.map((e) => '${indent! * (depth + 1)}"${e.key}": ${_encode(e.value, depth + 1)}').join(',\n');
      return '{\n$entries\n${indent! * depth}}';
    }
    
    return data.toString();
  }
}
