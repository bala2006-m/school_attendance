import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> generatePdf({
  required Map<String, dynamic> fee,
  List<dynamic>? studentFees, // List of fee records for all payments
  String? schoolName,
  String? schoolAddress,
  Uint8List? schoolPhotoBytes,
  required Map<String, dynamic> studentDetails,
  String? receiptNo,
  String? paidDate,
}) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  final title = fee['title']?.toString() ?? 'Title not available';
  final totalAmount = (fee['total_amount'] ?? 0).toDouble();
  final descriptions = (fee['descriptions'] ?? []) as List;
  final amounts = (fee['amounts'] ?? []) as List;

  // Collect all payments from all student fee records
  final payments = <Map<String, dynamic>>[];
  if (studentFees != null) {
    for (var feeRecord in studentFees) {
      if (feeRecord['payments'] != null) {
        for (var p in feeRecord['payments']) {
          payments.add(Map<String, dynamic>.from(p));
        }
      }
    }
  }

  final totalPaid = payments.fold<double>(
    0,
    (sum, p) => sum + (p['amount']?.toDouble() ?? 0),
  );
  final balance = totalAmount - totalPaid;

  final now = DateTime.now();
  final admin =
      fee['admin'] ??
      (studentFees != null && studentFees.isNotEmpty
          ? studentFees[0]['admin']
          : null);
  final collectedByName = admin != null ? (admin['name'] ?? '-') : '-';
  final startYear = now.month >= 4 ? now.year : now.year - 1;
  final endYear = startYear + 1;
  final academicYear = '$startYear-$endYear';

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      margin: const pw.EdgeInsets.all(24),
      build:
          (pw.Context context) => [
            // Header with school logo and name
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (schoolPhotoBytes != null)
                  pw.Container(
                    width: 55,
                    height: 55,
                    child: pw.Image(
                      pw.MemoryImage(schoolPhotoBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  )
                else
                  pw.SizedBox(width: 55, height: 55),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        schoolName ?? '',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (schoolAddress != null && schoolAddress.isNotEmpty)
                        pw.Text(
                          schoolAddress,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(height: 2, color: PdfColors.grey700),
            pw.SizedBox(height: 24),

            // Receipt title
            pw.Center(
              child: pw.Text(
                'Receipt',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 16),

            // Receipt details
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (receiptNo != null)
                      pw.Text(
                        'Receipt No: $receiptNo',
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    pw.Text(
                      'Date: ${paidDate ?? now.toString().split(' ')[0]}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Academic Year: $academicYear',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Student info box
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
                color: PdfColors.blue50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Received From: ${studentDetails['name'] ?? '-'}',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Payment For: $title',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Fee table
            pw.Text(
              'Fee Details',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text(
                        'Description',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text(
                        'Amount (₹)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                ...List.generate(descriptions.length, (i) {
                  final desc = descriptions[i].toString();
                  final amt =
                      (i < amounts.length) ? amounts[i].toString() : '-';
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text(desc, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text(
                          '₹$amt',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  );
                }),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text(
                        '₹$totalAmount',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Payments table
            if (payments.isNotEmpty) ...[
              pw.Text(
                'Payments Made',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Amount (₹)',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Method',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...payments.map((p) {
                    final date =
                        p['payment_date']?.toString().split('T')[0] ?? '-';
                    final amt = (p['amount'] ?? 0).toString();
                    final method =
                        (p['method'] ?? '-').toString().toUpperCase();
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            date,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '₹$amt',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            method,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Total Paid',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '₹$totalPaid',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('-', style: pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Remaining Balance',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '₹$balance',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('-', style: pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
            ],

            // Collected By
            pw.Text(
              'Collected By: $collectedByName',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 18),

            // Footer
            pw.Center(
              child: pw.Text(
                'Thank you for your payment.',
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
    ),
  );

  return pdf;
}
