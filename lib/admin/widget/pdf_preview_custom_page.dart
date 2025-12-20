import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfPreviewCustomPage extends StatelessWidget {
  final Future<pw.Document> Function() buildPdf;
  final String title;
  final String fileName;
  const PdfPreviewCustomPage({
    super.key,
    required this.buildPdf,
    required this.title,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Color(0xFF2B7CA8);
    final Color backgroundCard = Colors.grey[50]!; // softer white

    return Scaffold(
      backgroundColor: themeColor.withValues(
        alpha: 0.95,
      ), // slightly transparent
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeColor,
        elevation: 4, // subtle shadow
        toolbarHeight: 60, // taller AppBar
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 480,
                ), // responsive max width
                decoration: BoxDecoration(
                  color: backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 12,
                ),
                padding: const EdgeInsets.all(16),
                child: PdfPreview(
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  build: (format) async => (await buildPdf()).save(),
                ),
              ),
            ),
          ),
          Container(
            color: themeColor,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: themeColor,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(
                    Icons.print,
                    size: 22,
                    color: Colors.black87,
                  ),
                  label: const Text(
                    "Print",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final pdfDoc = await buildPdf();
                    await Printing.layoutPdf(
                      onLayout: (format) async => pdfDoc.save(),
                    );
                  },
                ),
                const SizedBox(width: 24), // spacing between buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: themeColor,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(
                    Icons.share,
                    size: 22,
                    color: Colors.black87,
                  ),
                  label: const Text(
                    "Share",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final pdfDoc = await buildPdf();
                    await Printing.sharePdf(
                      bytes: await pdfDoc.save(),
                      filename: '$fileName.pdf',
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
