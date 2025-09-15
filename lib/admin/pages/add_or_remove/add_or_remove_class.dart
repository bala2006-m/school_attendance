import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/services/api_service.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import '../dashboard/admin_dashboard.dart';

class ClassRegistration extends StatefulWidget {
  final String schoolId;
  final String username;
  const ClassRegistration({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<ClassRegistration> createState() => _ClassRegistrationState();
}

class _ClassRegistrationState extends State<ClassRegistration> {
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final FocusNode _classFocus = FocusNode();
  final GlobalKey _formKey1 = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isFormValid = false;
  bool _isFetchingClasses = false;
  bool _isSubmitting = false;
  bool showForm = false;

  List<Map<String, dynamic>> classes = [];

  // Field errors map
  Map<String, String?> fieldErrors = {'class': null, 'section': null};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _classFocus.requestFocus();
    });
    init();
  }

  void _checkFormValidity() {
    final classValue = _classController.text.trim();
    final sectionValue = _sectionController.text.trim();

    String? classError;
    String? sectionError;

    // Class validation
    if (classValue.isEmpty) {
      classError = 'Enter class';
    } else if (!RegExp(
      r'^(PRE-KG|LKG|UKG|[1-9]|1[0-2]|I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)$',
      caseSensitive: false,
    ).hasMatch(classValue)) {
      classError = 'Allowed: PRE-KG, LKG, UKG, or 1–12 or I to XII';
    }

    // Section validation
    if (sectionValue.isEmpty) {
      sectionError = 'Enter section';
    } else if (!RegExp(r'^[A-Z]$').hasMatch(sectionValue)) {
      sectionError = 'Only one capital letter allowed';
    } else {
      // Duplicate check
      final duplicate = classes.any(
        (cls) =>
            cls['class'].toString().toUpperCase() == classValue.toUpperCase() &&
            cls['section'].toString().toUpperCase() ==
                sectionValue.toUpperCase(),
      );
      if (duplicate) {
        sectionError = 'This class and section already exists';
      }
    }

    setState(() {
      fieldErrors['class'] = classError;
      fieldErrors['section'] = sectionError;
      _isFormValid = classError == null && sectionError == null;
    });
  }

  Future<void> init() async {
    setState(() => _isFetchingClasses = true);
    classes = await AdminApiService.fetchAllClasses(widget.schoolId);

    // Custom sorting: PRE-KG → LKG → UKG → 1–12
    final classOrder = {'PRE-KG': 0, 'LKG': 1, 'UKG': 2};

    classes.sort((a, b) {
      String classA = a['class'].toString();
      String classB = b['class'].toString();

      int rankA = classOrder[classA] ?? int.tryParse(classA) ?? 99;
      int rankB = classOrder[classB] ?? int.tryParse(classB) ?? 99;

      if (rankA != rankB) return rankA.compareTo(rankB);
      return a['section'].compareTo(b['section']);
    });

    if (!mounted) return;
    setState(() => _isFetchingClasses = false);

    _classController.addListener(_checkFormValidity);
    _sectionController.addListener(_checkFormValidity);
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    FocusScope.of(context).unfocus(); // Close keyboard

    final result = await ApiService.addClass(
      _classController.text.trim().toUpperCase(),
      _sectionController.text.trim().toUpperCase(),
      widget.schoolId,
    );

    if (!mounted) return;

    if (result.startsWith("✅")) {
      await init();
      _classController.clear();
      _sectionController.clear();
      setState(() => showForm = false); // Auto-close form
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isNotEmpty ? result : '❌ Unexpected error'),
        backgroundColor: result.startsWith("✅") ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _classController.dispose();
    _sectionController.dispose();
    _classFocus.dispose();
    super.dispose();
    _scrollController.dispose();
  }

  Future<bool> onWillPop() async {
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
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isFetchingClasses) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    final isMobile = size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Add/Remove Class',
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
                    title: 'Add/Remove Class',

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
        body: Center(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(key: _formKey1, height: 10),
                // Form Card
                if (showForm)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: size.width * 0.8,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Class Registration',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Class Field
                          TextField(
                            focusNode: _classFocus,
                            controller: _classController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: 'Class (PRE-KG, LKG, UKG, 1–12)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.class_),
                              errorText: fieldErrors['class'],
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9- ]'),
                              ),
                            ],
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) => _checkFormValidity(),
                          ),
                          const SizedBox(height: 16),

                          // Section Field
                          TextField(
                            controller: _sectionController,
                            decoration: InputDecoration(
                              labelText: 'Section (A-Z)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.school),
                              errorText: fieldErrors['section'],
                            ),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z]'),
                              ),
                              LengthLimitingTextInputFormatter(1),
                              UpperCaseTextFormatter(),
                            ],
                            onChanged: (_) => _checkFormValidity(),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_isSubmitting || !_isFormValid)
                                      ? null
                                      : _submitForm,
                              icon:
                                  _isSubmitting
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: Center(
                                          child: SpinKitFadingCircle(
                                            color: Colors.blueAccent,
                                            size: 60.0,
                                          ),
                                        ),
                                      )
                                      : const Icon(Icons.add),
                              label: Text(
                                _isSubmitting ? 'Please wait...' : 'Add Class',
                                style: const TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Registered Classes Title
                const Text(
                  'Registered Classes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Total : ${classes.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                if (classes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No classes registered yet.\nTap + to add one.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classData = classes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.class_, color: Colors.blue),
                          title: Text(
                            'Class: ${classData['class']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Section: ${classData['section']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Class'),
                                      content: Text(
                                        'Are you sure you want to delete Class "${classData['class']}" Section "${classData['section']}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                final result = await ApiService.deleteClass(
                                  classData['class'].toString(),
                                  classData['section'].toString(),
                                  widget.schoolId,
                                );

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result ==
                                              '❌ Failed: Internal Server Error'
                                          ? 'Class ${classData['class']} Section ${classData['section']} is used in other services'
                                          : result,
                                    ),
                                    backgroundColor:
                                        result.startsWith("✅")
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                );

                                if (result.startsWith("✅")) {
                                  await init();
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 50),
                const Divider(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue.shade50,
          onPressed:
              _isSubmitting
                  ? null
                  : () {
                    setState(() {
                      showForm = !showForm;
                    });
                    if (showForm) {
                      // 🔹 Smooth scroll to top when form is shown
                      Future.delayed(Duration(milliseconds: 100), () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      });
                    }
                  },

          child:
              showForm
                  ? Icon(Icons.close, size: 30, color: Colors.blue.shade900)
                  : Icon(Icons.add, size: 30, color: Colors.blue.shade900),
        ),
      ),
    );
  }
}

// Formatter: Converts input to uppercase automatically
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
