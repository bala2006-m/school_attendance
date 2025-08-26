import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/services/api_service.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../services/admin_api_service.dart';
import './admin_dashboard.dart';

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

  bool _isFormValid = false;
  bool _isLoading = false;
  bool showForm = false;

  String? _responseMessage;
  final _classFocus = FocusNode();

  List<Map<String, dynamic>> classes = [];

  // 🔴 Field errors map
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

    if (classValue.isEmpty) {
      classError = 'Enter class';
    } else if (int.tryParse(classValue) == null) {
      classError = 'Class must be a number';
    } else if (int.parse(classValue) < 1 || int.parse(classValue) > 12) {
      classError = 'Class must be between 1 and 12';
    }

    if (sectionValue.isEmpty) {
      sectionError = 'Enter section';
    } else if (!RegExp(r'^[A-Z]$').hasMatch(sectionValue)) {
      sectionError = 'Only one capital letter allowed';
    } else {
      // 🔴 Duplicate Check
      final duplicate = classes.any(
        (cls) =>
            cls['class'].toString() == classValue &&
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
    setState(() => _isLoading = true);
    classes = await AdminApiService.fetchAllClasses(widget.schoolId);
    classes.sort((a, b) {
      int classCompare = a['class'].compareTo(b['class']);
      if (classCompare != 0) return classCompare;
      return a['section'].compareTo(b['section']);
    });
    if (!mounted) return;
    setState(() => _isLoading = false);

    _classController.addListener(_checkFormValidity);
    _sectionController.addListener(_checkFormValidity);
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
      _responseMessage = null;
    });

    final result = await ApiService.addClass(
      _classController.text.trim(),
      _sectionController.text.trim(),
      widget.schoolId,
    );

    if (mounted) {
      init();
      _classController.clear();
      _sectionController.clear();
    }

    setState(() {
      _isLoading = false;
      _responseMessage = result.isNotEmpty ? result : '❌ Unexpected error';
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _responseMessage = null);
        }
      });
    });
  }

  @override
  void dispose() {
    _classController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    final isMobile = size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
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
                      Navigator.pushReplacement(
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
                  : const AdminAppbarDesktop(title: 'Add Or Remove Class'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
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
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.class_),
                              errorText: fieldErrors['class'],
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            onChanged: (_) => _checkFormValidity(),
                          ),
                          const SizedBox(height: 16),

                          // Section Field
                          TextField(
                            controller: _sectionController,
                            decoration: InputDecoration(
                              labelText: 'Section (A-Z)',
                              border: OutlineInputBorder(),
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
                                  (_isLoading || !_isFormValid)
                                      ? null
                                      : _submitForm,
                              icon:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(Icons.add),
                              label: Text(
                                _isLoading ? 'Please wait...' : 'Add Class',
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
                          const SizedBox(height: 20),

                          if (_responseMessage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _responseMessage!.contains('✅')
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _responseMessage!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      _responseMessage!.contains('✅')
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
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

                // Classes list
                ...classes.map((classData) {
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
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
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
                            if (result == '❌ Failed: Internal Server Error') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Class ${classData['class']} Section ${classData['section']} is used in other services',
                                  ),
                                ),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(result)));

                            if (result.startsWith("✅")) {
                              await init();
                            }
                          }
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue.shade50,
          onPressed: () {
            setState(() {
              showForm = !showForm;
            });
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
