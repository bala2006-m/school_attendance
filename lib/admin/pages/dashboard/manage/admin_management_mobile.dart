import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/add_or_remove/add_or_remove_admin.dart';
import 'package:school_attendance/admin/pages/add_or_remove/add_or_remove_staff.dart';
import 'package:school_attendance/admin/pages/add_or_remove/bulk_upload/bulk_upload_register_student.dart';
import 'package:school_attendance/admin/pages/class_teacher/class_teacher_assign.dart';
import 'package:school_attendance/admin/pages/dashboard/admin_dashboard.dart';
import 'package:school_attendance/admin/pages/leave_request/view_leave_request.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/build_classes.dart';
import '../../../components/build_profile_card_desktop.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../access/admin_access/admin_access.dart';
import '../../access/staff_access/staff_access.dart';
import '../../accounts/drawing/drawing.dart';
import '../../accounts/expense/expense.dart';
import '../../accounts/finance/finance.dart';
import '../../accounts/income/income.dart';
import '../../add_or_remove/add_or_remove_class.dart';
import '../../add_or_remove/bulk_upload/bulk_upload_register_admin.dart';
import '../../add_or_remove/bulk_upload/bulk_upload_register_staff.dart';
import '../../add_or_remove/student/add_or_remove_class_list.dart';
import '../../app_payment/app_payment.dart';
import '../../bus_fees/activate/activate_bus_fees.dart';
import '../../bus_fees/add_bus_fees/add_bus_fees.dart';
import '../../bus_fees/collect_bus_fees/collect_bus_fees.dart';
import '../../bus_fees/view_status/view_bus_fee_status.dart';
import '../../bus_fees_reports/paid_fee_report/paid_fee_report.dart';
import '../../bus_fees_reports/pending_fee_report/pending_fee_report.dart';
import '../../bus_student_list/bus_student_list.dart';
import '../../collect_fees/collect_fees_classes.dart';
import '../../community_classification/community_classification.dart';
import '../../consecutive-absentees/consecutive_absents_classes.dart';
import '../../daily_absentees/daily_absentees.dart';
import '../../daily_report/daily_report.dart';
import '../../exam/exam_time_table.dart';
import '../../exam_mark_report/exam_mark_report_classes.dart';
import '../../exam_marks/exam_mark_classes.dart';
import '../../exam_reports/fail_reports/failed_reports.dart';
import '../../exam_reports/pass_reports/pass_reports.dart';
import '../../fee_reports/pending_fee_collection/pending_fee_collection.dart';
import '../../fee_reports/periodical_fee_collection/periodical_fee_collection.dart';
import '../../fee_reports/today_collection/today_collection.dart';
import '../../fee_reports/total_fee_collection/total_fee_collection.dart';
import '../../mark_sheet/mark_sheet_page.dart';
import '../../nominal_roles/admin/download_admin_nomial_role.dart';
import '../../nominal_roles/staff/download_staff_nomial_role.dart';
import '../../nominal_roles/student/download_student_nomial_role.dart';
import '../../print_certificates/student/periodically_attendance_report.dart';
import '../../rte_fee_reports/paid_report/paid_rte_report.dart';
import '../../rte_fee_reports/pending_report/pending_rte_report.dart';
import '../../rte_fees/activate/activate_rte_fees.dart';
import '../../rte_fees/add_rte_fees/add_rte_fees.dart';
import '../../rte_fees/collect_rte_fees/collect_rte_fees.dart';
import '../../rte_fees/status/rte_status.dart';
import '../../rte_students_report/rte_students_report.dart';
import '../../student_fees/admin_fee_structure_classes.dart';
import '../../student_fees/update_status/update_term_fee_status.dart';
import '../../student_fees/view_status/view_term_fee_status.dart';
import '../../students_access/student_access_management.dart';
import '../../teacher_access/teacher_access.dart';
import '../../time_table/timetable_class_list.dart';
import '../../upload_images/upload_images.dart';
import '../../view_profiles/admin/view_admin_profiles.dart';
import '../../view_profiles/staff/view_staff_profile.dart';
import '../../view_profiles/student/view_student_profile.dart';
import './post_tickets.dart';
import 'create_today_message.dart';
import 'mark_leave_list.dart';

class MenuButtonData {
  final String title;
  final Widget page;
  final IconData icon;
  final int index;
  final String category;

