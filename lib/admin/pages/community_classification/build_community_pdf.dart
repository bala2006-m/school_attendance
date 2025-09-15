import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> buildPdf({
  required Uint8List schoolPhotoBytes,
  required String? schoolName,
  required String? schoolAddress,
  required List<Map<String, dynamic>> students,
  bool isLandscape = false,
}) async {
  final pdf = pw.Document();

  final pageFormat = (isLandscape
          ? PdfPageFormat.a4.landscape
          : PdfPageFormat.a4.portrait)
      .copyWith(
        marginLeft: 10,
        marginRight: 10,
        marginTop: 20,
        marginBottom: 20,
      );

  final headerTextStyle = pw.TextStyle(
    fontSize: isLandscape ? 16 : 14,
    fontWeight: pw.FontWeight.bold,
  );

  final bodyTextStyle = pw.TextStyle(fontSize: isLandscape ? 12 : 12);

  final cellPadding =
      isLandscape
          ? pw.EdgeInsets.only(top: 8, bottom: 8, left: 8)
          : pw.EdgeInsets.only(top: 4, bottom: 4, left: 4);
  final rightCellPadding =
      isLandscape
          ? pw.EdgeInsets.only(top: 8, bottom: 8, right: 8)
          : pw.EdgeInsets.only(top: 4, bottom: 4, right: 4);
  if (students.isEmpty) {
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build:
            (context) => pw.Center(
              child: pw.Text(
                "No students Found",
                style: pw.TextStyle(fontSize: 18),
              ),
            ),
      ),
    );
  } else {
    final communities =
        students
            .map((s) => (s['community'] ?? '').toString().trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var s in students) {
      final key = "${s['class']}-${s['section']}";
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FixedColumnWidth(60),
    };

    final int flexColumnCount = communities.length * 2 + 2;
    for (int i = 1; i <= flexColumnCount; i++) {
      columnWidths[i] = const pw.FlexColumnWidth(1);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build:
            (context) => [
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(
                      pw.MemoryImage(schoolPhotoBytes),
                      width: isLandscape ? 100 : 80,
                      height: isLandscape ? 100 : 80,
                    ),
                    if (schoolName != null)
                      pw.Text(
                        schoolName,
                        style: pw.TextStyle(
                          fontSize: isLandscape ? 20 : 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    if (schoolAddress != null)
                      pw.Text(
                        schoolAddress,
                        style: pw.TextStyle(fontSize: isLandscape ? 14 : 12),
                        textAlign: pw.TextAlign.center,
                      ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      "Community Classification Report",
                      style: pw.TextStyle(
                        fontSize: isLandscape ? 26 : 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: pageFormat.availableWidth,
                      child: buildTable(
                        communities,
                        grouped,
                        students,
                        columnWidths,
                        headerTextStyle,
                        bodyTextStyle,
                        cellPadding,
                        rightCellPadding,
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text("__________________"),
                            pw.Text("Principal"),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

pw.Table buildTable(
  List<String> communities,
  Map<String, List<Map<String, dynamic>>> grouped,
  List<Map<String, dynamic>> students,
  Map<int, pw.TableColumnWidth> columnWidths,
  pw.TextStyle headerTextStyle,
  pw.TextStyle bodyTextStyle,
  pw.EdgeInsets cellPadding,
  pw.EdgeInsets rightCellPadding,
) {
  pw.BoxDecoration rightSideBorderDecoration() {
    return pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide.none,
        bottom: pw.BorderSide.none,
        left: pw.BorderSide.none,
        right: pw.BorderSide(width: 1),
      ),
    );
  }

  pw.BoxDecoration rightLeftSideBorderDecoration() {
    return pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide.none,
        bottom: pw.BorderSide(width: 1),
        left: pw.BorderSide(width: 1),
        right: pw.BorderSide(width: 1),
      ),
    );
  }

  List<String> splitCommunityName(String name) {
    final length = name.length;
    if (length == 0) return ['', ''];

    final mid = (length / 2).ceil(); // First part is longer if odd

    final part1 = name.substring(0, mid);
    final part2 = name.substring(mid);

    return [part1, part2];
  }

  return pw.Table(
    border: pw.TableBorder.symmetric(
      inside: pw.BorderSide.none,
      outside: pw.BorderSide(width: 1),
    ),
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    columnWidths: columnWidths,
    children: [
      // Header row 1: Community names
      pw.TableRow(
        decoration: pw.BoxDecoration(
          border: pw.Border.symmetric(horizontal: pw.BorderSide(width: 1)),
        ),
        children: [
          pw.Container(
            decoration: rightSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text('Class', style: headerTextStyle),
          ),
          ...communities.expand((c) {
            final parts = splitCommunityName(c);
            return [
              pw.Container(
                alignment: pw.Alignment.centerRight,
                padding: cellPadding,
                child: pw.Text(parts[0], style: headerTextStyle),
              ),
              pw.Container(
                decoration: rightSideBorderDecoration(),
                alignment: pw.Alignment.centerLeft,
                padding: rightCellPadding,
                child: pw.Text(parts[1], style: headerTextStyle),
              ),
            ];
          }),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: cellPadding,
            child: pw.Text('Tot', style: headerTextStyle),
          ),
          pw.Container(
            alignment: pw.Alignment.centerLeft,
            padding: rightCellPadding,
            child: pw.Text('al', style: headerTextStyle),
          ),
        ],
      ),

      // Header row 2: M/F under each community (no top border between headers)
      pw.TableRow(
        children: [
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text(
              '_',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          ...communities.expand(
            (_) => [
              pw.Container(
                decoration: rightLeftSideBorderDecoration(),
                alignment: pw.Alignment.center,
                padding: cellPadding,
                child: pw.Text('M', style: headerTextStyle),
              ),
              pw.Container(
                decoration: rightLeftSideBorderDecoration(),
                alignment: pw.Alignment.center,
                padding: cellPadding,
                child: pw.Text('F', style: headerTextStyle),
              ),
            ],
          ),
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text('M', style: headerTextStyle),
          ),
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text('F', style: headerTextStyle),
          ),
        ],
      ),

      // Data rows and total row remain unchanged
      ...grouped.entries.map((entry) {
        final classKey = entry.key;
        final classStudents = entry.value;
        final rowCells = <pw.Widget>[
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text(classKey, style: bodyTextStyle),
          ),
        ];

        for (final c in communities) {
          final maleCount =
              classStudents
                  .where((s) => s['community'] == c && s['gender'] == 'M')
                  .length;
          final femaleCount =
              classStudents
                  .where((s) => s['community'] == c && s['gender'] == 'F')
                  .length;

          rowCells.addAll([
            pw.Container(
              decoration: rightLeftSideBorderDecoration(),
              alignment: pw.Alignment.center,
              padding: cellPadding,
              child: pw.Text(
                maleCount == 0 ? '-' : maleCount.toString(),
                style: bodyTextStyle,
              ),
            ),
            pw.Container(
              decoration: rightLeftSideBorderDecoration(),
              alignment: pw.Alignment.center,
              padding: cellPadding,
              child: pw.Text(
                femaleCount == 0 ? '-' : femaleCount.toString(),
                style: bodyTextStyle,
              ),
            ),
          ]);
        }

        final totalM = classStudents.where((s) => s['gender'] == 'M').length;
        final totalF = classStudents.where((s) => s['gender'] == 'F').length;

        rowCells.addAll([
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text(
              totalM == 0 ? '-' : totalM.toString(),
              style: bodyTextStyle,
            ),
          ),
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text(
              totalF == 0 ? '-' : totalF.toString(),
              style: bodyTextStyle,
            ),
          ),
        ]);

        return pw.TableRow(children: rowCells);
      }),

      // Total row
      pw.TableRow(
        children: [
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text('Total', style: headerTextStyle),
          ),
          ...communities.expand((c) {
            final totalMale =
                students
                    .where((s) => s['community'] == c && s['gender'] == 'M')
                    .length;
            final totalFemale =
                students
                    .where((s) => s['community'] == c && s['gender'] == 'F')
                    .length;

            return [
              pw.Container(
                decoration: rightLeftSideBorderDecoration(),
                alignment: pw.Alignment.center,
                padding: cellPadding,
                child: pw.Text(
                  totalMale == 0 ? '-' : totalMale.toString(),
                  style: headerTextStyle,
                ),
              ),
              pw.Container(
                decoration: rightLeftSideBorderDecoration(),
                alignment: pw.Alignment.center,
                padding: cellPadding,
                child: pw.Text(
                  totalFemale == 0 ? '-' : totalFemale.toString(),
                  style: headerTextStyle,
                ),
              ),
            ];
          }),
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text(
              students.where((s) => s['gender'] == 'M').length.toString(),
              style: headerTextStyle,
            ),
          ),
          pw.Container(
            decoration: rightLeftSideBorderDecoration(),
            alignment: pw.Alignment.center,
            padding: cellPadding,
            child: pw.Text(
              students.where((s) => s['gender'] == 'F').length.toString(),
              style: headerTextStyle,
            ),
          ),
        ],
      ),
    ],
  );
}
