import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> generateBusFeeReceiptPdf({
  required List<dynamic> paidBusFees,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
  required Map<String, dynamic> studentData,
  required String username,
}) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();
  final dateFormat = DateFormat('dd MMM yyyy');

  final logo =
      schoolPhotoBytes != null ? pw.MemoryImage(schoolPhotoBytes) : null;

  // Collect all payments
  final payments = <Map<String, dynamic>>[];
  for (var fee in paidBusFees) {
    final List<dynamic> feePayments = fee['busFeePayment'] ?? [];
    for (var p in feePayments) {
      payments.add({
        'student_id': p['student_id']?.toString() ?? '-',
        'term': fee['term'] ?? '-',
        'route': fee['route'] ?? '-',
        'total_amount': (fee['total_amount'] ?? 0),
        'amount_paid': (p['amount_paid'] ?? 0),
        'payment_mode': p['payment_mode'] ?? '-',
        'payment_date': p['payment_date'],
      });
    }
  }

  // Total Paid
  final totalPaid = payments.fold<double>(
    0,
    (sum, e) => sum + (e['amount_paid'] as num).toDouble(),
  );

  // Total Amount
  final totalAmount = paidBusFees.fold<double>(
    0.0,
    (sum, f) => sum + ((f['total_amount'] ?? 0) as num).toDouble(),
  );

  // Remaining balance
  final remainingBalance = totalAmount - totalPaid;

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      margin: const pw.EdgeInsets.all(24),
      build:
          (context) => [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 55,
                    height: 55,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
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
                          fontSize: 16,
                          color: PdfColors.blue800,
                        ),
                      ),
                      if (schoolAddress != null && schoolAddress.isNotEmpty)
                        pw.Text(
                          schoolAddress,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.blue700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Title
            pw.Center(
              child: pw.Text(
                'Bus Fee Receipt',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Student Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Received From: ${studentData['name'] ?? '-'}',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Admission No: $username',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Class: ${studentData['class'] != null ? '${studentData['class']['class']} - ${studentData['class']['section']}' : '-'}',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Route: ${studentData['route'] ?? '-'}',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Date: ${dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Fee Table
            pw.Text(
              'Fee Details',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue),
                  children:
                      ['Term', 'Route', 'Total Amount (₹)', 'Status']
                          .map(
                            (header) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                header,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                  color: PdfColors.white,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                ),
                ...paidBusFees.map((fee) {
                  final paymentsList = fee['busFeePayment'] as List? ?? [];
                  final paidSum = paymentsList.fold<double>(
                    0,
                    (sum, p) => sum + (p['amount_paid']?.toDouble() ?? 0),
                  );

                  final status =
                      (paidSum >= (fee['total_amount']?.toDouble() ?? 0))
                          ? 'Paid'
                          : 'Partially Paid';

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          fee['term'] ?? '-',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          fee['route'] ?? '-',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          (fee['total_amount'] ?? 0).toStringAsFixed(2),
                          style: pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          status,
                          style: pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Payments Made Table
            if (payments.isNotEmpty) ...[
              pw.Text(
                'Payments Made',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
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
                    children:
                        ['Date', 'Amount (₹)', 'Mode']
                            .map(
                              (header) => pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  header,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  ...payments.map((p) {
                    final date =
                        p['payment_date'] != null
                            ? dateFormat.format(
                              DateTime.parse(p['payment_date']),
                            )
                            : '-';
                    final amount = (p['amount_paid'] ?? 0).toStringAsFixed(2);
                    final mode = (p['payment_mode'] ?? '-').toUpperCase();

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
                            amount,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            mode,
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
                          totalPaid.toStringAsFixed(2),
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
                          remainingBalance.toStringAsFixed(2),
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
            ],

            pw.SizedBox(height: 20),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Authorized Signature',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
                pw.Text(
                  'Thank you for your payment!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'Generated digitally by School Fee Portal',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
    ),
  );

  return pdf;
}
