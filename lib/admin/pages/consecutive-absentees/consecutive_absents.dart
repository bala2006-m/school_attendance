import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/pdf_preview_custom_page.dart';
import '../dashboard/admin_dashboard.dart';
import 'build_consecutive_absentees_pdf.dart';
import 'consecutive_absents_classes.dart';

class ConsecutiveAbsents extends StatefulWidget {
  const ConsecutiveAbsents({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.className,
    required this.section,
  });

  final String schoolId;
  final String username;
  final String classId;
  final String className;
  final String section;

  @override
  State<ConsecutiveAbsents> createState() => _ConsecutiveAbsentsState();
}

class _ConsecutiveAbsentsState extends State<ConsecutiveAbsents> {
  final TextEditingController limitController = TextEditingController();
  List<dynamic> absentees = [];
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  bool isLoading = false;

  @override
  void initState() {
    fetchSchoolInfo();
    super.initState();
  }

  Future<void> init() async {
    if (limitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid limit'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      absentees = await AdminApiService.getConsecutiveAbsents(
        schoolId: int.parse(widget.schoolId),
        classId: int.parse(widget.classId),
        limit: int.parse(limitController.text),
      );

      if (absentees.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No absentees found for the given limit'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      await handleDownload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error generating PDF'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleDownload() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => buildPdf(
                    schoolPhotoBytes: schoolPhotoBytes,
                    schoolAddress: schoolAddress,
                    schoolName: schoolName,
                    absentees: absentees,
                  ),
              title: 'Long Absentees',
              fileName: 'long_absentees',
            ),
      ),
    );
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ConsecutiveAbsentsClasses(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Long Absentees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Long Absentees',
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Generate Consecutive Absentees Report',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1.2),

                  // Class Info Card
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Class:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                widget.className,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Section:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                widget.section,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Input Field
                  Text(
                    'Consecutive Days Limit',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    onChanged:
                        (_) => setState(() {}), // ✅ rebuilds when user types
                    decoration: InputDecoration(
                      hintText: 'Enter number of days',
                      prefixIcon: const Icon(Icons.timelapse_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          isLoading || limitController.text.isEmpty
                              ? null
                              : init,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLoading || limitController.text.isEmpty
                                ? Colors.grey
                                : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon:
                          isLoading
                              ? const SizedBox.shrink()
                              : const Icon(
                                Icons.picture_as_pdf_outlined,
                                color: Colors.white,
                              ),
                      label:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Generate PDF',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enter how many consecutive days a student has been absent to include them in the report.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
