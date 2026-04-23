import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:school_attendance/admin/pages/staff_attendance/staff_absentees.dart';
import 'package:school_attendance/admin/pages/staff_attendance/staff_attendance.dart';
import 'package:school_attendance/admin/pages/staff_attendance/view_staff_attendance.dart';
import 'package:school_attendance/admin/pages/student_attendance/periodicalReport/student_report_between_days.dart';
import 'package:school_attendance/admin/pages/student_attendance/viewAbsentees/student_absentees.dart';
import 'package:school_attendance/admin/pages/student_attendance/viewAttendance/view_student_attendance.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/build_profile_card_desktop.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../student_attendance/mark_old_attendance/mark_old_attendance.dart';
import '../../student_attendance/monthelyAttendance/monthly_attendance.dart';
import '../../student_attendance/update_attendance/modify_student_attendance.dart';

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

class AdminStudentMobile extends StatefulWidget {
  final String schoolId;
  final String adminUsername;
  final String adminName;
  final String adminDesignation;
  final Image? adminPhoto;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;

  const AdminStudentMobile({
    super.key,
    required this.schoolId,
    required this.adminUsername,
    required this.adminName,
    required this.adminDesignation,
    this.adminPhoto,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
    this.adminAccess,
  });

  final Map<String, dynamic>? adminAccess;

  @override
  State<AdminStudentMobile> createState() => _AdminStudentMobileState();
}

class _AdminStudentMobileState extends State<AdminStudentMobile> {
  ScrollController _scrollController = ScrollController();
  static double savedScrollOffset = 0;
  static int? savedClickedButtonIndex;
  int? _clickedButtonIndex;

  bool isRearrangeMode = false;
  List<String> _orderedCategories = [];
  Map<String, List<String>> _categoryButtonOrders = {};

  List<MenuButtonData> _allButtons = [];
  List<MenuButtonData> _allowedButtons = [];
  final Map<int, GlobalKey> _buttonKeys = {};
  final Map<int, FocusNode> _focusNodes = {};

