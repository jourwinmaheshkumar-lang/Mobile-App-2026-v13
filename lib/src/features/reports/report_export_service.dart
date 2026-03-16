import 'package:flutter/services.dart';
import '../../core/models/report.dart';
import '../../core/models/director.dart';
import '../../core/utils/text_utils.dart';

class ReportExportService {
  
  // Generate formatted text for WhatsApp
  static String _generateFormattedText(
    Report report,
    List<Director> allDirectors,
    List<Director> unassigned,
  ) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('🏢 *${report.title.toUpperCase()}*');
    buffer.writeln('📅 Date:  ${_formatDate(report.updatedAt)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    
    // Categories
    for (var category in report.categories) {
      final directors = allDirectors.where((d) => category.directorIds.contains(d.id)).toList();
      
      // Sort directors A to Z (Name)
      directors.sort((a, b) => a.name.compareTo(b.name));
      
      buffer.writeln('*${category.name}* (${directors.length})');
      
      if (directors.isNotEmpty) {
        for (int i = 0; i < directors.length; i++) {
          final d = directors[i];
          buffer.writeln('${i + 1}. ${textUtils.format(d.name)}');
        }
      }
      buffer.writeln('');
    }
    
    // Not Answered
    if (unassigned.isNotEmpty) {
      // Sort unassigned A to Z
      final sortedUnassigned = List<Director>.from(unassigned);
      sortedUnassigned.sort((a, b) => a.name.compareTo(b.name));
      
      buffer.writeln('⚠️ *Not Answered* (${sortedUnassigned.length})');
      for (int i = 0; i < sortedUnassigned.length; i++) {
        buffer.writeln('${i + 1}. ${textUtils.format(sortedUnassigned[i].name)}');
      }
      buffer.writeln('');
    }
    
    // Summary
    buffer.writeln('');
    buffer.writeln('📋 *SUMMARY*');
    buffer.writeln('✅ Assigned: ${allDirectors.length - unassigned.length}');
    buffer.writeln('⚠️ Not Answered: ${unassigned.length}');
    buffer.writeln('📊 *Total: ${allDirectors.length}*');
    
    return buffer.toString();
  }

  // Share to WhatsApp (copies to clipboard)
  static Future<void> shareToWhatsApp(
    Report report,
    List<Director> allDirectors,
    List<Director> unassigned,
  ) async {
    final text = _generateFormattedText(report, allDirectors, unassigned);
    await Clipboard.setData(ClipboardData(text: text));
  }

  // Export to PDF (placeholder - generates text for now)
  static Future<void> exportToPdf(
    Report report,
    List<Director> allDirectors,
    List<Director> unassigned,
  ) async {
    // For now, we'll copy the text to clipboard as a placeholder
    // In a real implementation, you would use a PDF library like pdf/printing
    final text = _generatePdfText(report, allDirectors, unassigned);
    await Clipboard.setData(ClipboardData(text: text));
  }

  static String _generatePdfText(
    Report report,
    List<Director> allDirectors,
    List<Director> unassigned,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('REPORT: ${report.title}');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    buffer.writeln('Date: ${_formatDate(report.updatedAt)}');
    buffer.writeln('Mode: ${report.selectionMode == SelectionMode.single ? "Single Selection" : "Multi Selection"}');
    buffer.writeln('');
    buffer.writeln('-' * 50);
    
    for (var category in report.categories) {
      final directors = allDirectors.where((d) => category.directorIds.contains(d.id)).toList();
      
      buffer.writeln('');
      buffer.writeln('${category.name} (${directors.length} directors)');
      buffer.writeln('-' * 30);
      
      if (directors.isEmpty) {
        buffer.writeln('  No directors assigned');
      } else {
        for (int i = 0; i < directors.length; i++) {
          final d = directors[i];
          buffer.writeln('  ${i + 1}. ${textUtils.format(d.name)} ${d.din.isNotEmpty ? "(DIN: ${d.din})" : ""}');
        }
      }
    }
    
    if (unassigned.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('NOT ANSWERED (${unassigned.length} directors)');
      buffer.writeln('-' * 30);
      for (int i = 0; i < unassigned.length; i++) {
        buffer.writeln('  ${i + 1}. ${textUtils.format(unassigned[i].name)}');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('SUMMARY');
    buffer.writeln('  Total Categories: ${report.categories.length}');
    buffer.writeln('  Assigned: ${allDirectors.length - unassigned.length}');
    buffer.writeln('  Not Answered: ${unassigned.length}');
    buffer.writeln('  Total Directors: ${allDirectors.length}');
    
    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
