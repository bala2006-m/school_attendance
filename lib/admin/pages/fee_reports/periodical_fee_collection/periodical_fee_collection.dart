import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../../services/api_service.dart';
import '../../../../services/term_fee_structure_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
import 'widget/build_periodical_fee_collection_pdf.dart';

class PeriodicalFeeCollection extends StatefulWidget {
  const PeriodicalFeeCollection({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.className,
    required this.section,
  });

  final String schoolId;
  final String classId;
  final String username;
  final String className;
  final String section;

  @override
  State<PeriodicalFeeCollection> createState() =>
      _PeriodicalFeeCollectionState();
}

class _PeriodicalFeeCollectionState extends State<PeriodicalFeeCollection> {
  bool isLoading = false;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  List<dynamic> paidFees = [];

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          try {
            schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
          } catch (e) {
            return;
          }
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<void> init() async {
    if (startDate == null || endDate == null) return;

    setState(() => isLoading = true);
    try {
      paidFees = await TermFeeStructureApi.getPeriodicalPaidFeesClass(
        schoolId: int.parse(widget.schoolId),
        startDate: startDate!,
        endDate: endDate!,
        classId: int.parse(widget.classId),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2024, 1),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
        endDate = null;
        paidFees.clear();
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the start date first.')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate!,
      firstDate: startDate!,
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
      await init();
    }
  }

  Future<void> handleBuild({required String title}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => buildPdf(
                    title: title,
                    fees: paidFees,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                  ),
              title: 'Fee Collection Report',
              fileName:
                  'fee_collection_${DateFormat('yyyyMMdd').format(startDate!)}_${DateFormat('yyyyMMdd').format(endDate!)}',
            ),
      ),
    );
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BuildClasses(
              schoolId: widget.schoolId,
              username: widget.username,
              title: 'Class List',
              onTap: ({
                required String schoolId,
                required String username,
                required String className,
                required String section,
                required String classId,
              }) {
                return PeriodicalFeeCollection(
                  schoolId: schoolId,
                  username: username,
                  className: className,
                  section: section,
                  classId: classId,
                );
              },

              onWillPop: AdminDashboard(
                schoolId: widget.schoolId,
                username: widget.username,
              ),
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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Periodical Fee Collection',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Periodical Fee Collection',
                    onBack: () {
                      onWillPop();
                    },
                  ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🏫 School Info
              if (schoolName != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: Colors.blueAccent,
                              size: 32,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                schoolName ?? 'Your School',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (schoolAddress != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            textAlign: TextAlign.center,
                            schoolAddress!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // 🗓 Start Date Button
              ElevatedButton.icon(
                onPressed: () => _pickStartDate(context),
                icon: Icon(Icons.date_range_rounded, color: Colors.white),
                label: Text(
                  startDate == null
                      ? 'Pick Start Date'
                      : 'Start: ${DateFormat('yyyy-MM-dd').format(startDate!)}',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🗓 End Date Button
              ElevatedButton.icon(
                onPressed:
                    startDate == null ? null : () => _pickEndDate(context),
                icon: Icon(
                  Icons.event_rounded,
                  color: startDate == null ? Colors.grey : Colors.white,
                ),
                label: Text(
                  endDate == null
                      ? 'Pick End Date'
                      : 'End: ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  backgroundColor:
                      startDate == null ? Colors.grey : Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🌀 Loading / Results
              if (isLoading)
                const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
              else if (startDate != null &&
                  endDate != null &&
                  paidFees.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    handleBuild(
                      title:
                          "Fee Collection ${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}",
                    );
                  },
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Generate PDF Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              else if (startDate != null && endDate != null && paidFees.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'No fees found for this period.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