  bool _isMenuOrderLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMenuOrder();
    _scrollController = ScrollController(
      initialScrollOffset: savedScrollOffset,
    );
    _clickedButtonIndex = savedClickedButtonIndex;
  }

  Future<void> _loadMenuOrder() async {
    final prefs = await SharedPreferences.getInstance();

    final String? globalCatsJson = prefs.getString(
      'admin_global_categories_order_${widget.schoolId}',
    );
    final String? globalButtonsJson = prefs.getString(
      'admin_global_buttons_order_${widget.schoolId}',
    );

    setState(() {
      if (globalCatsJson != null) {
        final fullCats = Map<String, dynamic>.from(jsonDecode(globalCatsJson));
        if (fullCats.containsKey('student')) {
          _orderedCategories = List<String>.from(fullCats['student']);
        }
      }

      if (globalButtonsJson != null) {
        final fullButtons = Map<String, dynamic>.from(
          jsonDecode(globalButtonsJson),
        );
        if (fullButtons.containsKey('student')) {
          _categoryButtonOrders = Map<String, List<String>>.from(
            (fullButtons['student'] as Map).map(
              (key, value) => MapEntry(key as String, List<String>.from(value)),
            ),
          );
        }
      }

      _initButtons();
    });

    await fetchMenuOrder();
    setState(() => _isMenuOrderLoaded = true);
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

          if (cats != null && cats['student'] != null) {
            _orderedCategories = List<String>.from(cats['student']);
            updated = true;
          }

          if (buttons != null && buttons['student'] != null) {
            _categoryButtonOrders = Map<String, List<String>>.from(
              (buttons['student'] as Map).map(
                (key, value) =>
                    MapEntry(key as String, List<String>.from(value)),
              ),
            );
            updated = true;
          }

          if (updated) {
            setState(() {
              _initButtons();
            });
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

    String? globalCatsJson = prefs.getString(
      'admin_global_categories_order_${widget.schoolId}',
    );
    String? globalButtonsJson = prefs.getString(
      'admin_global_buttons_order_${widget.schoolId}',
    );

    Map<String, dynamic> fullCats = {};
    Map<String, dynamic> fullButtons = {};

    if (globalCatsJson != null) {
      fullCats = Map<String, dynamic>.from(jsonDecode(globalCatsJson));
    }
    if (globalButtonsJson != null) {
      fullButtons = Map<String, dynamic>.from(jsonDecode(globalButtonsJson));
    }

    fullCats['student'] = _orderedCategories;
    fullButtons['student'] = _categoryButtonOrders;

    await prefs.setString(
      'admin_global_categories_order_${widget.schoolId}',
      jsonEncode(fullCats),
    );
    await prefs.setString(
      'admin_global_buttons_order_${widget.schoolId}',
      jsonEncode(fullButtons),
    );

    await AdminApiService.updateRearrange(
      schoolId: int.parse(widget.schoolId),
      username: widget.adminUsername,
      cats: fullCats,
      buttons: fullButtons,
    );
  }

  @override
  void didUpdateWidget(covariant AdminStudentMobile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adminAccess != oldWidget.adminAccess) {
      setState(() {
        _initButtons();
      });
    }
  }

  void _initButtons() {
    _allButtons = [
      MenuButtonData(
        title: 'Mark Attendance',
        page: StaffAttendance(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people,
        index: 0,
        category: 'Staff',
      ),
      MenuButtonData(
        title: 'View Absentees',
        page: StaffAbsentees(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people_outline,
        index: 1,
        category: 'Staff',
      ),
      MenuButtonData(
        title: 'View Attendance',
        page: ViewStaffAttendance(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.people_outline_outlined,
        index: 2,
        category: 'Staff',
      ),
      MenuButtonData(
        title: 'Update Attendance',
        page: ModifyStudentAttendance(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.mode,
        index: 3,
        category: 'Student',
      ),
      MenuButtonData(
        title: 'View Absentees',
        page: StudentAbsent(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.person_remove,
        index: 4,
        category: 'Student',
      ),
      MenuButtonData(
        title: 'View Attendance',
        page: ClassList(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.person_search,
        index: 5,
        category: 'Student',
      ),
      MenuButtonData(
        title: 'Monthly Attendance',
        page: MonthlyAttendance(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.calendar_month,
        index: 6,
        category: 'Student',
      ),
      MenuButtonData(
        title: 'Periodical Attendance',
        page: StudentReportBetweenDays(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.report,
        index: 7,
        category: 'Student',
      ),
      MenuButtonData(
        title: 'Mark Attendance',
        page: MarkOldAttendance(
          schoolId: widget.schoolId,
          username: widget.adminUsername,
        ),
        icon: Icons.mode_edit_outlined,
        index: 8,
        category: 'Student',
      ),
    ];

    _buttonKeys.clear();
    _focusNodes.clear();
    for (var btn in _allButtons) {
      _buttonKeys[btn.index] = GlobalKey();
      _focusNodes[btn.index] = FocusNode();
    }

    _allowedButtons =
        _allButtons.where((btn) {
          if (btn.category == 'Staff') return hasStaffAccess;
          if (btn.category == 'Student') return hasStudentAccess;
          return false;
        }).toList();

    // Set default category order if none exists
    if (_orderedCategories.isEmpty) {
      if (hasStaffAccess && hasStudentAccess) {
        _orderedCategories = ['Student', 'Staff'];
      } else if (hasStudentAccess) {
        _orderedCategories = ['Student'];
      } else if (hasStaffAccess) {
        _orderedCategories = ['Staff'];
      }
    }

    for (var cat in _orderedCategories) {
      final List<String> currentButtonTitles =
          _allowedButtons
              .where((b) => b.category == cat)
              .map((b) => b.title)
              .toList();

      if (!_categoryButtonOrders.containsKey(cat) ||
          _categoryButtonOrders[cat]!.isEmpty) {
        _categoryButtonOrders[cat] = currentButtonTitles;
      } else {
        final existingOrder = _categoryButtonOrders[cat]!;
        for (var title in currentButtonTitles) {
          if (!existingOrder.contains(title)) {
            existingOrder.add(title);
          }
        }
        existingOrder.removeWhere(
          (title) => !currentButtonTitles.contains(title),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      savedScrollOffset = _scrollController.offset;
    }
    savedClickedButtonIndex = _clickedButtonIndex;
    _scrollController.dispose();
    super.dispose();
  }

  bool get hasStaffAccess {
    final access = widget.adminAccess;
    return access != null &&
        (access['staff'] == true ||
            access['staff'] == "true" ||
            access['staff'] == 1 ||
            access['staff'] == "1");
  }

  bool get hasStudentAccess {
    final access = widget.adminAccess;
    return access != null &&
        (access['student'] == true ||
            access['student'] == "true" ||
            access['student'] == 1 ||
            access['student'] == "1");
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMenuOrderLoaded) {
      return Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return buildMainUI(context);
  }

  Widget buildMainUI(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final profileCard =
        screenWidth > 600
            ? BuildProfileCardDesktop.buildProfileCardDesktop(
              adminName: widget.adminName,
              adminDesignation: widget.adminDesignation,
              adminPhoto: widget.adminPhoto,
              schoolAddress: widget.schoolAddress,
              schoolName: widget.schoolName,
            )
            : BuildProfileCard(
              schoolPhoto: widget.schoolPhoto,
              schoolAddress: widget.schoolAddress,
              schoolName: widget.schoolName,
            );

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        controller: _scrollController,

        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profileCard,
              SizedBox(height: screenHeight * 0.03),

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
              const SizedBox(height: 20),

              // Dynamic Content
              if (isRearrangeMode)
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: _onCategoryReorder,
                  children: _buildAllCategories(),
                )
              else
                Column(children: _buildAllCategories()),

              const SizedBox(height: 30),
            ],
          ),
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
    return _orderedCategories
        .where((category) {
          return _allowedButtons.any((b) => b.category == category);
        })
        .map((category) {
          final buttons =
              _allowedButtons.where((b) => b.category == category).toList();

          // Order buttons within category
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
        })
        .toList();
  }

  Widget _buildCategoryContainer(String title, List<MenuButtonData> buttons) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black26, width: 2),
        boxShadow: const [BoxShadow(color: Colors.transparent)],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                            buttons
                                .map((data) {
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
                                })
                                .toList()
                                .cast<Widget>(),
                      ),
                    )
                    : Wrap(
                      spacing: 0,
                      runSpacing: 0,
                      alignment: WrapAlignment.center,
                      children:
                          buttons
                              .map((data) {
                                return buildElevatedButton(
                                  context,
                                  data.title,
                                  data.page,
                                  data.icon,
                                  buttonIndex: data.index,
                                );
                              })
                              .toList()
                              .cast<Widget>(),
                    ),
              ],
            ),
          ),
        ],
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
        final List<MenuButtonData> currentButtons =
            _allowedButtons.where((b) => b.category == category).toList();
        order.addAll(currentButtons.map((b) => b.title));
      }
      final String item = order.removeAt(oldIndex);
      order.insert(newIndex, item);
      _categoryButtonOrders[category] = order;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isClicked ? Colors.cyan.shade800 : Colors.cyan,
                minimumSize: Size(
                  MediaQuery.of(context).size.width / 4.5,
                  MediaQuery.of(context).size.height * 0.09,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: () {
                setState(() {
                  _clickedButtonIndex = buttonIndex;
                });
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
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
