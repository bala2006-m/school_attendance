import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required String title,
  required List<dynamic> fees,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
}) async {
  final pdf = pw.Document();
  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();
  final logo =
      schoolPhotoBytes != null ? pw.MemoryImage(schoolPhotoBytes) : null;

  // 🟢 Group by Class + Section
  final Map<String, List<dynamic>> classFeesMap = {};
  for (final fee in fees) {
    final classInfo = fee['class'];
    if (classInfo == null) continue;
    final className = classInfo['class'] ?? '';
    final section = classInfo['section'] ?? '';
    final key = '$className-$section';
    classFeesMap.putIfAbsent(key, () => []).add(fee);
  }

  // Sort classes
  final List<String> classOrder = [
    'PreKG',
    'LKG',
    'UKG',
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
  ];

  final sortedKeys =
      classFeesMap.keys.toList()..sort((a, b) {
        final aParts = a.split('-');
        final bParts = b.split('-');
        final aClass = aParts[0];
        final bClass = bParts[0];
        final aIndex = classOrder.indexOf(aClass);
        final bIndex = classOrder.indexOf(bClass);
        if (aIndex != bIndex) return aIndex.compareTo(bIndex);
        return aParts[1].compareTo(bParts[1]);
      });

  // 🧮 Build each class page
  for (final key in sortedKeys) {
    final feeList = classFeesMap[key]!;
    final classInfo = feeList.first['class'];
    final className = classInfo['class'] ?? '';
    final section = classInfo['section'] ?? '';
    final classDisplay = '$className - Section $section';
    final currentDateStr = DateTime.now().toLocal().toString().split(' ').first;

    // 🟢 Group inside class by fee title (term)
    final Map<String, List<dynamic>> termMap = {};
    for (final fee in feeList) {
      final termTitle = fee['feeStructure']?['title'] ?? 'Unknown';
      termMap.putIfAbsent(termTitle, () => []).add(fee);
    }

    double classTotal = 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 🏫 Header
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
                    pw.SizedBox(width: 16),
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
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 🧾 Title
              pw.Center(
                child: pw.Text(
                  '$title\n$classDisplay',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueAccent,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // 🟢 Fee wise tables
              ...termMap.entries.expand((entry) {
                final termTitle = entry.key;
                final termFees = entry.value;
                final totalCollection = termFees.fold<double>(
                  0,
                  (sum, item) => sum + (item['paid_amount'] ?? 0).toDouble(),
                );
                classTotal += totalCollection;

                return [
                  // Term Title
                  pw.Text(
                    termTitle,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  // Table
                  pw.TableHelper.fromTextArray(
                    headers: const [
                      'S.No',
                      'Admn.No',
                      'Name',
                      'Paid Amount (₹)',
                      'Status',
                      'Method',
                      'Collected Date',
                      'Captured By',
                    ],
                    data: List<List<String>>.generate(termFees.length, (index) {
                      final fee = termFees[index];
                      final payments = fee['payments'] as List<dynamic>? ?? [];
                      final payment = payments.isNotEmpty ? payments.first : {};
                      final adminName = fee['admin']?['name'] ?? '';
                      final collectedDate =
                          payment['payment_date'] ?? fee['createdAt'] ?? '';
                      final formattedDate =
                          collectedDate.isNotEmpty
                              ? collectedDate.toString().split('T').first
                              : '';

                      return [
                        '${index + 1}',
                        fee['username']?.toString() ?? '',
                        fee['user']?['name'] ?? '',
                        (double.parse(
                          fee['paid_amount'].toString(),
                        ).toStringAsFixed(2)),
                        fee['status'] == 'PARTIALLY_PAID'
                            ? 'PARTIALLY PAID'
                            : fee['status'],
                        payment['method'] ?? '',
                        formattedDate,
                        adminName,
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
                      0: const pw.FixedColumnWidth(18),
                      3: const pw.FixedColumnWidth(50),
                      4: const pw.FixedColumnWidth(40),
                      5: const pw.FixedColumnWidth(40),
                      6: const pw.FixedColumnWidth(45),
                    },
                    cellAlignments: {
                      0: pw.Alignment.center,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerLeft,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerLeft,
                      5: pw.Alignment.centerLeft,
                      6: pw.Alignment.centerLeft,
                      7: pw.Alignment.centerLeft,
                    },
                    cellHeight: 25,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Total for $termTitle: ₹${totalCollection.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 14),
                ];
              }),

              pw.Divider(),
              pw.Row(
                children: [
                  pw.Text(
                    'Generated on: $currentDateStr',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'Class Total: ₹${classTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf;
}
