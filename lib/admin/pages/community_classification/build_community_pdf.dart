import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required Uint8List? schoolPhotoBytes,
  required String? schoolName,
  required String? schoolAddress,
  required List<Map<String, dynamic>> students,
  bool isLandscape = false,
}) async {
  final pdf = pw.Document();

  // load fonts (adjust if you're using a different font loader)
  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  final pageFormat =
      (isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4).copyWith(
        marginLeft: 10,
        marginRight: 10,
        marginTop: 20,
        marginBottom: 20,
      );

  final headerTextStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  );
  final bodyTextStyle = pw.TextStyle(fontSize: 9);

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
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
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
    return pdf;
  }

  // Define class order for sorting
  final classOrder = [
    'PREKG',
    'LKG',
    'UKG',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
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

  int classCompare(String a, String b) {
    final aIndex = classOrder.indexOf(a.toUpperCase());
    final bIndex = classOrder.indexOf(b.toUpperCase());
    if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
    if (aIndex == -1) return 1;
    if (bIndex == -1) return -1;
    return aIndex.compareTo(bIndex);
  }

  // Normalize student entries (avoid null exceptions)
  final normalizedStudents =
      students.map((s) {
        return {
          'class': (s['class'] ?? '').toString(),
          'section': (s['section'] ?? '').toString(),
          'community': (s['community'] ?? '').toString(),
          'gender': (s['gender'] ?? '').toString().toUpperCase(),
          ...s, // keep other fields intact if present
        };
      }).toList();

  // Sort students by class and section
  normalizedStudents.sort((a, b) {
    final classA = (a['class'] ?? '').toString().toUpperCase();
    final classB = (b['class'] ?? '').toString().toUpperCase();
    final sectionA = (a['section'] ?? '').toString().toUpperCase();
    final sectionB = (b['section'] ?? '').toString().toUpperCase();

    final classCmp = classCompare(classA, classB);
    if (classCmp != 0) return classCmp;
    return sectionA.compareTo(sectionB);
  });

  // Group students by "class-section"
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (var s in normalizedStudents) {
    final cls = (s['class'] ?? '').toString();
    final sec = (s['section'] ?? '').toString();
    final key = sec.isEmpty ? cls : '$cls-$sec';
    grouped.putIfAbsent(key, () => []).add(s);
  }

  // Sort grouped entries by class and section keys
  final sortedGroupedEntries =
      grouped.entries.toList()..sort((a, b) {
        final aKey = a.key.split('-');
        final bKey = b.key.split('-');
        final classA = aKey[0].toUpperCase();
        final sectionA = aKey.length > 1 ? aKey[1].toUpperCase() : '';
        final classB = bKey[0].toUpperCase();
        final sectionB = bKey.length > 1 ? bKey[1].toUpperCase() : '';

        final classCmp = classCompare(classA, classB);
        if (classCmp != 0) return classCmp;
        return sectionA.compareTo(sectionB);
      });

  // Communities (unique, sorted)
  final communities =
      normalizedStudents
          .map((s) => (s['community'] ?? '').toString().trim())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  // Build columnWidths map: column 0 fixed, remaining columns flex
  final Map<int, pw.TableColumnWidth> columnWidths = {};
  columnWidths[0] = const pw.FixedColumnWidth(60);
  final int otherCols =
      (communities.length * 2) + 2; // 2 columns per community + Tot M + Tot F
  for (int i = 1; i <= otherCols; i++) {
    columnWidths[i] = const pw.FlexColumnWidth(1);
  }

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      pageFormat: pageFormat,
      build:
          (context) => [
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      schoolPhotoBytes != null
                          ? pw.Image(
                            pw.MemoryImage(schoolPhotoBytes),
                            width: 80,
                            height: 80,
                          )
                          : pw.SizedBox(),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (schoolName != null && schoolName.isNotEmpty)
                              pw.Text(
                                schoolName,
                                textAlign: pw.TextAlign.center,
                                softWrap: true,
                                style: pw.TextStyle(
                                  color: PdfColors.blue900,
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            if (schoolAddress != null &&
                                schoolAddress.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 6),
                                child: pw.Text(
                                  schoolAddress,
                                  textAlign: pw.TextAlign.center,
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.blue900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(),
                  pw.Text(
                    "Community Classification Report",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: pageFormat.availableWidth,
                    child: buildTable(
                      communities,
                      Map.fromEntries(sortedGroupedEntries),
                      normalizedStudents,
                      columnWidths,
                      headerTextStyle,
                      bodyTextStyle,
                      cellPadding,
                      rightCellPadding,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text("__________________"),
                          pw.Text(
                            "Principal",
                            style: pw.TextStyle(fontSize: 10),
                          ),
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

  return pdf;
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
      color: PdfColors.blue,
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
    if (name.trim().isEmpty) return ['', ''];
    final length = name.length;
    final mid = (length / 2).ceil();
    final part1 = name.substring(0, mid);
    final part2 = name.substring(mid);
    return [part1, part2];
  }

  // Build header rows and data rows
  final List<pw.TableRow> rows = [];

  // Header row 1 (community names)
  rows.add(
    pw.TableRow(
      decoration: pw.BoxDecoration(
        border: pw.Border.symmetric(horizontal: pw.BorderSide(width: 1)),
      ),
      children: [
        pw.Container(
          decoration: rightSideBorderDecoration(),
          alignment: pw.Alignment.center,
          padding: cellPadding,
          child: pw.Text(
            'Class',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        ...communities.expand((c) {
          final parts = splitCommunityName(c);
          return [
            pw.Container(
              decoration: pw.BoxDecoration(color: PdfColors.blue),
              alignment: pw.Alignment.centerRight,
              padding: cellPadding,
              child: pw.Text(
                parts[0],
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
              ),
              alignment: pw.Alignment.centerLeft,
              padding: rightCellPadding,
              child: pw.Text(
                parts[1].isEmpty ? '-' : parts[1],
                style: pw.TextStyle(
                  color: parts[1].isEmpty ? PdfColors.blue : PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        }),
        pw.Container(
          decoration: pw.BoxDecoration(color: PdfColors.blue),
          alignment: pw.Alignment.centerRight,
          padding: cellPadding,
          child: pw.Text(
            'Tot',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Container(
          decoration: pw.BoxDecoration(color: PdfColors.blue),
          alignment: pw.Alignment.centerLeft,
          padding: rightCellPadding,
          child: pw.Text(
            'al',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  // Header row 2 (M / F)
  rows.add(
    pw.TableRow(
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.blue,
            border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
          ),
          alignment: pw.Alignment.center,
          padding: cellPadding,
          child: pw.Text(
            '_',
            style: pw.TextStyle(
              color: PdfColors.blue,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        ...communities.expand((_) {
          return [
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
              ),
              alignment: pw.Alignment.center,
              padding: cellPadding,
              child: pw.Text('M', style: headerTextStyle),
            ),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
              ),
              alignment: pw.Alignment.center,
              padding: cellPadding,
              child: pw.Text('F', style: headerTextStyle),
            ),
          ];
        }),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.blue,
            border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
          ),
          alignment: pw.Alignment.center,
          padding: cellPadding,
          child: pw.Text('M', style: headerTextStyle),
        ),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.blue,
            border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
          ),
          alignment: pw.Alignment.center,
          padding: cellPadding,
          child: pw.Text('F', style: headerTextStyle),
        ),
      ],
    ),
  );

  // Data rows
  for (final entry in grouped.entries) {
    final classKey = entry.key;
    final classStudents = entry.value;

    final List<pw.Widget> rowCells = [
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
              .where(
                (s) =>
                    (s['community'] ?? '').toString() == c &&
                    (s['gender'] ?? '').toString().toUpperCase() == 'M',
              )
              .length;
      final femaleCount =
          classStudents
              .where(
                (s) =>
                    (s['community'] ?? '').toString() == c &&
                    (s['gender'] ?? '').toString().toUpperCase() == 'F',
              )
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

    final totalM =
        classStudents
            .where((s) => (s['gender'] ?? '').toString().toUpperCase() == 'M')
            .length;
    final totalF =
        classStudents
            .where((s) => (s['gender'] ?? '').toString().toUpperCase() == 'F')
            .length;

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

    rows.add(pw.TableRow(children: rowCells));
  }

  // Final TOTAL row (column-wise totals) — FIXED: use dark text color so it's visible on white bg
  final pw.TextStyle totalsVisibleStyle = headerTextStyle.copyWith(
    color: PdfColors.black,
  );

  rows.add(
    pw.TableRow(
      children: [
        pw.Container(
          decoration: rightLeftSideBorderDecoration(),
          alignment: pw.Alignment.center,
          padding: cellPadding,
          child: pw.Text('Total', style: totalsVisibleStyle),
        ),
        ...communities.expand((c) {
          final totalMale =
              students
                  .where(
                    (s) =>
                        (s['community'] ?? '').toString() == c &&
                        (s['gender'] ?? '').toString().toUpperCase() == 'M',
                  )
                  .length;
          final totalFemale =
              students
                  .where(
                    (s) =>
                        (s['community'] ?? '').toString() == c &&
                        (s['gender'] ?? '').toString().toUpperCase() == 'F',
                  )
                  .length;

          return [
            pw.Container(
              decoration: rightLeftSideBorderDecoration(),
              alignment: pw.Alignment.center,
              padding: cellPadding,
              child: pw.Text(
                totalMale == 0 ? '-' : totalMale.toString(),
                style: totalsVisibleStyle,
              ),
            ),
            pw.Container(
              decoration: rightLeftSideBorderDecoration(),
              alignment: pw.Alignment.center,
              padding: cellPadding,
              child: pw.Text(
                totalFemale == 0 ? '-' : totalFemale.toString(),
                style: totalsVisibleStyle,
              ),
            ),
          ];
        }),
        pw.Container(
          decoration: rightLeftSideBorderDecoration(),
          alignment: pw.Alignment.center,
          padding: cellPadding,
          child: pw.Text(
            students
                .where(
                  (s) => (s['gender'] ?? '').toString().toUpperCase() == 'M',
                )
                .length
                .toString(),
            style: totalsVisibleStyle,
          ),
        ),
        pw.Container(
          decoration: rightLeftSideBorderDecoration(),
          alignment: pw.Alignment.center,
          padding: cellPadding,
          child: pw.Text(
            students
                .where(
                  (s) => (s['gender'] ?? '').toString().toUpperCase() == 'F',
                )
                .length
                .toString(),
            style: totalsVisibleStyle,
          ),
        ),
      ],
    ),
  );

  return pw.Table(
    border: pw.TableBorder.symmetric(
      inside: pw.BorderSide.none,
      outside: pw.BorderSide(width: 1),
    ),
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    columnWidths: columnWidths,
    children: rows,
  );
}