  MenuButtonData({
    required this.title,
    required this.page,
    required this.icon,
    required this.index,
    required this.category,
  });
}

class AdminManagementMobile extends StatefulWidget {
  final String adminUsername;
  final String schoolId;
  final String schoolName;
  final String schoolAddress;
  final Image? schoolPhoto;
  const AdminManagementMobile({
    super.key,
    required this.adminUsername,
    required this.schoolId,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
    this.adminAccess,
  });

  final Map<String, dynamic>? adminAccess;

  @override
  State<AdminManagementMobile> createState() => _AdminManagementMobileState();
}

class _AdminManagementMobileState extends State<AdminManagementMobile> {
  String adminName = '';
  String designation = '';
  Image? adminPhoto;
  bool isLoading = true;
  ScrollController _scrollController = ScrollController();
  static double savedScrollOffset = 0;
  static int? savedClickedButtonIndex;
  int? _clickedButtonIndex;

  final TextEditingController _searchController = TextEditingController();
  List<MenuButtonData> _allButtons = [];
  List<MenuButtonData> _allowedButtons = [];
  List<MenuButtonData> _filteredButtons = [];
  final Map<int, GlobalKey> _buttonKeys = {};
  final Map<int, FocusNode> _focusNodes = {};
  String _searchQuery = "";

  bool isRearrangeMode = false;
  List<String> _orderedCategories = [];
  Map<String, List<String>> _categoryButtonOrders = {};

  @override
  void initState() {
    super.initState();
    loadProfileData();
    _loadMenuOrder(); // load custom order and initialize buttons
    _scrollController = ScrollController(
      initialScrollOffset: savedScrollOffset,
    );
    _clickedButtonIndex = savedClickedButtonIndex;
  }

  Future<void> _loadMenuOrder() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Read the FULL maps from global cache
    final String? globalCatsJson = prefs.getString(
      'admin_global_categories_order_${widget.schoolId}',
    );
    final String? globalButtonsJson = prefs.getString(
      'admin_global_buttons_order_${widget.schoolId}',
    );

