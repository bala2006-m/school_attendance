import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_api_service.dart';

Widget buildListView({
  required List<Map<String, dynamic>> structures,
  required Future<void> Function() fetchStructures,
  required Function({
    Map<String, dynamic>? existingFee,
    required List<Map<String, dynamic>> structures,
    required List<String> feeDescriptions,
    required BuildContext context,
    required VoidCallback updateSaveEnabled,
    required GlobalKey<FormState> formKey,
    required Future<void> Function() fetchStructures,
    required String username,
    required int classId,
    required int schoolId,
  })
  addOrUpdateFee,
  required List<String> feeDescriptions,
  required VoidCallback updateSaveEnabled,
  required GlobalKey<FormState> formKey,
  required String username,
  required int classId,
  required int schoolId,
  required bool isSavingEnabled,
  required String className,
  required String section,
  required List<dynamic> firstFee,
  required List<Map<String, dynamic>> classes,
  required BuildContext context,
}) {
  // If structures is empty and firstFee has data, show apply options
  if (structures.isEmpty && firstFee.isNotEmpty) {
    // Keep track of selected fees (by index)
    Set<int> selectedIndexes = {};

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
          bool allSuccess = true;

          for (var idx in selectedIndexes) {
            final fee = firstFee[idx];
            final descs = List<String>.from(fee['descriptions'] ?? []);
            final amts = List<dynamic>.from(fee['amounts'] ?? []);
            final descriptions = descs;
            final amounts = amts.map((a) => (a as num).toDouble()).toList();
            final totalAmount = amounts.fold(0.0, (sum, val) => sum + val);

            final startDateStr = fee['start_date'] ?? "";
            final endDateStr = fee['end_date'] ?? "";

            final success = await AdminApiService.addFeeStructure(
              schoolId: schoolId,
              classId: classId,
              descriptions: descriptions,
              amounts: amounts,
              totalAmount: totalAmount,
              createdBy: username,
              startDate: startDateStr,
              endDate: endDateStr,
              title: (fee['title'] ?? '').toString().toUpperCase(),
            );

            if (!success) {
              allSuccess = false;
            }
          }

          if (allSuccess) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected fee structures applied successfully'),
                ),
              );
            }
            await fetchStructures();
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
          children: [
            classSectionCard(className, section),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select fee structures to apply for $className - $section',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: firstFee.length,
                itemBuilder: (context, index) {
                  final fee = firstFee[index];
                  final classInfo = fee['class'] ?? {};
                  final isSelected = selectedIndexes.contains(index);

                  // Prepare fee description preview string
                  String detailsPreview = '';
                  if (fee['descriptions'] is List && fee['amounts'] is List) {
                    final descs = List<String>.from(fee['descriptions']);
                    final amts = List<dynamic>.from(fee['amounts']);
                    final pairs = List.generate(
                      descs.length,
                      (i) => '${descs[i]}: ₹${amts.length > i ? amts[i] : '-'}',
                    );
                    detailsPreview = pairs.join('\n');
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) => toggleSelection(index, val),
                      title: Text(
                        '${fee['title']} - ${classInfo['class']} ${classInfo['section']}',
                      ),
                      subtitle: Text(detailsPreview),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed:
                    selectedIndexes.isNotEmpty ? applySelectedFees : null,
                child: const Text('Apply Selected Fees'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Otherwise, show the normal list
  return Column(
    children: [
      classSectionCard(className, section),
      Flexible(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: structures.length,
            itemBuilder: (context, index) {
              final fee = structures[index];
              final isActive = fee['status'] == 'active';

              List<String> descs = [];
              List<dynamic> amts = [];

              if (fee['descriptions'] is List && fee['amounts'] is List) {
                descs = List<String>.from(fee['descriptions']);
                amts = List<dynamic>.from(fee['amounts']);
                // final pairs = List.generate(
                //   descs.length,
                //   (i) => '${descs[i]}: ₹${amts.length > i ? amts[i] : '-'}',
                // );
              }

              return card(
                fee: fee,
                structures: structures,
                feeDescriptions: feeDescriptions,
                context: context,
                updateSaveEnabled: updateSaveEnabled,
                formKey: formKey,
                fetchStructures: fetchStructures,
                username: username,
                classId: classId,
                schoolId: schoolId,
                descs: descs,
                amts: amts,
                isActive: isActive,
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 50),
    ],
  );
}

Future<void> addOrUpdateFee({
  Map<String, dynamic>? existingFee,
  required List<Map<String, dynamic>> structures,
  required List<String> feeDescriptions,
  required BuildContext context,
  required VoidCallback updateSaveEnabled,
  required GlobalKey<FormState> formKey,
  required Future<void> Function() fetchStructures,
  required String username,
  required int classId,
  required int schoolId,
}) async {
  // Initialize values
  String startDateString = '';
  String endDateString = '';
  String? selectedDescription = existingFee?['title']?.toString().toUpperCase();
  DateTime? startDate =
      existingFee?['start_date'] != null
          ? DateTime.tryParse(existingFee!['start_date'])?.toLocal()
          : null;
  DateTime? endDate =
      existingFee?['end_date'] != null
          ? DateTime.tryParse(existingFee!['end_date'])?.toLocal()
          : null;
  String? customDescription = '';
  List<Map<String, String>> feeDetails = [];

  // Load existing fee details if present
  if (existingFee != null &&
      existingFee['descriptions'] is List &&
      existingFee['amounts'] is List) {
    final descs = List<String>.from(existingFee['descriptions']);
    final amts = List.from(existingFee['amounts']);
    feeDetails = List.generate(descs.length, (i) {
      return {
        'title': descs[i],
        'amount': amts.length > i ? amts[i].toString() : '',
      };
    });
  } else {
    feeDetails = [
      {'title': '', 'amount': ''},
    ];
  }

  // Prepare dropdown titles filtering out used titles
  final usedTitles =
      structures.map((e) => e['title'].toString().toUpperCase()).toSet();
  final filteredTitles = <String>{};
  for (final title in feeDescriptions) {
    final upper = title.toUpperCase();
    if (!usedTitles.contains(upper)) filteredTitles.add(upper);
  }
  if (selectedDescription != null &&
      selectedDescription.isNotEmpty &&
      !filteredTitles.contains(selectedDescription)) {
    filteredTitles.add(selectedDescription);
  }
  final dropdownItems = filteredTitles.toList()..sort();

  bool isSaveEnabled = false;
  final List<FocusNode> descriptionFocusNodes = List.generate(
    feeDetails.length,
    (_) => FocusNode(),
  );
  await showDialog(
    context: context,
    builder:
        (_) => StatefulBuilder(
          builder: (context, setStateDialog) {
            void validateForm() {
              isSaveEnabled =
                  formKey.currentState!.validate() &&
                  startDate != null &&
                  endDate != null &&
                  (selectedDescription != null &&
                      selectedDescription!.isNotEmpty) &&
                  feeDetails.every(
                    (f) =>
                        f['title']!.isNotEmpty &&
                        f['amount']!.isNotEmpty &&
                        double.tryParse(f['amount']!) != null,
                  );
              setStateDialog(() {});
              updateSaveEnabled();
            }

            Future<void> deleteFee() async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text(
                        'Are you sure you want to delete this fee structure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                final success = await AdminApiService.deleteFeeStructure(
                  existingFee?['id'],
                );
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close add/update dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fee deleted successfully')),
                    );
                  }
                  await fetchStructures(); // Refresh list
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete fee')),
                    );
                  }
                }
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      existingFee != null
                          ? 'Update Fee Structure'
                          : 'Add Fee Structure',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Form(
                        key: formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: validateForm,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                value:
                                    dropdownItems.contains(selectedDescription)
                                        ? selectedDescription
                                        : null,
                                decoration: feeTitleDecoration,
                                items:
                                    dropdownItems
                                        .map(
                                          (title) => DropdownMenuItem(
                                            value: title,
                                            child: Text(title),
                                          ),
                                        )
                                        .toList(),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Select fee title'
                                            : null,
                                onChanged: (v) {
                                  selectedDescription = v;
                                  if (v != 'CUSTOM') customDescription = '';
                                  validateForm();
                                },
                              ),
                              if (selectedDescription == 'CUSTOM')
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextFormField(
                                    initialValue: customDescription,
                                    decoration: customFeeDecoration,
                                    onChanged: (v) {
                                      customDescription = v.toUpperCase();
                                      validateForm();
                                    },
                                    validator: (v) {
                                      if (selectedDescription == 'CUSTOM') {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Enter custom fee title';
                                        }
                                        final allTitles =
                                            structures
                                                .map(
                                                  (e) =>
                                                      e['title']
                                                          .toString()
                                                          .toUpperCase(),
                                                )
                                                .toSet();
                                        if (allTitles.contains(
                                          v.trim().toUpperCase(),
                                        )) {
                                          return 'Title already exists';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Text(
                                'Fee Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...feeDetails.asMap().entries.map((entry) {
                                final i = entry.key;
                                final detail = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          focusNode: descriptionFocusNodes[i],
                                          initialValue: detail['title'],
                                          decoration: descriptionDecoration,
                                          onChanged: (val) {
                                            feeDetails[i]['title'] = val;
                                            validateForm();
                                          },
                                          validator:
                                              (val) =>
                                                  val == null || val.isEmpty
                                                      ? 'Enter description'
                                                      : null,
                                        ),
                                      ),

                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: detail['amount'],
                                          decoration: InputDecoration(
                                            labelText: 'Amount (₹)',
                                            filled: true,
                                            fillColor: Colors.teal.shade50,
                                            labelStyle: TextStyle(
                                              color: Colors.teal.shade700,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.teal.shade700,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Colors.red,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                  horizontal: 16,
                                                ),
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}'),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            feeDetails[i]['amount'] = val;
                                            validateForm();
                                          },
                                          validator: (val) {
                                            if (val == null || val.isEmpty) {
                                              return 'Enter amount';
                                            }
                                            if (double.tryParse(val) == null) {
                                              return 'Invalid number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      if (feeDetails.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          tooltip: 'Remove fee detail',
                                          onPressed: () {
                                            feeDetails.removeAt(i);
                                            validateForm();
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.blue,
                                  ),
                                  label: const Text(
                                    'Add Row',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  onPressed: () {
                                    feeDetails.add({'title': '', 'amount': ''});
                                    descriptionFocusNodes.add(FocusNode());
                                    setStateDialog(
                                      () {},
                                    ); // rebuild to include new field
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          descriptionFocusNodes.last
                                              .requestFocus();
                                        });
                                    validateForm();
                                  },
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Total Amount: ₹${feeDetails.fold<double>(0, (sum, f) => sum + (double.tryParse(f['amount'] ?? '') ?? 0)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: Text(
                                  startDate != null
                                      ? 'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}'
                                      : 'Select Start Date',
                                  style: TextStyle(color: Colors.teal.shade700),
                                ),
                                trailing: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.teal,
                                ),
                                onTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate ?? now,
                                    firstDate: now,
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.teal.shade700,
                                            onPrimary: Colors.white,
                                            onSurface: Colors.teal.shade700,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.teal.shade700,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    startDateString =
                                        "${picked.year.toString().padLeft(4, '0')}-"
                                        "${picked.month.toString().padLeft(2, '0')}-"
                                        "${picked.day.toString().padLeft(2, '0')}T00:00:00Z";
                                    startDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                    );
                                    validateForm();
                                  }
                                },
                              ),
                              ListTile(
                                title: Text(
                                  endDate != null
                                      ? 'End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                                      : 'Select End Date',
                                  style: TextStyle(color: Colors.teal.shade700),
                                ),
                                trailing: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.teal,
                                ),
                                onTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: endDate ?? startDate ?? now,
                                    firstDate: startDate ?? now,
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.teal.shade700,
                                            onPrimary: Colors.white,
                                            onSurface: Colors.teal.shade700,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.teal.shade700,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    endDateString =
                                        "${picked.year.toString().padLeft(4, '0')}-"
                                        "${picked.month.toString().padLeft(2, '0')}-"
                                        "${picked.day.toString().padLeft(2, '0')}T00:00:00Z";
                                    endDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                    );
                                    validateForm();
                                  }
                                },
                              ),
                              if (existingFee != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 8.0,
                                    top: 12.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete Fee Structure',
                                      onPressed: () async {
                                        await deleteFee();
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          onPressed:
                              isSaveEnabled
                                  ? () async {
                                    final mainDescription =
                                        selectedDescription == 'CUSTOM'
                                            ? customDescription!.toUpperCase()
                                            : selectedDescription!
                                                .toUpperCase();

                                    final descriptions =
                                        feeDetails
                                            .map((e) => e['title']!.trim())
                                            .toList();

                                    final amounts =
                                        feeDetails
                                            .map(
                                              (e) =>
                                                  double.tryParse(
                                                    e['amount']!.trim(),
                                                  ) ??
                                                  0.0,
                                            )
                                            .toList();

                                    final totalAmount = amounts.fold(
                                      0.0,
                                      (sum, val) => sum + val,
                                    );

                                    bool success;

                                    if (existingFee != null) {
                                      success =
                                          await AdminApiService.updateFeeStructure(
                                            feeId: existingFee['id'],
                                            descriptions: descriptions,
                                            amounts: amounts,
                                            totalAmount: totalAmount,
                                            startDate: startDateString,
                                            endDate: endDateString,
                                            updatedBy: username,
                                            title: mainDescription,
                                          );
                                    } else {
                                      success =
                                          await AdminApiService.addFeeStructure(
                                            schoolId: schoolId,
                                            classId: classId,
                                            descriptions: descriptions,
                                            amounts: amounts,
                                            totalAmount: totalAmount,
                                            createdBy: username,
                                            startDate: startDateString,
                                            endDate: endDateString,
                                            title: mainDescription,
                                          );
                                    }

                                    if (success) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              existingFee != null
                                                  ? 'Fee updated successfully'
                                                  : 'Fee added successfully',
                                            ),
                                          ),
                                        );
                                      }
                                      await fetchStructures();
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Operation failed'),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                  : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
  );
}
// _structures  is null firstFee has values then show  apply firstFee[class]['class'] -firstFee[class]['section'] fees to this class if clicked then insert fee structure

