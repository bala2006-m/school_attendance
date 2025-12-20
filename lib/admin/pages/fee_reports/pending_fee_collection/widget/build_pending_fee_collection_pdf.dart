import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required String title,
  required Map<String, dynamic> fees,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
}) async {
  final pdf = pw.Document();

  // Load fonts
  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final logo =
      schoolPhotoBytes != null && schoolPhotoBytes.isNotEmpty
          ? pw.MemoryImage(schoolPhotoBytes)
          : null;

  final List<dynamic> students = (fees['students'] as List?) ?? [];
  final List<dynamic> feeStructures = (fees['feeStructures'] as List?) ?? [];
  final totalPendingRaw = fees['totalPending'] ?? 0;

  // Group students by class
  final Map<int, List<Map<String, dynamic>>> studentsByClass = {};
  for (final s in students) {
    final student = (s as Map).cast<String, dynamic>();
    final classMap = (student['class'] as Map?)?.cast<String, dynamic>();
    final int classId =
        classMap?['id'] as int? ?? student['class_id'] as int? ?? 0;

    studentsByClass.putIfAbsent(classId, () => []).add(student);
  }

  // Group feeStructure
  final Map<int, List<Map<String, dynamic>>> feeByClass = {};
  for (final f in feeStructures) {
    final fee = (f as Map).cast<String, dynamic>();
    final int classId = fee['class_id'] as int? ?? 0;

    feeByClass.putIfAbsent(classId, () => []).add(fee);
  }

  // Pending by student
  final Map<String, double> pendingByStudent = {};

  for (final s in students) {
    final student = (s as Map).cast<String, dynamic>();
    double pendingAmount = 0.0;

    final int classId = student['class_id'] as int? ?? 0;
    final classFeeStructures = feeByClass[classId] ?? [];

    final List<Map<String, dynamic>> studentFeesList =
        ((student['studentFees'] as List?) ?? [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

    final Map<int, Map<String, double>> studentFeesMerged = {};

    for (final sf in studentFeesList) {
      final feeStructureMap =
          (sf['feeStructure'] as Map?)?.cast<String, dynamic>();
      final int fsId = feeStructureMap?['id'] as int? ?? 0;

      studentFeesMerged.putIfAbsent(fsId, () => {"total": 0.0, "paid": 0.0});

      final double totalAmount =
          double.tryParse(sf['total_amount'].toString()) ??
          studentFeesMerged[fsId]!["total"]!;
      studentFeesMerged[fsId]!["total"] = totalAmount;

      final List<dynamic> paymentsDynamic = (sf['payments'] as List?) ?? [];

      for (final p in paymentsDynamic) {
        final payment = (p as Map).cast<String, dynamic>();
        studentFeesMerged[fsId]!["paid"] =
            (studentFeesMerged[fsId]!["paid"] ?? 0.0) +
            (double.tryParse(payment['amount'].toString()) ?? 0.0);
      }
    }

    for (final feeStructure in classFeeStructures) {
      final int fsId = feeStructure['id'] as int? ?? 0;
      final double total =
          double.tryParse(feeStructure['total_amount'].toString()) ?? 0.0;

      if (studentFeesMerged.containsKey(fsId)) {
        final double paid = studentFeesMerged[fsId]!["paid"] ?? 0.0;
        final double diff = total - paid;
        if (diff > 0) pendingAmount += diff;
      } else {
        pendingAmount += total;
      }
    }

    pendingByStudent[student['username'].toString()] = pendingAmount;
  }

  // Calculate total pending amount
  final double totalPendingAmount = pendingByStudent.values.fold(
    0.0,
    (sum, amount) => sum + amount,
  );

  // Helper: Paginate LARGE student tables to avoid TooManyPagesException
  List<List<Map<String, dynamic>>> chunkList(
    List<Map<String, dynamic>> list,
    int size,
  ) {
    List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  pdf.addPage(
    pw.MultiPage(
      maxPages: 999,
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      build: (context) {
        return [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
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
                    ),
                  ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        schoolName ?? "School Name",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (schoolAddress != null &&
                          schoolAddress.trim().isNotEmpty)
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
          pw.SizedBox(height: 16),

          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
          ),

          pw.SizedBox(height: 12),

          pw.Text(
            "Total Pending Students: $totalPendingRaw",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Total Pending Amount: ₹${totalPendingAmount.toStringAsFixed(2)}",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 16),

          ...studentsByClass.entries.map((entry) {
            final classId = entry.key;
            final classStudents = entry.value;

            final firstClass =
                (classStudents.first['class'] as Map?)?.cast<String, dynamic>();
            final String className =
                "${firstClass?['class'] ?? ''}-${firstClass?['section'] ?? ''}";

            final classFees = feeByClass[classId] ?? [];

            final chunks = chunkList(classStudents, 25);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.blueGrey50,
                  child: pw.Text(
                    "Class: $className",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueAccent,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),

                if (classFees.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: ["Term", "Status", "Total ₹", "Start", "End"],
                    data:
                        classFees.map((f) {
                          return [
                            f['title'].toString(),
                            f['status'].toString(),
                            (double.tryParse(f['total_amount'].toString()) ??
                                    0.0)
                                .toStringAsFixed(2),
                            f['start_date'].toString().split('T')[0],
                            f['end_date'].toString().split('T')[0],
                          ];
                        }).toList(),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey400,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    border: pw.TableBorder.all(width: 0.5),
                  ),

                pw.SizedBox(height: 10),

                ...chunks.map((chunk) {
                  return pw.Column(
                    children: [
                      pw.TableHelper.fromTextArray(
                        headers: [
                          "S.No",
                          "Admn",
                          "Name",
                          "Father",
                          "Mobile",
                          "Pending ₹",
                        ],
                        data: [
                          ...chunk.asMap().entries.map((e) {
                            final student = e.value;
                            final pending =
                                pendingByStudent[student['username']
                                    .toString()] ??
                                0.0;

                            return [
                              (e.key + 1).toString(),
                              student['username'].toString(),
                              student['name'].toString(),
                              student['father_name'].toString(),
                              student['mobile'].toString(),
                              pending.toStringAsFixed(2),
                            ];
                          }),
                        ],
                        headerDecoration: pw.BoxDecoration(
                          color: PdfColors.blue,
                        ),
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        border: pw.TableBorder.all(width: 0.5),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            );
          }),

          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Generated on: ${DateTime.now().toString().split(" ").first}",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ];
      },
    ),
  );

  return pdf;
}
