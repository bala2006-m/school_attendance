import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../../../services/api_service.dart';
import '../../../services/term_fee_structure_api.dart';
import '../../Appbar/student_appbar_desktop.dart';
import '../../Appbar/student_appbar_mobile.dart';
import '../student_dashboard.dart';
import './widgets/widget.dart';

class StudentFeesScreen extends StatefulWidget {
  final int schoolId;
  final int classId;
  final String username;

  const StudentFeesScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
  });

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _allFees = [];
  List<dynamic> _studentFees = [];
  late TabController _tabController;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  Map<String, dynamic> studentDetails = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
    fetchSchoolInfo();
    fetchStudentDetails();
  }

  Future<void> fetchStudentDetails() async {
    final data = await StudentApiServices.fetchStudentDataUsername(
      schoolId: widget.schoolId,
      username: widget.username,
    );
    if (data != null && mounted) {
      setState(() {
        studentDetails = data;
      });
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(
        widget.schoolId.toString(),
      );
      if (schoolData.isNotEmpty) {
        setState(() {
          schoolName = schoolData[0]['name'] ?? '';
          schoolAddress = schoolData[0]['address'] ?? '';
          if (schoolData[0]['photo'] != null) {
            schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load school info")),
        );
      }
    }
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);

    try {
      final studentFeeData = await TermFeeStructureApi.getStudentFeeByUsername(
        username: widget.username,
        schoolId: widget.schoolId,
        classId: widget.classId,
      );

      final feeStructures = await AdminApiService.getFeeStructuresByClass(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );

      setState(() {
        _studentFees = studentFeeData;
        _allFees = List<Map<String, dynamic>>.from(feeStructures);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load fees")));
      }
    }
  }

  Future<bool> onWillPop() async {
    StudentDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => StudentDashboard(
              username: widget.username,
              schoolId: widget.schoolId,
            ),
      ),
    );
    return false;
  }

  // Convert list to string for UI
  String _listToString(List<dynamic>? list) {
    if (list == null || list.isEmpty) return '-';
    return list.join(', ');
  }

  /// Get all payments of a fee structure for a student and SUM them
  double _totalPaidForFee(int feeId) {
    double totalPaid = 0.0;
    for (final rec in _studentFees) {
      if (rec["id"] == feeId) {
        totalPaid += (rec['paid_amount'] ?? 0).toDouble();
      }
    }
    return totalPaid;
  }

  /// Get single student fee record for UI (latest record)
  List? _studentFeeRecordByFeeId(int feeId) {
    try {
      final records = _studentFees.where((el) => el['id'] == feeId).toList();
      if (records.isEmpty) return null;

      records.sort(
        (a, b) => DateTime.parse(
          b['createdAt'],
        ).compareTo(DateTime.parse(a['createdAt'])),
      );
      return records;
    } catch (_) {
      return null;
    }
  }

  // ------------------ FIXED LOGIC ---------------------

  /// Pending = NOT fully paid
  List<Map<String, dynamic>> _pendingFees() {
    return _allFees.where((fee) {
      final feeId = fee['id'];
      final totalAmount = (fee['total_amount'] ?? 0).toDouble();
      final paid = _totalPaidForFee(feeId);

      if (paid >= totalAmount) return false; // fully paid

      return true; // unpaid or partial paid
    }).toList();
  }

  /// Completed = fully paid
  List<Map<String, dynamic>> _completedFees() {
    return _allFees.where((fee) {
      final feeId = fee['id'];
      final totalAmount = (fee['total_amount'] ?? 0).toDouble();
      final paid = _totalPaidForFee(feeId);

      return paid >= totalAmount; // fully paid
    }).toList();
  }

  // ----------------------------------------------------

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
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isMobile ? 240 : 240),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isMobile
                    ? StudentAppbarMobile(
                      schoolId: widget.schoolId,
                      username: widget.username,
                      title: 'Term Payments',
                      enableDrawer: false,
                      enableBack: true,
                      onBack: () => onWillPop(),
                    )
                    : StudentAppbarDesktop(
                      title: 'Term Payments',
                      enableDrawer: false,
                      enableBack: true,
                      onBack: () => onWillPop(),
                    ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.orangeAccent,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [Tab(text: 'Pending'), Tab(text: 'Completed')],
                  ),
                ),
              ],
            ),
          ),
          body:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      buildFeesList(
                        _pendingFees(),
                        isCompleted: false,
                        totalPaidForFee: _totalPaidForFee,
                        studentFeeRecordByFeeId: _studentFeeRecordByFeeId,
                        listToString: _listToString,
                        context: context,
                        schoolName: schoolName,
                        schoolPhotoBytes: schoolPhotoBytes,
                        schoolAddress: schoolAddress,
                        studentDetails: studentDetails,
                      ),
                      buildFeesList(
                        _completedFees(),
                        isCompleted: true,
                        totalPaidForFee: _totalPaidForFee,
                        studentFeeRecordByFeeId: _studentFeeRecordByFeeId,
                        listToString: _listToString,
                        context: context,
                        schoolName: schoolName,
                        schoolPhotoBytes: schoolPhotoBytes,
                        schoolAddress: schoolAddress,
                        studentDetails: studentDetails,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