Widget classSectionCard(String className, String section) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Class: $className',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
            fontSize: 24,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(width: 28),
        Text(
          'Section: $section',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
            fontSize: 24,
            letterSpacing: 1.0,
          ),
        ),
      ],
    ),
  );
}

/// Toggle active/inactive status
Future<void> toggleStatus({
  required int feeId,
  required String currentStatus,
  required BuildContext context,
  required Future<void> Function() fetchStructures,
}) async {
  final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
  try {
    final success = await AdminApiService.updateFeeStatus(
      feeId: feeId,
      status: newStatus,
    );
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status changed to $newStatus')));
      }
      await fetchStructures();
    } else {
      throw Exception('Failed to update status');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

Widget card({
  required Map<String, dynamic> fee,
  required List<Map<String, dynamic>> structures,
  required List<String> feeDescriptions,
  required BuildContext context,
  required VoidCallback updateSaveEnabled,
  required GlobalKey<FormState> formKey,
  required Future<void> Function() fetchStructures,
  required String username,
  required int classId,
  required int schoolId,
  required List<String> descs,
  required List<dynamic> amts,
  required bool isActive,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 6,
    margin: const EdgeInsets.symmetric(vertical: 14),
    shadowColor: Colors.teal.withValues(alpha: 0.3),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 24,
        ),
        title: cardHeader(
          fee: fee,
          structures: structures,
          feeDescriptions: feeDescriptions,
          context: context,
          updateSaveEnabled: updateSaveEnabled,
          formKey: formKey,
          fetchStructures: fetchStructures,
          username: username,
          classId: classId,
          schoolId: schoolId,
        ),
        subtitle: cardSubtitle(
          fee: fee,
          descs: descs,
          amts: amts,
          isActive: isActive,
          fetchStructures: fetchStructures,
          context: context,
        ),
      ),
    ),
  );
}

