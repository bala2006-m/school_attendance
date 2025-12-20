import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Safely extracts string values from nested maps
String _safeGetString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  return value.toString().trim();
}

/// Safely extracts double values from nested maps
double _safeGetDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Safely extracts and formats date strings
String _formatDate(dynamic dateStr) {
  if (dateStr == null || dateStr.toString().isEmpty) return '';
  try {
    final dt = DateTime.parse(dateStr.toString());
    return DateFormat('dd-MM-yyyy').format(dt);
  } catch (_) {
    return dateStr.toString();
  }
}

/// Extracts class info from various data structures
Map<String, String> _extractClassInfo(dynamic classData) {
  String className = '';
  String section = '';

  if (classData is Map) {
    className = _safeGetString(
      classData['class'] ?? classData['className'] ?? '',
    );
    section = _safeGetString(classData['section'] ?? classData['sec'] ?? '');
  }

  return {'className': className, 'section': section};
}

/// Builds a PDF document showing Term fees, RTE fees and Bus fees grouped by class-section.
Future<pw.Document> buildPdf({
  required String title,
  required List<dynamic> fees, // term fees
  required List<dynamic> rtePayments, // RTE fees
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
  required List<dynamic> students,
  required List<dynamic> allPayments, // bus fees
}) async {
  final pdf = pw.Document();

  // Fonts
  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();
  final logo =
      schoolPhotoBytes != null ? pw.MemoryImage(schoolPhotoBytes) : null;

  // Group term fees by class-section
  final Map<String, List<dynamic>> classFeesMap = {};
  for (final fee in fees) {
    final classData = fee['class'];
    if (classData == null) continue;
    final classInfo = _extractClassInfo(classData);
    final className = classInfo['className'] ?? '';
    final section = classInfo['section'] ?? '';
    if (className.isEmpty) continue;
    final key = '$className-$section';
    classFeesMap.putIfAbsent(key, () => []).add(fee);
  }

  // Ensure classes that appear only in RTE or Bus are included
  for (final r in rtePayments) {
    final classes = r['classes'] ?? r['class'];
    final classInfo = _extractClassInfo(classes);
    final className =
        classInfo['className'] ?? _safeGetString(r['class_name'] ?? '');
    final section = classInfo['section'] ?? _safeGetString(r['section'] ?? '');
    if (className.isEmpty) continue;
    final key = '$className-$section';
    classFeesMap.putIfAbsent(key, () => []);
  }

  for (final p in allPayments) {
    final student = (p['student'] ?? {}) as Map?;
    if (student == null) continue;

    String className = '';
    String section = '';
    final classId = student['class_id'] ?? student['class']?['id'];

    if (classId != null) {
      try {
        final stu = students.firstWhere(
          (s) => (s['id'] ?? '').toString() == classId.toString(),
          orElse: () => null,
        );
        if (stu != null) {
          final classInfo = _extractClassInfo(stu['class']);
          className = classInfo['className'] ?? '';
          section = classInfo['section'] ?? '';
        }
      } catch (_) {
        // Ignore errors
      }
    }

    // Fallback to direct class info in payment
    if (className.isEmpty) {
      final classes = p['classes'] ?? p['class'];
      final classInfo = _extractClassInfo(classes);
      className = classInfo['className'] ?? '';
      section = classInfo['section'] ?? '';
    }

    if (className.isEmpty) continue;
    final key = '$className-$section';
    classFeesMap.putIfAbsent(key, () => []);
  }

  // Sort classes by order
  const List<String> classOrder = [
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
        final aClass = aParts.isNotEmpty ? aParts[0] : '';
        final bClass = bParts.isNotEmpty ? bParts[0] : '';
        final aIndex = classOrder.indexOf(aClass);
        final bIndex = classOrder.indexOf(bClass);
        if (aIndex != bIndex) {
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        }
        final aSec = aParts.length > 1 ? aParts[1] : '';
        final bSec = bParts.length > 1 ? bParts[1] : '';
        return aSec.compareTo(bSec);
      });

  // If everything empty, show a single page with message
  final bool allEmpty =
      fees.isEmpty && rtePayments.isEmpty && allPayments.isEmpty;
  if (allEmpty) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) {
          final currentDateStr = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now());
          return pw.Column(
            children: [
              _buildHeader(
                logo,
                schoolName,
                schoolAddress,
                title,
                currentDateStr,
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  'No collection found for the selected date',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  // For each class-section, create a MultiPage
  for (final key in sortedKeys) {
    final feeList = classFeesMap[key] ?? [];

    String className = '';
    String section = '';
    if (key.contains('-')) {
      final parts = key.split('-');
      className = parts[0];
      section = parts.length > 1 ? parts[1] : '';
    }

    // Build termMap from feeList
    final Map<String, List<dynamic>> termMap = {};
    for (final fee in feeList) {
      final termTitle = _safeGetString(
        fee['feeStructure']?['title'] ?? 'Unknown',
      );
      if (termTitle.isNotEmpty) {
        termMap.putIfAbsent(termTitle, () => []).add(fee);
      }
    }

    // Build RTE list for this class-section
    final classRteList =
        rtePayments.where((p) {
          final classes = p['classes'] ?? p['class'] ?? {};
          if (classes is Map) {
            final cName = _safeGetString(classes['class'] ?? '');
            final cSec = _safeGetString(classes['section'] ?? '');
            if (cName == className && (section.isEmpty || cSec == section)) {
              return true;
            }
          }

          // Fallback: match by student class_id
          final student = (p['student'] ?? {}) as Map?;
          if (student != null) {
            final studentClassId =
                student['class_id'] ?? student['class']?['id'];
            if (studentClassId != null && feeList.isNotEmpty) {
              final firstClassId = feeList.first['class']?['id'];
              if (firstClassId != null && firstClassId == studentClassId) {
                return true;
              }
            }
          }
          return false;
        }).toList();

    // Build bus payments for this class-section
    final classBusPayments =
        allPayments.where((p) {
          final student = (p['student'] ?? {}) as Map?;
          if (student == null) return false;

          final clsId = student['class_id'] ?? student['class']?['id'];
          if (clsId != null && feeList.isNotEmpty) {
            final firstClassId = feeList.first['class']?['id'];
            if (firstClassId != null) return firstClassId == clsId;
          }

          // Fallback: match by class name and section
          final classes = p['classes'] ?? p['class'] ?? {};
          if (classes is Map) {
            final cName = _safeGetString(classes['class'] ?? '');
            final cSec = _safeGetString(classes['section'] ?? '');
            if (cName == className && (section.isEmpty || cSec == section)) {
              return true;
            }
          }
          return false;
        }).toList();

    // Only add page if there is data
    if (termMap.isNotEmpty ||
        classRteList.isNotEmpty ||
        classBusPayments.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          footer:
              (context) => pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
          build: (context) {
            final currentDateStr = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.now());
            final List<pw.Widget> content = [];

            // Header
            content.add(
              _buildHeader(
                logo,
                schoolName,
                schoolAddress,
                title,
                currentDateStr,
              ),
            );
            content.add(pw.SizedBox(height: 12));
            content.add(
              pw.Center(
                child: pw.Text(
                  '$className - Section ${section.isEmpty ? "-" : section}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            );
            content.add(pw.SizedBox(height: 12));

            double classTotal = 0;

            // TERM FEES section
            if (termMap.isNotEmpty) {
              for (final termEntry in termMap.entries) {
                final termTitle = termEntry.key;
                final termFees = termEntry.value;

                final totalCollection = termFees.fold<double>(0, (sum, item) {
                  final val =
                      item['paid_amount'] ??
                      item['amount_paid'] ??
                      item['paidAmount'] ??
                      0;
                  return sum + _safeGetDouble(val);
                });
                classTotal += totalCollection;

                content.add(
                  pw.Text(
                    termTitle,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
                content.add(pw.SizedBox(height: 6));

                final data = _buildTermFeesTableData(termFees);
                content.add(_buildTermFeesTable(data));
                content.add(pw.SizedBox(height: 6));
                content.add(
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Total for $termTitle: ₹${totalCollection.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                );
                content.add(pw.SizedBox(height: 12));
              }
            }

            // RTE FEES section
            if (classRteList.isNotEmpty) {
              final rteTotal = classRteList.fold<double>(0, (sum, p) {
                final val =
                    p['amount_paid'] ??
                    p['paid_amount'] ??
                    p['paidAmount'] ??
                    0;
                return sum + _safeGetDouble(val);
              });
              classTotal += rteTotal;

              content.add(
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'RTE Fee Collection',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 8));

              final rteData = _buildRteTableData(classRteList);
              content.add(_buildRteTable(rteData));
              content.add(pw.SizedBox(height: 8));
              content.add(
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'RTE Fees Total: ₹${rteTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 12));
            }

            // BUS FEES section
            if (classBusPayments.isNotEmpty) {
              final busTotal = classBusPayments.fold<double>(0, (sum, p) {
                final val = p['amount_paid'] ?? p['paid_amount'] ?? 0;
                return sum + _safeGetDouble(val);
              });
              classTotal += busTotal;

              content.add(
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.yellow200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Bus Fees Collection',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.yellow900,
                    ),
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 8));

              final busData = _buildBusTableData(classBusPayments);
              content.add(_buildBusTable(busData));
              content.add(pw.SizedBox(height: 8));
              content.add(
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Bus Fees Total: ₹${busTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepOrange800,
                    ),
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 12));
            }

            // Final Class Total
            content.add(pw.Divider(color: PdfColors.grey400));
            content.add(
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Class Total: ₹${classTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
            );
            content.add(pw.SizedBox(height: 8));
            content.add(
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.right,
              ),
            );

            // Always return a Column, even if content is empty
            return [
              pw.Column(
                children:
                    content.isEmpty
                        ? [pw.Text('No data for this class')]
                        : content,
              ),
            ];
          },
        ),
      );
    }
  }

  return pdf;
}

/// Builds the PDF header with school logo, name, and report details
pw.Widget _buildHeader(
  pw.MemoryImage? logo,
  String? schoolName,
  String? schoolAddress,
  String title,
  String currentDateStr,
) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (logo != null)
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            image: pw.DecorationImage(image: logo, fit: pw.BoxFit.cover),
            border: pw.Border.all(color: PdfColors.blueAccent, width: 1),
          ),
        ),
      if (logo != null) pw.SizedBox(width: 12),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              schoolName ?? 'School Name',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            if (schoolAddress != null && schoolAddress.isNotEmpty)
              pw.Text(schoolAddress, style: pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Date: $currentDateStr', style: pw.TextStyle(fontSize: 9)),
        ],
      ),
    ],
  );
}

