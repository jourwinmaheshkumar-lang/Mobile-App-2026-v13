import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/form_field.dart';
import '../models/form_model.dart';
import '../models/form_submission.dart';

class FormExportService {
  static Future<void> exportToCsv(FormModel form, List<FormSubmissionModel> submissions) async {
    List<List<dynamic>> rows = [];

    // Header Row
    List<dynamic> header = ['User', 'Submitted At'];
    for (var field in form.fields) {
      header.add(field.label);
    }
    rows.add(header);

    // Data Rows
    for (var sub in submissions) {
      List<dynamic> row = [
        sub.userName ?? sub.userId,
        DateFormat('yyyy-MM-dd HH:mm').format(sub.submittedAt),
      ];
      for (var field in form.fields) {
        var resp = sub.responses[field.id];
        if (resp is List) {
          row.add(resp.join(', '));
        } else if (field.type == FormFieldType.currency && resp != null) {
          row.add('₹ ${resp.toString()}');
        } else {
          row.add(resp?.toString() ?? '');
        }
      }
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/${form.title.replaceAll(' ', '_')}_reports.csv";
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Form Reports for ${form.title}');
  }

  static Future<void> exportToPdf(FormModel form, List<FormSubmissionModel> submissions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(form.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Detailed Report - Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Divider(),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Submissions: ${submissions.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          ...submissions.map((sub) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('User: ${sub.userName ?? sub.userId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(sub.submittedAt),
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey200),
                  pw.SizedBox(height: 8),
                  ...form.fields.map((field) {
                    var resp = sub.responses[field.id];
                    String respStr = '';
                    if (resp is List) {
                      respStr = resp.join(', ');
                    } else if (field.type == FormFieldType.currency && resp != null) {
                      respStr = '₹ ${resp.toString()}';
                    } else {
                      respStr = resp?.toString() ?? 'N/A';
                    }
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(text: '${field.label}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.TextSpan(text: respStr, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