Widget cardHeader({
  required Map<String, dynamic> fee,
  required List<Map<String, dynamic>> structures,
  required List<String> feeDescriptions,
  required BuildContext context,
  required VoidCallback updateSaveEnabled,
  required GlobalKey<FormState> formKey,
  required Future<void> Function() fetchStructures,
  required String username,
  required int classId,
  required int schoolId,
}) {
  return Center(
    child: Column(
      children: [
        Row(
          children: [
            Text(
              fee['title'] ?? 'Untitled Fee',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue.shade800,
                letterSpacing: 0.5,
              ),
            ),
            Spacer(),
            Tooltip(
              message: 'Edit Fee',
              waitDuration: Duration(milliseconds: 500),
              child: Material(
                color: Colors.teal.shade100,
                shape: CircleBorder(),
                child: InkWell(
                  customBorder: CircleBorder(),
                  splashColor: Colors.teal.shade300,
                  onTap:
                      () => addOrUpdateFee(
                        existingFee: fee,
                        structures: structures,
                        feeDescriptions: feeDescriptions,
                        context: context,
                        updateSaveEnabled: updateSaveEnabled,
                        formKey: formKey,
                        fetchStructures: fetchStructures,
                        username: username,
                        classId: classId,
                        schoolId: schoolId,
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit,
                      color: Colors.teal.shade700,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Divider(),
      ],
    ),
  );
}

Widget cardSubtitle({
  required Map<String, dynamic> fee,
  required List<String> descs,
  required List<dynamic> amts,
  required bool isActive,
  required Future<void> Function() fetchStructures,
  required BuildContext context,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${fee['total_amount']}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                descs.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${descs[i]}: ₹${amts.length > i ? amts[i] : '-'}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start: ${fee['start_date']?.split('T')[0] ?? '-'}\nEnd :  ${fee['end_date']?.split('T')[0] ?? '-'}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
            ],
          ),
        ),
        Spacer(),
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tooltip(
              message: isActive ? 'Deactivate Fee' : 'Activate Fee',
              waitDuration: Duration(milliseconds: 500),
              child: Switch.adaptive(
                value: isActive,
                activeColor: Colors.green.shade700,
                inactiveThumbColor: Colors.red.shade700,
                onChanged:
                    (_) => toggleStatus(
                      feeId: fee['id'],
                      currentStatus: fee['status'],
                      fetchStructures: fetchStructures,
                      context: context,
                    ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

InputDecoration customFeeDecoration = InputDecoration(
  labelText: 'Custom Fee Title',
  filled: true,
  fillColor: Colors.teal.shade50,
  labelStyle: TextStyle(color: Colors.teal.shade700),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.red),
  ),
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
);

InputDecoration feeTitleDecoration = InputDecoration(
  labelText: 'Fee Title',
  filled: true,
  fillColor: Colors.teal.shade50,
  labelStyle: TextStyle(color: Colors.teal.shade700),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.red),
  ),
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
);

InputDecoration descriptionDecoration = InputDecoration(
  labelText: 'Description',
  filled: true,
  fillColor: Colors.teal.shade50,
  labelStyle: TextStyle(color: Colors.teal.shade700),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.red),
  ),
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
);