/// Builds table data for term fees
List<List<String>> _buildTermFeesTableData(List<dynamic> termFees) {
  return List<List<String>>.generate(termFees.length, (index) {
    final fee = termFees[index] as Map;
    final payments = (fee['payments'] ?? []) as List<dynamic>;
    final payment = payments.isNotEmpty ? (payments.first ?? {}) as Map : {};

    final adminName = _safeGetString(
      fee['admin']?['name'] ?? payment['admin']?['name'] ?? '',
    );
    final paidAmountVal =
        fee['paid_amount'] ?? fee['amount_paid'] ?? fee['paidAmount'] ?? 0;
    final paidAmountStr =
        '₹${_safeGetDouble(paidAmountVal).toStringAsFixed(2)}';
    final method = _safeGetString(
      payment['payment_mode'] ??
          payment['paymentMode'] ??
          fee['payment_mode'] ??
          '',
    );
    final status = _safeGetString(fee['status'] ?? '');
    // final dateStr =
    payment['payment_date'] ?? fee['payment_date'] ?? fee['created_at'];
    // final dateFormatted = _formatDate(dateStr);

    return [
      '${index + 1}',
      _safeGetString(fee['username'] ?? fee['admission_no'] ?? ''),
      _safeGetString(fee['user']?['name'] ?? fee['student_name'] ?? ''),
      paidAmountStr,
      method,
      status,
      adminName,
    ];
  });
}

