import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:intl/intl.dart';
import 'package:school_attendance/services/bus_fee_structure_api.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../dashboard/admin_dashboard.dart';
import 'widget/widgets.dart';

class AddBusFees extends StatefulWidget {
  final String username;
  final String schoolId;

  const AddBusFees({super.key, required this.username, required this.schoolId});

  @override
  State<AddBusFees> createState() => _AddBusFeesState();
}

class _AddBusFeesState extends State<AddBusFees>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _formWidgetKey = GlobalKey(); // for scrolling
  final _scrollController = ScrollController();
  final BusFeeStructureApi api = BusFeeStructureApi();

  // Keep route controller for compatibility / editing text
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _termController = TextEditingController();
  final TextEditingController _customTermController = TextEditingController();
  final TextEditingController _amountMonthController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // For route modal search
  final TextEditingController _routeSearchController = TextEditingController();

  bool isLoading = true;
  bool isActive = false;
  bool isEditing = false;
  bool showForm = false;
  bool isFormValid = false;
  bool isDataChanged = false;
  int? editingId;

  List<dynamic> busFees = [];
  Map<String, dynamic> uniqueRouts = {};

  Map<String, dynamic> originalData = {};

  // New: selected routes for multi-select
  List<String> selectedRoutes = [];

  late AnimationController _fabAnimController;

  void _scrollToForm() {
    final context = _formWidgetKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fetchData();

    _routeController.addListener(validateForm);
    _termController.addListener(validateForm);
    _customTermController.addListener(validateForm);
    _amountMonthController.addListener(validateForm);
    _totalAmountController.addListener(() {
      // Format with commas while typing (simple approach)
      final raw = _totalAmountController.text;
      final caretPos = _totalAmountController.selection;
      final formatted = _formatNumber(raw);
      if (formatted != raw) {
        _totalAmountController.value = TextEditingValue(
          text: formatted,
          selection: caretPos,
        );
      }
      validateForm();
    });
    _endDateController.addListener(validateForm);

    _routeSearchController.addListener(() {
      // just trigger rebuild for modal search; modal uses a StatefulBuilder so this
      // controller will update local state via setStateModal when modal is open.
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _routeController.dispose();
    _termController.dispose();
    _customTermController.dispose();
    _amountMonthController.dispose();
    _totalAmountController.dispose();
    _endDateController.dispose();
    _routeSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatNumber(String input) {
    // keep only digits and decimals (but we treat amounts as integers mostly)
    String cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return '';
    // split on decimal if any
    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      final intPart = parts[0];
      final decPart = parts.length > 1 ? parts[1] : '';
      final formattedInt = _addCommas(intPart);
      return decPart.isEmpty ? '$formattedInt.' : '$formattedInt.$decPart';
    } else {
      return _addCommas(cleaned);
    }
  }

  String _addCommas(String number) {
    // handle leading zeros
    if (number.isEmpty) return '';
    final sign = number.startsWith('-') ? '-' : '';
    final digits = number.replaceFirst('-', '');
    final buffer = StringBuffer();
    int offset = digits.length % 3;
    if (offset > 0) {
      buffer.write(digits.substring(0, offset));
      if (digits.length > offset) buffer.write(',');
    }
    for (int i = offset; i < digits.length; i += 3) {
      buffer.write(digits.substring(i, i + 3));
      if (i + 3 < digits.length) buffer.write(',');
    }
    return sign + buffer.toString();
  }

  void validateForm() {
    // Use selectedRoutes for validation instead of single route controller
    bool valid =
        selectedRoutes.isNotEmpty &&
        _termController.text.isNotEmpty &&
        (_termController.text != "CUSTOM" ||
            _customTermController.text.isNotEmpty) &&
        _totalAmountController.text.isNotEmpty;

    if (isEditing) {
      isDataChanged = _checkIfDataChanged();
    }

    setState(() {
      isFormValid = valid;
    });
  }

  bool _checkIfDataChanged() {
    if (originalData.isEmpty) return true;

    // Compare by first selected route when editing (editing supports single route)
    final currentRoute = selectedRoutes.isNotEmpty ? selectedRoutes.first : '';
    return currentRoute != (originalData['route'] ?? '') ||
        _termController.text != (originalData['term'] ?? '') ||
        _amountMonthController.text !=
            (originalData['amount_month']?.toString() ?? '') ||
        // Compare without commas
        _totalAmountController.text.replaceAll(',', '') !=
            (originalData['total_amount']?.toString() ?? '') ||
        _endDateController.text !=
            (originalData['end_date']?.toString().split("T").first ?? '') ||
        isActive != (originalData['status'] == "active");
  }

  Future<void> fetchData() async {
    await Future.wait([fetchRouts(), fetchBusFees()]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchRouts() async {
    final data = await ApiService.fetchUniqueRoutes(int.parse(widget.schoolId));

    setState(() {
      uniqueRouts = data;
      List<Map<String, dynamic>> sortedRoutes = List<Map<String, dynamic>>.from(
        uniqueRouts['routs'] ?? [],
      );

      // Sort in ascending order, handling nulls
      sortedRoutes.sort((a, b) {
        final routeA =
            a['route']?.toString() ?? ''; // Treat null as empty string
        final routeB = b['route']?.toString() ?? '';
        return routeA.compareTo(routeB); // Ascending alphabetical order
      });
      uniqueRouts['routs'] = sortedRoutes;
    });
  }

  Future<void> fetchBusFees() async {
    final data = await BusFeeStructureApi.getStructuresBySchool(
      int.parse(widget.schoolId),
    );
    setState(() {
      busFees = data;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one route")),
      );
      return;
    }

    setState(() => isLoading = true);

    final termValue =
        _termController.text == "CUSTOM"
            ? _customTermController.text.trim()
            : _termController.text.trim();

    List<Map<String, dynamic>> payloads = [];

    // Create one payload for each selected route
    for (String route in selectedRoutes) {
      // parse numeric values by removing commas
      final totalAmountRaw = _totalAmountController.text.replaceAll(',', '');
      final amountMonthRaw = _amountMonthController.text.replaceAll(',', '');

      payloads.add({
        "school_id": int.parse(widget.schoolId),
        "route": route,
        "term": termValue,
        "amount_month": double.tryParse(amountMonthRaw) ?? 0,
        "total_amount": double.tryParse(totalAmountRaw) ?? 0,
        "status": isActive ? "active" : "inactive",
        "end_date":
            _endDateController.text.trim().isEmpty
                ? null
                : '${DateTime.parse(_endDateController.text.trim()).toIso8601String()}Z',
        "created_by": widget.username,
        "updated_by": widget.username,
      });
    }

    bool success = true;
    for (var data in payloads) {
      final result =
          isEditing
              ? await api.updateStructure(editingId!, data)
              : await api.createStructure(data);

      if (result == null) success = false;
    }

    setState(() => isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[600],
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  isEditing
                      ? "Bus Fee Structure updated!"
                      : "Bus Fee Structure(s) added!",
                ),
              ],
            ),
          ),
        );
      }
      _clearForm();
      fetchBusFees();
      setState(() => showForm = false);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text("Operation failed!"),
              ],
            ),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _routeController.clear();
    _termController.clear();
    _customTermController.clear();
    _amountMonthController.clear();
    _totalAmountController.clear();
    _endDateController.clear();
    originalData.clear();
    selectedRoutes.clear();
    setState(() {
      isActive = false;
      isEditing = false;
      editingId = null;
      isFormValid = false;
      isDataChanged = false;
    });
  }

  void _editStructure(Map<String, dynamic> item) {
    setState(() {
      showForm = true;
      isEditing = true;
      if (showForm) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToForm());
      }
      editingId = item['id'];
      originalData = Map<String, dynamic>.from(item);

      // For editing we set selectedRoutes to the single route of this item
      final routeValue = item['route'] ?? '';
      selectedRoutes = routeValue == null ? [] : [routeValue];

      _routeController.text = item['route'] ?? '';
      _termController.text = item['term'] ?? '';
      _amountMonthController.text = item['amount_month']?.toString() ?? '';
      // Format total for display
      _totalAmountController.text = (item['total_amount']?.toString() ?? '')
          .replaceAll(',', '');
      _totalAmountController.text = _formatNumber(_totalAmountController.text);
      _endDateController.text =
          item['end_date']?.toString().split("T").first ?? '';
      isActive = item['status'] == "active";
      validateForm();
    });
  }

  Future<void> _deleteStructure(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              "Delete Bus Fee",
              style: TextStyle(color: Colors.red[700]),
            ),
            content: Text("Are you sure you want to delete this record?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete", style: TextStyle(color: Colors.red[700])),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final success = await api.deleteStructure(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Deleted successfully ✅")));
      }
      fetchBusFees();
    }
  }

  Future<void> _toggleStatus(int id, bool newStatus) async {
    final status = newStatus ? "active" : "inactive";
    final result = await api.toggleStatusById(id, status, widget.username);

    if (result != null) {
      fetchBusFees();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed to update status")));
      }
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  List<String> getAvailableTermsForRoute(String? selectedRoute) {
    // When multi-select is active, use first selected route to determine available terms.
    final route =
        (selectedRoute == null || selectedRoute.isEmpty) ? null : selectedRoute;
    if (route == null || route.isEmpty) {
      return ["I TERM", "II TERM", "III TERM", "CUSTOM"];
    }
    final usedTerms =
        busFees
            .where((f) => f['route'] == route)
            .map<String>((f) => f['term'] as String)
            .toList();
    final allTerms = ["I TERM", "II TERM", "III TERM", "CUSTOM"];
    return allTerms.where((term) => !usedTerms.contains(term)).toList();
  }

  void _openRouteSelector(List<dynamic> routes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.35,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 14,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: StatefulBuilder(
                    builder: (context, setStateModal) {
                      final safeRoutes =
                          (routes)
                              .map<Map<String, String>>((item) {
                                if (item is Map && item['route'] != null) {
                                  return {'route': item['route'].toString()};
                                } else if (item is String) {
                                  return {'route': item};
                                }
                                return {'route': ''}; // fallback safe map
                              })
                              .where((e) => e['route']!.trim().isNotEmpty)
                              .toList();

                      final query =
                          _routeSearchController.text.trim().toLowerCase();

                      final filtered =
                          query.isEmpty
                              ? safeRoutes
                              : safeRoutes.where((r) {
                                final name =
                                    r['route'].toString().toLowerCase();
                                return name.contains(query);
                              }).toList();

                      final allRouteNames =
                          safeRoutes
                              .map<String>((e) => e['route'].toString())
                              .toList();

                      final allSelected =
                          selectedRoutes.length == allRouteNames.length &&
                          allRouteNames.isNotEmpty;

                      return Column(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.drag_handle,
                                size: 18,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ---------------- SEARCH BAR + SELECT ALL ----------------
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _routeSearchController,
                                  onChanged: (_) => setStateModal(() {}),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: "Search routes...",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setStateModal(() {
                                    if (!allSelected) {
                                      selectedRoutes = allRouteNames.toList();
                                    } else {
                                      selectedRoutes.clear();
                                    }
                                  });
                                  setState(() {});
                                  validateForm();
                                },
                                icon: Icon(
                                  allSelected
                                      ? Icons.clear_all
                                      : Icons.select_all,
                                ),
                                label: Text(
                                  allSelected ? "Unselect all" : "Select all",
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // ---------------- LIST VIEW ----------------
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: filtered.length,
                                itemBuilder: (context, idx) {
                                  final r = filtered[idx];
                                  final routeName = r['route'];

                                  final isSelected = selectedRoutes.contains(
                                    routeName,
                                  );

                                  return Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 4,
                                    ),
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (v) {
                                        setStateModal(() {
                                          if (v == true) {
                                            if (!selectedRoutes.contains(
                                              routeName,
                                            )) {
                                              selectedRoutes.add(routeName);
                                            }
                                          } else {
                                            selectedRoutes.remove(routeName);
                                          }
                                        });
                                        setState(() {});
                                        validateForm();
                                      },
                                      title: Text(
                                        routeName!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ---------------- APPLY BUTTON ----------------
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {});
                                    validateForm();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Apply (${selectedRoutes.length})",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bus Fee Structure',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bus Fee Structure',
                    onBack: onWillPop,
                  ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: showForm ? Colors.grey[700] : Color(0xFF3B5FBC),
          icon: AnimatedRotation(
            turns: showForm ? 0.125 : 0,
            duration: Duration(milliseconds: 350),
            child: Icon(
              showForm ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
          label: Text(
            showForm ? "Close" : "Add Bus Fee",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            setState(() {
              if (showForm) _clearForm();
              showForm = !showForm;
            });
            if (showForm) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToForm(),
              );
            }
          },
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(color: Colors.blue, size: 50),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height,
                        child: existingFeeContainer(
                          busFees: busFees,
                          isMobile: isMobile,
                          editStructure: _editStructure,
                          deleteStructure: _deleteStructure,
                          toggleStatus: _toggleStatus,
                        ),
                      ),
                      showForm ? SizedBox(height: 20) : SizedBox(height: 40),
                      if (showForm)
                        Container(
                          key: _formWidgetKey,
                          child: _buildForm(isMobile),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    // --- ROUTES (raw routes from uniqueRouts) ---
    final allRoutes =
        ((uniqueRouts['routs'] as List?) ?? [])
            .where((item) {
              final route = item['route']?.toString().trim().toLowerCase();
              return route != null && route.isNotEmpty && route != 'null';
            })
            .map((e) => e['route'].toString())
            .toList();

    // --- FILTER existing routes for selected TERM ---
    List<String> getFilteredRoutes() {
      final selectedTerm = _termController.text.trim();

      if (selectedTerm.isEmpty) return allRoutes;

      // existingFees must be your real DB list
      // example shape:
      // [{ "term": "TERM 1", "route": "A" }, ...]
      final existingForTerm =
          busFees
              .where((e) => e["term"] == selectedTerm)
              .map((e) => e["route"])
              .toSet();

      return allRoutes.where((r) => !existingForTerm.contains(r)).toList();
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            width: isMobile ? double.infinity : 720,
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -----------------------------------------
                        // TITLE
                        // -----------------------------------------
                        Row(
                          children: [
                            Icon(
                              isEditing ? Icons.edit : Icons.add_circle,
                              color:
                                  isEditing
                                      ? Colors.amber[700]
                                      : const Color(0xFF3B5FBC),
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              overflow: TextOverflow.ellipsis,
                              isEditing ? "Edit Bus Fee" : "Add Bus Fee",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child:
                                  isEditing
                                      ? Chip(
                                        key: ValueKey('editing_chip'),
                                        avatar: Icon(Icons.info, size: 16),
                                        label: Text('Editing'),
                                        backgroundColor: Colors.amber.shade100,
                                      )
                                      : SizedBox.shrink(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ---------------------------------------------------
                        // 1️⃣  TERM SECTION (MOVED TO TOP)
                        // ---------------------------------------------------
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📅 Term Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      getAvailableTermsForRoute(
                                        selectedRoutes.isNotEmpty
                                            ? selectedRoutes.first
                                            : '',
                                      ).map((term) {
                                        final bool isSelected =
                                            _termController.text == term;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(term),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              setState(() {
                                                _termController.text =
                                                    selected ? term : '';

                                                // RESET ROUTES when TERM changes
                                                selectedRoutes.clear();
                                              });
                                              validateForm();
                                            },
                                            selectedColor: const Color(
                                              0xFF3B5FBC,
                                            ),
                                            backgroundColor:
                                                Colors.blueGrey.shade50,
                                            labelStyle: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.blueGrey[700],
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),

                              if (_termController.text == "CUSTOM") ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _customTermController,
                                  decoration: _inputDecoration(
                                    "Enter Custom Term",
                                    Icons.edit_calendar,
                                  ),
                                  validator:
                                      (v) =>
                                          _termController.text == "CUSTOM" &&
                                                  (v == null || v.isEmpty)
                                              ? "Enter custom term"
                                              : null,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ---------------------------------------------------
                        // 2️⃣  ROUTE SECTION (NOW AFTER TERM)
                        // ---------------------------------------------------
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🛣️ Route Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[700],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // route selector
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        final filtered = getFilteredRoutes();
                                        _openRouteSelector(filtered);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.route,
                                              color: Colors.blueGrey,
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                selectedRoutes.isEmpty
                                                    ? "Select Routes"
                                                    : "${selectedRoutes.length} selected",
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ),
                                            Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Tooltip(
                                    message: "Clear selected routes",
                                    child: IconButton(
                                      onPressed:
                                          selectedRoutes.isEmpty
                                              ? null
                                              : () {
                                                setState(() {
                                                  selectedRoutes.clear();
                                                });
                                                validateForm();
                                              },
                                      icon: Icon(Icons.clear),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child:
                                    selectedRoutes.isEmpty
                                        ? SizedBox.shrink()
                                        : SizedBox(
                                          height: 44,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: selectedRoutes.length,
                                            itemBuilder: (context, index) {
                                              final r = selectedRoutes[index];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6.0,
                                                ),
                                                child: InputChip(
                                                  label: Text(r),
                                                  onDeleted: () {
                                                    setState(() {
                                                      selectedRoutes.removeAt(
                                                        index,
                                                      );
                                                    });
                                                    validateForm();
                                                  },
                                                  deleteIcon: const Icon(
                                                    Icons.close,
                                                  ),
                                                  elevation: 2,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 2,
                                                      ),
                                                ),
                                              );
                                            },
                                            separatorBuilder:
                                                (_, __) => SizedBox(width: 6),
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ---------------------------------------------------
                        // AMOUNT SECTION
                        // ---------------------------------------------------
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F7F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "💰 Fee Details",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal[700],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Tooltip(
                                    message:
                                        "Total amount to be charged for the term",
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      "₹",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),

                                  Expanded(
                                    child: TextFormField(
                                      controller: _totalAmountController,
                                      decoration: _inputDecoration(
                                        "Total Amount",
                                        Icons.payments,
                                      ),
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator:
                                          (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? "Enter total amount"
                                                  : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text("Active"),
                            Switch(
                              value: isActive,
                              onChanged: (v) => setState(() => isActive = v),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ---------------------------------------------------
                        // BUTTON
                        // ---------------------------------------------------
                        Center(
                          child: ElevatedButton.icon(
                            icon:
                                isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Icon(
                                      isEditing ? Icons.update : Icons.save,
                                    ),
                            label: Text(isEditing ? "Update" : "Save"),
                            onPressed:
                                (!isFormValid ||
                                        (isEditing && !isDataChanged) ||
                                        isLoading)
                                    ? null
                                    : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B5FBC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 40,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 6,
                              shadowColor: Colors.blueAccent.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          showForm ? SizedBox(height: 40) : SizedBox(),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
