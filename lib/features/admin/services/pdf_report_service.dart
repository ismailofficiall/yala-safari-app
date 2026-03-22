import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service to generate and export professional A4 landscape/portrait PDF reports.
/// This demonstrates advanced reporting capabilities for an administrative dashboard.
class PdfReportService {
  /// Compiles system data into an Executive Summary PDF and triggers a system print/save dialog.
  static Future<void> generateWeeklyReport({
    required List<Map<String, dynamic>> incidents,
    required List<Map<String, dynamic>> drivers,
  }) async {
    final pdf = pw.Document();

    // Sort drivers by rating to get top performers
    final sortedDrivers = List<Map<String, dynamic>>.from(drivers)..sort((a, b) {
      final rA = (a['rating'] is num) ? (a['rating'] as num).toDouble() : 5.0;
      final rB = (b['rating'] is num) ? (b['rating'] as num).toDouble() : 5.0;
      return rB.compareTo(rA);
    });

    final activeDrivers = drivers.where((d) => d['status'] == 'Active').length;
    final openIncidents = incidents.where((i) => i['is_resolved'] == false).length;

    // Build the PDF page definition
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Report Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Yala National Park", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    pw.SizedBox(height: 4),
                    pw.Text("Fleet Operations & Incident Report", style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  "Generated on:\n${DateTime.now().toLocal().toString().substring(0, 16)}",
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),

            // Executive Summary
            pw.Header(level: 1, text: "1. Executive Summary", textStyle: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBox("Total Drivers", "${drivers.length}"),
                _buildSummaryBox("Active Shift", "$activeDrivers"),
                _buildSummaryBox("Total Incidents", "${incidents.length}"),
                _buildSummaryBox("Open Issues", "$openIncidents"),
              ],
            ),
            pw.SizedBox(height: 30),

            // Top Drivers Table
            pw.Header(level: 1, text: "2. Top Performing Drivers (Top 10)", textStyle: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Rank', 'Driver Name', 'Jeep ID', 'Rating', 'Status'],
              data: sortedDrivers.take(10).toList().asMap().entries.map((e) {
                final d = e.value;
                final r = (d['rating'] is num) ? (d['rating'] as num).toDouble() : 5.0;
                return [
                  (e.key + 1).toString(),
                  d['driver_name'].toString(),
                  d['jeep_id'].toString(),
                  r.toStringAsFixed(1),
                  d['status'].toString(),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 30),

            // Recent Incidents Table
            pw.Header(level: 1, text: "3. Recent Operational Incidents", textStyle: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Date', 'Type', 'Coordinates', 'Resolved'],
              data: incidents.take(20).map((i) {
                final date = (i['created_at']?.toString() ?? 'N/A').length > 10 ? i['created_at'].toString().substring(0, 10) : 'N/A';
                final lat = (i['latitude'] as num?)?.toStringAsFixed(4) ?? '?';
                final lng = (i['longitude'] as num?)?.toStringAsFixed(4) ?? '?';
                return [
                  date,
                  i['type']?.toString() ?? 'Other',
                  "$lat, $lng",
                  i['is_resolved'] == true ? 'Yes' : 'No',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Prompt user to save/print the PDF using system dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Yala_Driver_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Helper widget for the PDF to draw a statistic box
  static pw.Widget _buildSummaryBox(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        ],
      ),
    );
  }
}