/// Builds term fees table widget
pw.Widget _buildTermFeesTable(List<List<String>> data) {
  return pw.TableHelper.fromTextArray(
    headers: [
      'S.No',
      'Admn.No',
      'Name',
      'Paid Amount (₹)',
      'Method',
      'Status',
      'Collected By',
    ],
    data: data,
    headerStyle: pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      fontSize: 9,
    ),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
    rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
    cellPadding: const pw.EdgeInsets.all(4),
    cellAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerLeft,
      5: pw.Alignment.centerLeft,
      6: pw.Alignment.centerLeft,
    },
    cellStyle: pw.TextStyle(fontSize: 9),
  );
}

/// Builds table data for RTE fees
List<List<String>> _buildRteTableData(List<dynamic> rteList) {
  return List<List<String>>.generate(rteList.length, (index) {
    final p = rteList[index] as Map;
    final student = (p['student'] ?? {}) as Map;

    final adm = _safeGetString(student['username'] ?? '');
    final name = _safeGetString(student['name'] ?? '');
    final amtVal = p['amount_paid'] ?? p['paid_amount'] ?? p['paidAmount'] ?? 0;
    final amtStr = '₹${_safeGetDouble(amtVal).toStringAsFixed(2)}';
    final method = _safeGetString(
      p['payment_mode'] ?? p['paymentMode'] ?? p['method'] ?? '',
    );
    final dateStr = p['payment_date'] ?? p['created_at'];
    final dateFormatted = _formatDate(dateStr);
    final adminName = _safeGetString(p['admin']?['name'] ?? '');

    return [
      '${index + 1}',
      adm,
      name,
      amtStr,
      method,
      dateFormatted,
      adminName,
    ];
  });
}

