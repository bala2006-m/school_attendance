// Updated buildRtePdf() with fee structure table and modified payments table

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildRtePdf({
  required List<dynamic> students,
  required List<dynamic> payments,
  required List<dynamic> structures,
  String? schoolName,
  String? schoolAddress,
  Uint8List? schoolPhotoBytes,
  required String className,
  required String section,
}) async {
  final pdf = pw.Document();

  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();
  final logo =
      schoolPhotoBytes != null ? pw.MemoryImage(schoolPhotoBytes) : null;

  final now = DateTime.now();
  final formattedDate =
      "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

  final studentMap = {
    for (var s in students)
      (s["username"] ?? s["id"]).toString(): s["name"] ?? "Unknown",
  };

  // final structureMap = {for (var s in structures) (s["id"]).toString(): s};

  final totalAmount = payments.fold<num>(
    0,
    (sum, p) => sum + (p["amount_paid"] ?? 0),
  );

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build:
          (context) => [
            // HEADER
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
                          schoolName ?? "School Name",
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

            pw.SizedBox(height: 16),

            // TITLE
            pw.Center(
              child: pw.Text(
                "PAID RTE FEE REPORT",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueAccent,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),

            pw.SizedBox(height: 16),

            // CLASS & DATE
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Class: $className - $section",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    "Date: $formattedDate",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // FEE STRUCTURE TABLE
            if (structures.isNotEmpty) ...[
              pw.Text(
                "Fee Structure",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blueAccent),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Descriptions",
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Amount (₹)",
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...structures.expand((s) {
                    final descList =
                        (s["descriptions"] as List?)?.cast<String>() ?? [];
                    final amtList =
                        (s["amounts"] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [];

                    final rows = <pw.TableRow>[];

                    for (int i = 0; i < descList.length; i++) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(descList[i]),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                amtList.length > i
                                    ? double.parse(
                                      amtList[i].toString(),
                                    ).toStringAsFixed(2)
                                    : "-",
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    rows.add(
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              "Total",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              double.parse(
                                s["total_amount"].toString(),
                              ).toStringAsFixed(2),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    return rows;
                  }),
                ],
              ),

              pw.SizedBox(height: 20),
            ],

            // PAYMENTS TABLE
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blueAccent),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: [
                "S.No",
                "Name",
                "Admn. No",
                "Paid Date",
                "Amount (₹)",
                "Mode",
                "Status",
              ],
              data: List.generate(payments.length, (index) {
                final p = payments[index];
                final studentId = p["student_id"].toString();
                final studentName = studentMap[studentId] ?? "-";
                final date =
                    p["payment_date"]?.toString().split("T").first ?? "";
                final amt = p["amount_paid"]?.toString() ?? "0";

                return [
                  "${index + 1}",
                  studentName,
                  studentId,
                  DateFormat("dd-MM-yyyy").format(DateTime.parse(date)),
                  double.parse(amt.toString()).toStringAsFixed(2),
                  p["payment_mode"] ?? "-",
                  p["status"] ?? "-",
                ];
              }),
            ),

            pw.SizedBox(height: 20),

            // TOTAL PAYMENT AMOUNT
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  "Total Amount Collected: ",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "₹${totalAmount.toString()}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ],
            ),
          ],
    ),
  );

  return pdf;
}
