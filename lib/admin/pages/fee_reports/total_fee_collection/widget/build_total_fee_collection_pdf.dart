import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentPayment {
  final String admissionNumber;
  final String studentName;
  final double paidAmount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String status;
  final double totalFeeAmount;

  StudentPayment({
    required this.admissionNumber,
    required this.studentName,
    required this.paidAmount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.status,
    required this.totalFeeAmount,
  });
}

double _parseAmount(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  try {
    return double.parse(value.toString());
  } catch (e) {
    return 0.0;
  }
}

String _formatDate(dynamic dateValue) {
  if (dateValue == null) return '';
  try {
    final DateTime parsedDate =
        dateValue is DateTime
            ? dateValue
            : DateTime.parse(dateValue.toString());
    final localDate = parsedDate.isUtc ? parsedDate.toLocal() : parsedDate;
    return "${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}";
  } catch (e) {
    return '';
  }
}

String _getStatus(double paidAmount, double totalFeeAmount) {
  return paidAmount >= totalFeeAmount ? 'PAID' : 'PARTIALLY PAID';
}

List<StudentPayment> _aggregateStudentPayments(List<dynamic> fees) {
  final Map<String, StudentPayment> aggregated = {};

  for (final fee in fees) {
    final username = fee['username']?.toString() ?? '';
    final user = fee['user'] as Map<dynamic, dynamic>? ?? {};
    final studentName = user['name']?.toString() ?? 'Unknown';
    final payments = fee['payments'] as List<dynamic>? ?? [];
    final totalFeeAmount = _parseAmount(fee['total_amount']);

    if (payments.isEmpty) continue;

    final payment = payments[0] as Map<dynamic, dynamic>;
    final paidAmount = _parseAmount(fee['paid_amount']);
    final paymentMethod = payment['method']?.toString() ?? '';
    final paymentDate = payment['payment_date'];
    final status = _getStatus(paidAmount, totalFeeAmount);

    final key = username;

    if (aggregated.containsKey(key)) {
      final existing = aggregated[key]!;
      aggregated[key] = StudentPayment(
        admissionNumber: existing.admissionNumber,
        studentName: existing.studentName,
        paidAmount: existing.paidAmount + paidAmount,
        paymentMethod: paymentMethod,
        paymentDate: existing.paymentDate,
        status: _getStatus(existing.paidAmount + paidAmount, totalFeeAmount),
        totalFeeAmount: totalFeeAmount,
      );
    } else {
      aggregated[key] = StudentPayment(
        admissionNumber: username,
        studentName: studentName,
        paidAmount: paidAmount,
        paymentMethod: paymentMethod,
        paymentDate: DateTime.parse(paymentDate.toString()),
        status: status,
        totalFeeAmount: totalFeeAmount,
      );
    }
  }

  return aggregated.values.toList();
}

Future<pw.Document> buildPdf({
  required String title,
  required List<dynamic> fees,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
  required String className,
  required String section,
}) async {
  final pdf = pw.Document();
  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();
  final logo =
      schoolPhotoBytes != null ? pw.MemoryImage(schoolPhotoBytes) : null;

  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  final filteredFees =
      fees.where((fee) {
        final status = (fee['status'] ?? '').toString().toLowerCase();
        return status == 'paid' ||
            status == 'partially_paid' ||
            status == 'partiallypaid';
      }).toList();

  final Map<int, List<dynamic>> groupedFees = {};
  for (final fee in filteredFees) {
    final structure = fee['feeStructure'];
    if (structure == null || structure['id'] == null) continue;
    final id = structure['id'] as int;
    groupedFees.putIfAbsent(id, () => []).add(fee);
  }

  for (final entry in groupedFees.entries) {
    final feeList = entry.value;
    final structure = feeList.first['feeStructure'] as Map<dynamic, dynamic>;

    final structureTitle = structure['title'] ?? 'Unknown Term';
    final descriptions =
        (structure['descriptions'] as List<dynamic>?)?.cast<String>() ?? [];
    final amounts = structure['amounts'] as List<dynamic>? ?? [];
    final total = _parseAmount(structure['total_amount']);
    final startDate = _formatDate(structure['start_date']);
    final endDate = _formatDate(structure['end_date']);

    final studentPayments = _aggregateStudentPayments(feeList);

    final totalCollection = studentPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.paidAmount,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null)
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          image: pw.DecorationImage(
                            image: logo,
                            fit: pw.BoxFit.cover,
                          ),
                          border: pw.Border.all(
                            color: PdfColors.blueAccent,
                            width: 1,
                          ),
                        ),
                      ),
                    if (logo != null) pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            schoolName ?? 'School Name',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          if (schoolAddress != null)
                            pw.Text(
                              schoolAddress,
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey700,
                              ),
                              maxLines: 2,
                            ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue50,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Text(
                              'Class: $className | Section: $section',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.blue800,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              pw.Center(
                child: pw.Text(
                  '$title - $structureTitle',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueAccent,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blueGrey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Fee Structure Details',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.TableHelper.fromTextArray(
                      headers: ['Description', 'Amount (₹)'],
                      data: List.generate(
                        descriptions.length,
                        (i) => [
                          descriptions[i],
                          currencyFormat.format(
                            _parseAmount(amounts.length > i ? amounts[i] : 0),
                          ),
                        ],
                      ),
                      border: pw.TableBorder.all(
                        color: PdfColors.grey600,
                        width: 0.5,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.blueGrey400,
                      ),
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                      cellStyle: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Total: ${currencyFormat.format(total)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Valid: $startDate to $endDate',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              pw.TableHelper.fromTextArray(
                headers: [
                  'S.No',
                  'Admn. No',
                  'Name',
                  'Amount (₹)',
                  'Status',
                  'Date',
                  'Method',
                ],
                data: List<List<String>>.generate(studentPayments.length, (
                  index,
                ) {
                  final payment = studentPayments[index];
                  return [
                    '${index + 1}',
                    payment.admissionNumber,
                    payment.studentName,
                    currencyFormat.format(payment.paidAmount),
                    payment.status,
                    _formatDate(payment.paymentDate),
                    payment.paymentMethod,
                  ];
                }),
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueAccent,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                columnWidths: {
                  0: const pw.FixedColumnWidth(8),
                  1: const pw.FixedColumnWidth(18),
                  2: const pw.FixedColumnWidth(45),
                  3: const pw.FixedColumnWidth(25),
                  4: const pw.FixedColumnWidth(20),
                  5: const pw.FixedColumnWidth(22),
                  6: const pw.FixedColumnWidth(20),
                },
                cellHeight: 25,
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Students: ${studentPayments.length}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Collection: ${currencyFormat.format(totalCollection)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated: ${_formatDate(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf;
}