    setState(() {
      if (globalCatsJson != null) {
        final fullCats = Map<String, dynamic>.from(jsonDecode(globalCatsJson));
        if (fullCats.containsKey('manage')) {
          _orderedCategories = List<String>.from(fullCats['manage']);
        }
      }
      
      if (globalButtonsJson != null) {
        final fullButtons = Map<String, dynamic>.from(jsonDecode(globalButtonsJson));
        if (fullButtons.containsKey('manage')) {
          _categoryButtonOrders = Map<String, List<String>>.from(
            (fullButtons['manage'] as Map).map(
              (key, value) => MapEntry(key as String, List<String>.from(value)),
            ),
          );
        }
      }
      
      _initButtons();
      fetchMenuOrder(); // Fetch from DB and update cache/UI
    });
  }

  Future<void> fetchMenuOrder() async {
    try {
      final response = await AdminApiService.fetchAdminRearrange(
        schoolId: widget.schoolId,
        username: widget.adminUsername,
      );

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null) {
          final cats = data['categories'];
          final buttons = data['buttons'];

          bool updated = false;

          // Sync 'manage' section categories
          if (cats != null && cats['manage'] != null) {
            _orderedCategories = List<String>.from(cats['manage']);
            updated = true;
          }

          // Sync 'manage' section buttons
          if (buttons != null && buttons['manage'] != null) {
            _categoryButtonOrders = Map<String, List<String>>.from(
              (buttons['manage'] as Map).map(
                (key, value) => MapEntry(key as String, List<String>.from(value)),
              ),
            );
            updated = true;
          }

          if (updated) {
            if (mounted) {
              setState(() {
                _initButtons();
              });
            }
            // Update global cache with FULL maps from DB
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'admin_global_categories_order_${widget.schoolId}',
              jsonEncode(cats),
            );
            await prefs.setString(
              'admin_global_buttons_order_${widget.schoolId}',
              jsonEncode(buttons),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching menu order: $e");
    }
  }

  Future<void> _saveMenuOrder() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Read the FULL maps from global cache
    String? globalCatsJson = prefs.getString('admin_global_categories_order_${widget.schoolId}');
    String? globalButtonsJson = prefs.getString('admin_global_buttons_order_${widget.schoolId}');

    Map<String, dynamic> fullCats = {};
    Map<String, dynamic> fullButtons = {};

    if (globalCatsJson != null) {
      fullCats = Map<String, dynamic>.from(jsonDecode(globalCatsJson));
    }
    if (globalButtonsJson != null) {
      fullButtons = Map<String, dynamic>.from(jsonDecode(globalButtonsJson));
    }

    // 2. Update ONLY the current section ('manage') in the full maps
    fullCats['manage'] = _orderedCategories;
    fullButtons['manage'] = _categoryButtonOrders;

    // 3. Save the updated FULL maps back to global cache
    await prefs.setString(
      'admin_global_categories_order_${widget.schoolId}',
      jsonEncode(fullCats),
    );
    await prefs.setString(
      'admin_global_buttons_order_${widget.schoolId}',
      jsonEncode(fullButtons),
    );

    // 4. Send the FULL maps to the database
    await AdminApiService.updateRearrange(
      schoolId: int.parse(widget.schoolId),
      username: widget.adminUsername,
      cats: fullCats,
      buttons: fullButtons,
    );
  }

  @override
  void didUpdateWidget(covariant AdminManagementMobile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adminAccess != oldWidget.adminAccess) {
      _initButtons();
    }
  }

  final Map<String, String> _categoryAccessKey = {
    "Collect Fees": "collectFees",
    "Manage": "manage",
    "Access": "access",
    "Exam": "exam",
    "Term Fees": "termFees",
    "Bus Fees": "busFees",
    "RTE Fees": "rteFees",
    "Account": "account",
    "Services": "services",
    "Bulk Upload": "bulkUpload",
    "View Profiles": "viewProfiles",
    "Reports": "reports",
  };

  bool hasAccess(String title) {
    final access = widget.adminAccess;
    return access != null && access[title] == true;
  }

  void _initButtons() {
    _allButtons = [
      // Manage
      MenuButtonData(
        title: "Message",
        page: CreateTodayMessage(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.message,
        index: 0,
        category: "Manage",
      ),
      MenuButtonData(
        title: "Admin",
        page: AddOrRemoveAdmin(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.admin_panel_settings,
        index: 1,
        category: "Manage",
      ),
      MenuButtonData(
        title: "Staff",
        page: AddOrRemoveStaff(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.person_add_alt_1_outlined,
        index: 2,
        category: "Manage",
      ),
      MenuButtonData(
        title: "Student",
        page: AddOrRemoveClassList(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people_alt_outlined,
        index: 3,
        category: "Manage",
      ),
      MenuButtonData(
        title: "Class",
        page: ClassRegistration(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.class_,
        index: 4,
        category: "Manage",
      ),
      MenuButtonData(
        title: "Holiday",
        page: MarkLeaveList(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.calendar_month,
        index: 5,
        category: "Manage",
      ),
      MenuButtonData(
        title: "TimeTable",
        page: TimetableClassList(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people_alt_outlined,
        index: 6,
        category: "Manage",
      ),

      MenuButtonData(
        title: "Post Events",
        page: UploadImagesVideos(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.event,
        index: 7,
        category: "Manage",
      ),
      MenuButtonData(
        title: "Time Table",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return ExamTimeTableScreen(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.event,
        index: 8,
        category: "Exam",
      ),
      MenuButtonData(
        title: "Mark Sheet",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return EditableMarksheet(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.event,
        index: 9,
        category: "Exam",
      ),
      MenuButtonData(
        title: "Activate\nProgress\nCard",
        page: ExamMarkClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.collections_bookmark_outlined,
        index: 10,
        category: "Exam",
      ),

      MenuButtonData(
        title: "Admins",
        page: AdminAccess(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.admin_panel_settings_outlined,
        index: 11,
        category: "Access",
      ),
      MenuButtonData(
        title: "Staffs",
        page: StaffAccess(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people_outline,
        index: 12,
        category: "Access",
      ),
      MenuButtonData(
        title: "Teachers",
        page: TeacherAccess(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.assignment_add,
        index: 13,
        category: "Access",
      ),

      MenuButtonData(
        title: "Class Teachers\nAssign",
        page: ClassTeacherAssign(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.assignment_ind,
        index: 14,
        category: "Access",
      ),
      MenuButtonData(
        title: "Students",
        page: StudentAccessManagement(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.assignment_add,
        index: 15,
        category: "Access",
      ),
      // Term Fees
      MenuButtonData(
        title: "Add Term \nFees",
        page: AdminFeeStructureClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.feed,
        index: 16,
        category: "Term Fees",
      ),
      MenuButtonData(
        title: "Activate\nTerm Fees",
        page: UpdateTermFeeStatus(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.update,
        index: 17,
        category: "Term Fees",
      ),
      MenuButtonData(
        title: "Total Fee\nCollected",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return TotalFeeCollection(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.add,
        index: 18,
        category: "Term Fees",
      ),
      MenuButtonData(
        title: "Periodical\nFee\nCollection",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
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
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.select_all,
        index: 19,
        category: "Term Fees",
      ),
      MenuButtonData(
        title: "Pending Fee\nList",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return PendingFeeCollection(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.pending,
        index: 20,
        category: "Term Fees",
      ),
      MenuButtonData(
        title: "View\nStatus",
        page: ViewTermFeeStatus(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.analytics,
        index: 21,
        category: "Term Fees",
      ),

      // Collect Fees
      MenuButtonData(
        title: "Term Fees",
        page: CollectFeesClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.collections_bookmark,
        index: 22,
        category: "Collect Fees",
      ),
      MenuButtonData(
        title: "Bus Fees",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return CollectBusFees(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.generating_tokens,
        index: 23,
        category: "Collect Fees",
      ),
      MenuButtonData(
        title: "RTE Fees",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return CollectRteFees(
              schoolId: int.parse(schoolId),
              username: username,
              className: className,
              section: section,
              classId: int.parse(classId),
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.generating_tokens,
        index: 24,
        category: "Collect Fees",
      ),

      // Bus Fees
      MenuButtonData(
        title: "Add Bus\nFees",
        page: AddBusFees(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.bus_alert,
        index: 25,
        category: "Bus Fees",
      ),
      MenuButtonData(
        title: "Activate\nBus Fees",
        page: ActivateBusFees(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.update,
        index: 26,
        category: "Bus Fees",
      ),
      MenuButtonData(
        title: "Pending Fee\nList",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return PendingFeeReport(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.pending,
        index: 27,
        category: "Bus Fees",
      ),
      MenuButtonData(
        title: "Paid Fee\nList",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return PaidFeeReport(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.currency_rupee,
        index: 28,
        category: "Bus Fees",
      ),
      MenuButtonData(
        title: "View\nStatus",
        page: ViewBusFeeStatus(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.analytics,
        index: 29,
        category: "Bus Fees",
      ),

      // RTE Fees
      MenuButtonData(
        title: "Add RTE\nFees",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return AdminRteFeeStructureScreen(
              schoolId: int.parse(schoolId),
              username: username,
              className: className,
              section: section,
              classId: int.parse(classId),
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.rtt,
        index: 30,
        category: "RTE Fees",
      ),
      MenuButtonData(
        title: "Activate\nRTE Fees",
        page: ActivateRteFees(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.update,
        index: 31,
        category: "RTE Fees",
      ),
      MenuButtonData(
        title: "Pending RTE\nList",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return PendingRteReport(
              schoolId: int.parse(schoolId),
              username: username,
              className: className,
              section: section,
              classId: int.parse(classId),
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.pending,
        index: 32,
        category: "RTE Fees",
      ),
      MenuButtonData(
        title: "Paid RTE\nList",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return PaidRteReport(
              schoolId: int.parse(schoolId),
              username: username,
              className: className,
              section: section,
              classId: int.parse(classId),
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.currency_rupee,
        index: 33,
        category: "RTE Fees",
      ),
      MenuButtonData(
        title: "View\nStatus",
        page: RteStatus(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.analytics,
        index: 34,
        category: "RTE Fees",
      ),

      // Account
      MenuButtonData(
        title: "Daily\nCollected",
        page: BuildClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
          title: 'Class List',
          onTap: ({
            required String schoolId,
            required String username,
            required String className,
            required String section,
            required String classId,
          }) {
            return TodayCollectionOptionB(
              schoolId: schoolId,
              username: username,
              className: className,
              section: section,
              classId: classId,
            );
          },
          onWillPop: AdminDashboard(
            schoolId: widget.schoolId,
            username: widget.adminUsername,
          ),
        ),
        icon: Icons.today,
        index: 35,
        category: "Account",
      ),
      MenuButtonData(
        title: "Income",
        page: Income(schoolId: widget.schoolId, username: widget.adminUsername),
        icon: Icons.money,
        index: 36,
        category: "Account",
      ),
      MenuButtonData(
        title: "Expense",
        page: Expense(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.outbond_outlined,
        index: 37,
        category: "Account",
      ),
      MenuButtonData(
        title: "Drawing",
        page: Drawing(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.drive_folder_upload,
        index: 38,
        category: "Account",
      ),
      MenuButtonData(
        title: "Finance",
        page: Finance(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.analytics,
        index: 39,
        category: "Account",
      ),

      // Services
      MenuButtonData(
        title: "View Leave\nRequest",
        page: ViewLeaveRequest(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.remove_from_queue,
        index: 40,
        category: "Services",
      ),
      MenuButtonData(
        title: "Submit\nTicket",
        page: PostTickets(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.feed,
        index: 41,
        category: "Services",
      ),
      MenuButtonData(
        title: "App\nPayment",
        page: AppPayment(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.payment,
        index: 42,
        category: "Services",
      ),

      // Bulk Upload
      MenuButtonData(
        title: "Admin\nUpload",
        page: BulkUploadRegisterAdmin(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.remove_from_queue,
        index: 43,
        category: "Bulk Upload",
      ),
      MenuButtonData(
        title: "Staff\nUpload",
        page: BulkUploadRegisterStaff(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.remove_from_queue,
        index: 44,
        category: "Bulk Upload",
      ),
      MenuButtonData(
        title: "Student\nUpload",
        page: BulkUploadRegisterStudent(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.remove_from_queue,
        index: 45,
        category: "Bulk Upload",
      ),

      // View Profiles
      MenuButtonData(
        title: "Admin",
        page: ViewAdminProfile(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.admin_panel_settings_outlined,
        index: 46,
        category: "View Profiles",
      ),
      MenuButtonData(
        title: "Staff",
        page: ViewStaffProfile(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.person,
        index: 47,
        category: "View Profiles",
      ),
      MenuButtonData(
        title: "Student",
        page: ViewStudentProfile(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people,
        index: 48,
        category: "View Profiles",
      ),

      // Reports
      MenuButtonData(
        title: "Admin\nLists",
        page: DownloadAdminNomialRole(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.admin_panel_settings_outlined,
        index: 49,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Staff\nLists",
        page: DownloadStaffNominalRole(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.person,
        index: 50,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Student\nLists",
        page: DownloadStudentNomialRole(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people,
        index: 51,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Community\nClustering",
        page: CommunityClassification(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.bar_chart_sharp,
        index: 52,
        category: "Reports",
      ),
      MenuButtonData(
        title: "RTE\nStudents",
        page: RteStudentsReport(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.rate_review,
        index: 53,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Bus Going\nStudents",
        page: BusStudentList(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.bus_alert,
        index: 54,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Periodical\nAttendance",
        page: PeriodicallyAttendanceReport(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people,
        index: 55,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Daily\nAttendance\nSummary",
        page: DailyReport(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.calendar_view_day,
        index: 56,
        category: "Reports",
      ),

      MenuButtonData(
        title: "Daily\nAbsentees",
        page: DailyAbsentees(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.bar_chart_sharp,
        index: 57,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Long\nAbsentees",
        page: ConsecutiveAbsentsClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.highlight_remove,
        index: 58,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Exam\nMark",
        page: ExamMarkReportClasses(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.report,
        index: 59,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Pass",
        page: PassReports(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.done_all,
        index: 60,
        category: "Reports",
      ),
      MenuButtonData(
        title: "Failed",
        page: FailedReports(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.sms_failed,
        index: 61,
        category: "Reports",
      ),
    ];

    // Initialize keys and focus nodes for each button
    _buttonKeys.clear();
    _focusNodes.clear();
    for (var btn in _allButtons) {
      _buttonKeys[btn.index] = GlobalKey();
      _focusNodes[btn.index] = FocusNode();
    }

    final access = widget.adminAccess;

    // If access not loaded yet → show nothing
    if (access == null) {
      _filteredButtons = [];
      return;
    }

    // Filter buttons based on category access
    _allowedButtons =
        _allButtons.where((button) {
          final accessKey = _categoryAccessKey[button.category];

          // If category not mapped, hide it
          if (accessKey == null) return false;

          // Show only if access true
          return access[accessKey] == true;
        }).toList();

    // Initialize default orders if empty
    if (_orderedCategories.isEmpty) {
      _orderedCategories =
          _allowedButtons.map((e) => e.category).toSet().toList();
    }

    // Ensure all categories have a button order
    for (var cat in _orderedCategories) {
      if (!_categoryButtonOrders.containsKey(cat) ||
          _categoryButtonOrders[cat]!.isEmpty) {
        _categoryButtonOrders[cat] =
            _allowedButtons
                .where((b) => b.category == cat)
                .map((b) => b.title)
                .toList();
      }
    }

    _filteredButtons = List.from(_allowedButtons);
  }

  @override
  void dispose() {
    // Save scroll position only if attached
    if (_scrollController.hasClients) {
      savedScrollOffset = _scrollController.offset;
    }
    savedClickedButtonIndex = _clickedButtonIndex;

    // Dispose focus nodes
    for (var node in _focusNodes.values) {
      node.dispose();
    }

    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToFocusedButton() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Give the view a moment to attach the controller and layout children
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      // 2. Try to jump to the saved offset directly (fastest)
      if (_scrollController.hasClients) {
        try {
          _scrollController.jumpTo(savedScrollOffset);
        } catch (e) {
          debugPrint("Jump error: $e");
        }
      }

      // 3. Wait slightly more for items to be fully rendered
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      // 4. Use ensureVisible to refine the scroll position and pull the button into view
      if (savedClickedButtonIndex != null &&
          _buttonKeys.containsKey(savedClickedButtonIndex)) {
        final key = _buttonKeys[savedClickedButtonIndex];
        final node = _focusNodes[savedClickedButtonIndex];

        if (key?.currentContext != null) {
          await Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
          // 5. Finally, request focus
          node?.requestFocus();
        }
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredButtons = List.from(_allowedButtons);
      } else {
        _filteredButtons =
            _allowedButtons.where((button) {
              return button.title.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> loadProfileData() async {
    try {
      final adminData = await AdminApiService.fetchAdminData(
        username: widget.adminUsername,
        schoolId: widget.schoolId,
      );
      setState(() {
        adminName = adminData?['name'] ?? '';
        designation = adminData?['designation'] ?? '';
        if (adminData?['photo'] != null) {
          Uint8List imageBytes = base64Decode(adminData?['photo']);
          adminPhoto = Image.memory(imageBytes);
        }
        isLoading = false;
      });

      if (savedClickedButtonIndex != null) {
        _scrollToFocusedButton();
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body:
          isLoading
              ? SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0)
              : SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MediaQuery.of(context).size.width > 600
                        ? BuildProfileCardDesktop.buildProfileCardDesktop(
                          adminName: adminName,
                          adminDesignation: designation,
                          adminPhoto: adminPhoto,
                          schoolAddress: widget.schoolAddress,
                          schoolName: widget.schoolName,
                        )
                        : BuildProfileCard(
                          schoolPhoto: widget.schoolPhoto,
                          schoolAddress: widget.schoolAddress,
                          schoolName: widget.schoolName,
                        ),
                    const SizedBox(height: 20),

                    // Rearrange Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isRearrangeMode = !isRearrangeMode;
                                if (!isRearrangeMode) {
                                  _saveMenuOrder();
                                }
                              });
                            },
                            icon: Icon(
                              isRearrangeMode ? Icons.save : Icons.reorder,
                              color: Colors.white,
                            ),
                            label: Text(
                              isRearrangeMode ? "Save Layout" : "Rearrange",
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isRearrangeMode
                                      ? Colors.green
                                      : Colors.blue.shade900,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Search Bar
                    if (!isRearrangeMode)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search buttons...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.blue.shade900,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 20,
                            ),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                    : null,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Dynamic Content
                    if (_searchQuery.isEmpty)
                      if (isRearrangeMode)
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: _onCategoryReorder,
                          children: _buildAllCategories(),
                        )
                      else
                        Column(children: _buildAllCategories())
                    else
                      Column(children: _buildSearchResults()),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
    );
  }

  void _onCategoryReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _orderedCategories.removeAt(oldIndex);
      _orderedCategories.insert(newIndex, item);
      _saveMenuOrder(); // Save changes immediately
    });
  }

  List<Widget> _buildAllCategories() {
    return _orderedCategories.where((category) {
      return _allowedButtons.any((b) => b.category == category);
    }).map((category) {
      final buttons =
          _allowedButtons.where((b) => b.category == category).toList();

      // Order buttons within the category if custom order exists
      if (_categoryButtonOrders.containsKey(category)) {
        final order = _categoryButtonOrders[category]!;
        buttons.sort((a, b) {
          int indexA = order.indexOf(a.title);
          int indexB = order.indexOf(b.title);
          if (indexA == -1) indexA = 999;
          if (indexB == -1) indexB = 999;
          return indexA.compareTo(indexB);
        });
      }

      return Column(
        key: ValueKey(category),
        children: [
          _buildCategoryContainer(category, buttons),
          const SizedBox(height: 30),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSearchResults() {
    // Group search results by category for better context, or just show them.
    // Let's show them grouped by category to maintain context.

    final categories = _filteredButtons.map((e) => e.category).toSet().toList();

    if (_filteredButtons.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No buttons found matching '$_searchQuery'",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ];
    }

    return categories.map((category) {
      final buttons =
          _filteredButtons.where((b) => b.category == category).toList();
      return Column(
        children: [
          _buildCategoryContainer(category, buttons),
          const SizedBox(height: 30),
        ],
      );
    }).toList();
  }

  Widget _buildCategoryContainer(String title, List<MenuButtonData> buttons) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black26, width: 2),
        boxShadow: const [BoxShadow(color: Colors.transparent)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.blue.shade900,
                    size: 50,
                  ),
                ],
              ),
            ),

            // Grid or List of buttons
            isRearrangeMode
                ? SizedBox(
                  height: 170,
                  child: ReorderableListView(
                    scrollDirection: Axis.horizontal,
                    onReorder:
                        (oldIndex, newIndex) =>
                            _onButtonReorder(title, oldIndex, newIndex),
                    children:
                        buttons.map((data) {
                          return Container(
                            key: ValueKey("${title}_${data.title}"),
                            child: buildElevatedButton(
                              context,
                              data.title,
                              data.page,
                              data.icon,
                              buttonIndex: data.index,
                            ),
                          );
                        }).toList(),
                  ),
                )
                : Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  alignment: WrapAlignment.center,
                  children:
                      buttons.map((data) {
                        return buildElevatedButton(
                          context,
                          data.title,
                          data.page,
                          data.icon,
                          buttonIndex: data.index,
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }

  void _onButtonReorder(String category, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final List<String> order = List<String>.from(
        _categoryButtonOrders[category] ?? [],
      );
      if (order.isEmpty) {
        // Fallback to current button list
        final currentButtons =
            _allowedButtons.where((b) => b.category == category).toList();
        order.addAll(currentButtons.map((b) => b.title));
      }
      final String item = order.removeAt(oldIndex);
      order.insert(newIndex, item);
      _categoryButtonOrders[category] = order;

      // Re-initialize buttons to reflect the new order immediately
      _initButtons();
      _saveMenuOrder(); // Save changes immediately
    });
  }

  Widget buildElevatedButton(
    BuildContext context,
    String text,
    Widget page,
    IconData icon, {
    required int buttonIndex,
  }) {
    bool isClicked = _clickedButtonIndex == buttonIndex;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.22,
          minWidth: MediaQuery.of(context).size.width / 4.5,
          maxWidth: MediaQuery.of(context).size.width / 4.5,
        ),
        child: Container(
          key: _buttonKeys[buttonIndex],
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                focusNode: _focusNodes[buttonIndex],
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isClicked ? Colors.cyan.shade800 : Colors.cyan,
                  minimumSize: Size(
                    MediaQuery.of(context).size.width / 4.5,
                    MediaQuery.of(context).size.height * 0.09,
                  ),
                  maximumSize: Size(
                    MediaQuery.of(context).size.width / 4.5,
                    MediaQuery.of(context).size.height * 0.09,
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                  shadowColor: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _clickedButtonIndex = buttonIndex;
                  });

                  // Save scroll position and clicked button before navigating
                  savedScrollOffset = _scrollController.offset;
                  savedClickedButtonIndex = buttonIndex;

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => page),
                  );
                },
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                textAlign: TextAlign.center,
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
