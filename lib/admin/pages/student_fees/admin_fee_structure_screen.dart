import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/pages/student_fees/widget/admin_fee_widgets.dart';

import '../../../teacher/services/teacher_api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import 'admin_fee_structure_classes.dart';

class AdminFeeStructureScreen extends StatefulWidget {
  final int schoolId;
  final int classId;
  final String className;
  final String section;
  final String username;

  const AdminFeeStructureScreen({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.className,
    required this.section,
  });

  @override
  State<AdminFeeStructureScreen> createState() =>
      _AdminFeeStructureScreenState();
}

class _AdminFeeStructureScreenState extends State<AdminFeeStructureScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _structures = [];
  List<Map<String, dynamic>> classes = [];
  List<dynamic> firstFee = [];
  final _formKey = GlobalKey<FormState>();
  final List<String> feeDescriptions = [
    'I TERM',
    'II TERM',
    'III TERM',
    'CUSTOM',
  ];

  List<Map<String, String>> feeDetails = [];
  bool _isSavingEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchStructures();
    fetchClasses();
    fetchallFeeStructuresClasses();
  }

  Future<void> fetchClasses() async {
    classes = await TeacherApiServices.fetchClassData(
      widget.schoolId.toString(),
    );
    final filtered =
        classes.where((item) => item['class'] == widget.className).toList();
    setState(() {
      classes = filtered;
    });
  }

  Future<void> fetchallFeeStructuresClasses() async {
    final data = await AdminApiService.getFirstFeeStructuresByClassName(
      schoolId: widget.schoolId,
      className: widget.className,
    );
    setState(() {
      firstFee = data;
    });
  }

  Future<void> _fetchStructures() async {
    setState(() => _loading = true);
    try {
      final data = await AdminApiService.getFeeStructuresByClass(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      setState(() => _structures = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch fee structures: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateSaveEnabled() {
    final validAmounts = feeDetails.every((detail) {
      final titleValid =
          detail['title'] != null && detail['title']!.trim().isNotEmpty;
      final amountValid =
          detail['amount'] != null &&
          detail['amount']!.trim().isNotEmpty &&
          double.tryParse(detail['amount']!) != null;
      return titleValid && amountValid;
    });
    final enabled = validAmounts;
    if (enabled != _isSavingEnabled) {
      setState(() {
        _isSavingEnabled = enabled;
      });
    }
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminFeeStructureClasses(
              schoolId: widget.schoolId.toString(),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed:
              () => addOrUpdateFee(
                existingFee: null,
                structures: _structures,
                feeDescriptions: feeDescriptions,
                context: context,
                updateSaveEnabled: _updateSaveEnabled,
                formKey: _formKey,
                fetchStructures: _fetchStructures,
                username: widget.username,
                classId: widget.classId,
                schoolId: widget.schoolId,
              ),
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          label: const Text(
            'Add Fee',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          extendedPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Manage Fees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Manage Fees',
                    onBack: () => onWillPop(),
                  ),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _structures.isEmpty && firstFee.isNotEmpty
                ? _buildApplyFirstFeeCard()
                : RefreshIndicator(
                  onRefresh: _fetchStructures,
                  child: buildListView(
                    structures: _structures,
                    fetchStructures: _fetchStructures,
                    feeDescriptions: feeDescriptions,
                    updateSaveEnabled: _updateSaveEnabled,
                    formKey: _formKey,
                    username: widget.username,
                    classId: widget.classId,
                    schoolId: widget.schoolId,
                    isSavingEnabled: _isSavingEnabled,
                    addOrUpdateFee: addOrUpdateFee,
                    className: widget.className,
                    section: widget.section,
                    firstFee: firstFee,
                    classes: classes,
                    context: context,
                  ),
                ),
      ),
    );
  }

  Widget _buildApplyFirstFeeCard() {
    Set<int> selectedIndexes = {};
    bool isApplying = false;

    return StatefulBuilder(
      builder: (context, setState) {
        void toggleSelection(int index, bool? value) {
          setState(() {
            if (value == true) {
              selectedIndexes.add(index);
            } else {
              selectedIndexes.remove(index);
            }
          });
        }

        Future<void> applySelectedFees() async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Confirm Apply Fees'),
                  content: Text(
                    'Apply ${selectedIndexes.length} selected fee structure(s) to this class?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
          );

          if (confirmed != true) return;

          setState(() => isApplying = true);
          bool allSuccess = true;

          for (var idx in selectedIndexes) {
            final fee = firstFee[idx];
            final descs = List<String>.from(fee['descriptions'] ?? []);
            final amts = List<dynamic>.from(fee['amounts'] ?? []);
            final descriptions = descs;
            final amounts =
                amts
                    .map(
                      (a) =>
                          (a is num)
                              ? a.toDouble()
                              : double.tryParse(a.toString()) ?? 0.0,
                    )
                    .toList();
            final totalAmount = amounts.fold(0.0, (sum, val) => sum + val);

            final success = await AdminApiService.addFeeStructure(
              schoolId: widget.schoolId,
              classId: widget.classId,
              descriptions: descriptions,
              amounts: amounts,
              totalAmount: totalAmount,
              createdBy: widget.username,
              startDate: fee['start_date'] ?? '',
              endDate: fee['end_date'] ?? '',
              title: (fee['title'] ?? '').toString().toUpperCase(),
            );

            if (!success) {
              allSuccess = false;
            }
          }

          setState(() => isApplying = false);

          if (allSuccess) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected fee structures applied successfully'),
                ),
              );
            }
            await _fetchStructures();
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to apply some fee structures'),
                ),
              );
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apply Fee Structures',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select one or more fee structures to apply for ${widget.className} - ${widget.section}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: firstFee.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final fee = firstFee[index];
                    final classInfo = fee['class'] ?? {};
                    final isSelected = selectedIndexes.contains(index);

                    String detailsPreview = '';
                    if (fee['descriptions'] is List && fee['amounts'] is List) {
                      final descs = List<String>.from(fee['descriptions']);
                      final amts = List<dynamic>.from(fee['amounts']);
                      final pairs = List.generate(
                        descs.length,
                        (i) =>
                            '${descs[i]}: ₹${amts.length > i ? amts[i] : '-'}',
                      );
                      detailsPreview = pairs.join('\n');
                    }

                    final startDateStr =
                        fee['start_date'] != null
                            ? DateTime.tryParse(fee['start_date'])?.toLocal()
                            : null;
                    final endDateStr =
                        fee['end_date'] != null
                            ? DateTime.tryParse(fee['end_date'])?.toLocal()
                            : null;
                    final dateRange =
                        (startDateStr != null && endDateStr != null)
                            ? '${DateFormat('MMM dd, yyyy').format(startDateStr)} - ${DateFormat('MMM dd, yyyy').format(endDateStr)}'
                            : '';

                    final amounts =
                        (fee['amounts'] is List)
                            ? (List<dynamic>.from(fee['amounts']))
                                .map(
                                  (a) =>
                                      (a is num)
                                          ? a.toDouble()
                                          : double.tryParse(a.toString()) ??
                                              0.0,
                                )
                                .toList()
                            : <double>[];
                    final totalAmount = amounts.fold(
                      0.0,
                      (sum, val) => sum + val,
                    );

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) => toggleSelection(index, val),
                        title: Text(
                          '${fee['title']} - ${classInfo['class']} ${classInfo['section']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dateRange.isNotEmpty)
                              Text(
                                dateRange,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              detailsPreview,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Total: ₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: ElevatedButton(
                onPressed:
                    selectedIndexes.isNotEmpty && !isApplying
                        ? applySelectedFees
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    isApplying
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : Text(
                          'Apply Selected Fees',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                selectedIndexes.isNotEmpty && !isApplying
                                    ? Colors.white
                                    : Colors.grey[100],
                          ),
                        ),
              ),
            ),
          ],
        );
      },
    );
  }
}
