import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../pages/nominal_roles/student/build_student_list_excel.dart';
import 'pdf_preview_custom_page.dart';

class ExcelPreviewPage extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final String title;
  final String fileName;
  final Future<pw.Document> Function() buildPdf;

  const ExcelPreviewPage({
    super.key,
    required this.students,
    required this.title,
    required this.fileName,
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF2B7CA8);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    themeColor.withValues(alpha: 0.1),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'S.No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Admn.No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Gender',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Class',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Sec',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: List.generate(students.length, (index) {
                    final s = students[index];
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text('${s['username'] ?? ''}')),
                        DataCell(Text('${s['name'] ?? ''}')),
                        DataCell(
                          Text(
                            s['gender'] == 'M'
                                ? 'Male'
                                : (s['gender'] == 'F' ? 'Female' : 'Others'),
                          ),
                        ),
                        DataCell(Text('${s['class'] ?? ''}')),
                        DataCell(Text('${s['section'] ?? ''}')),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.print,
                  label: 'Print',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PdfPreviewCustomPage(
                              buildPdf: buildPdf,
                              title: title,
                              fileName: fileName,
                            ),
                      ),
                    );
                  },
                ),
                _ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onPressed: () async {
                    final path = await saveExcelFile(
                      students: students,
                      fileName: fileName,
                    );
                    if (Platform.isAndroid || Platform.isIOS) {
                      await Share.shareXFiles([
                        XFile(
                          path,
                          mimeType:
                              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        ),
                      ], text: 'Student List Excel');
                    }
                  },
                ),
                _ActionButton(
                  icon: Icons.open_in_new,
                  label: 'Open',
                  onPressed: () async {
                    final path = await saveExcelFile(
                      students: students,
                      fileName: fileName,
                    );
                    await OpenFilex.open(path);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF2B7CA8);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: themeColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }
}