/// Builds RTE fees table widget
pw.Widget _buildRteTable(List<List<String>> data) {
  return pw.TableHelper.fromTextArray(
    headers: [
      'S.No',
      'Admn.No',
      'Name',
      'Amount (₹)',
      'Method',
      'Date',
      'Collected By',
    ],
    data: data,
    headerStyle: pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      fontSize: 9,
    ),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.orange50),
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellPadding: const pw.EdgeInsets.all(4),
    cellAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerLeft,
      5: pw.Alignment.centerLeft,
      6: pw.Alignment.centerLeft,
    },
  );
}

/// Builds table data for bus fees
List<List<String>> _buildBusTableData(List<dynamic> busList) {
  return List<List<String>>.generate(busList.length, (index) {
    final p = busList[index] as Map;
    final student = (p['student'] ?? {}) as Map;
    final busFeeStructure = (p['busFeeStructure'] ?? {}) as Map;

    final adm = _safeGetString(student['username'] ?? '');
    final name = _safeGetString(student['name'] ?? '');
    final route = _safeGetString(busFeeStructure['route'] ?? p['route'] ?? '');
    final term = _safeGetString(busFeeStructure['term'] ?? '');
    final amtVal = p['amount_paid'] ?? p['paid_amount'] ?? 0;
    final amtStr = '₹${_safeGetDouble(amtVal).toStringAsFixed(2)}';
    final method = _safeGetString(p['payment_mode'] ?? p['paymentMode'] ?? '');
    final dateStr = p['payment_date'] ?? p['created_at'];
    final dateFormatted = _formatDate(dateStr);
    final adminName = _safeGetString(p['admin']?['name'] ?? '');

    return [
      '${index + 1}',
      adm,
      name,
      route,
      term,
      amtStr,
      method,
      dateFormatted,
      adminName,
    ];
  });
}

/// Builds bus fees table widget
pw.Widget _buildBusTable(List<List<String>> data) {
  return pw.TableHelper.fromTextArray(
    headers: [
      'S.No',
      'Admn.No',
      'Name',
      'Route',
      'Term',
      'Paid Amount (₹)',
      'Method',
      'Date',
      'Collected By',
    ],
    data: data,
    headerStyle: pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      fontSize: 9,
    ),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.yellow800),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.yellow200),
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellPadding: const pw.EdgeInsets.all(4),
    cellAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerLeft,
      4: pw.Alignment.centerLeft,
      5: pw.Alignment.centerRight,
      6: pw.Alignment.centerLeft,
      7: pw.Alignment.centerLeft,
      8: pw.Alignment.centerLeft,
    },
  );
}
