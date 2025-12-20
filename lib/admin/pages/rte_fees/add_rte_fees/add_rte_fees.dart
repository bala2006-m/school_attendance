import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../services/rte_fees_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../dashboard/admin_dashboard.dart';

class AdminRteFeeStructureScreen extends StatefulWidget {
  final int schoolId;
  final int classId;
  final String className;
  final String section;
  final String username;

  const AdminRteFeeStructureScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
    required this.username,
  });

  @override
  State<AdminRteFeeStructureScreen> createState() =>
      _AdminRteFeeStructureScreenState();
}

class _AdminRteFeeStructureScreenState extends State<AdminRteFeeStructureScreen>
    with TickerProviderStateMixin {
  final RteFeesService _api = RteFeesService();

  bool _loading = true;
  List<dynamic> _structures = [];
  bool refreshing = false;

  late final AnimationController _staggerController;

  @override
  void initState() {
    // print(widget.classId);
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fetchStructures();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _fetchStructures() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await _api.getStructuresBySchool(
        widget.schoolId,
        classId: widget.classId,
      );

      if (mounted) {
        setState(() {
          _structures = data ?? [];
        });
        _staggerController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch structures: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => refreshing = true);
    await _fetchStructures();
    if (mounted) setState(() => refreshing = false);
  }

  Future<void> _deleteStructure(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Structure'),
            content: const Text(
              'Are you sure you want to delete this structure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final success = await _api.deleteStructure(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
      }
      _fetchStructures();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Delete failed')));
      }
    }
  }

  Future<void> _toggleStatus(int id, bool makeActive) async {
    final status = makeActive ? 'active' : 'inactive';
    final res = await _api.toggleStatusById(id, status, widget.username);
    if (res != null) {
      _fetchStructures();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  Future<void> _openCreateEditModal({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.86,
            minChildSize: 0.45,
            maxChildSize: 0.98,
            builder: (context, controller) {
              return GestureDetector(
                onTap: () {},
                child: _RteStructureEditor(
                  controller: controller,
                  api: _api,
                  schoolId: widget.schoolId,
                  classId: widget.classId,
                  username: widget.username,
                  existing: existing,
                ),
              );
            },
          ),
    );

    if (result == true) {
      _fetchStructures();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.volunteer_activism,
            size: 80,
            color: Colors.blueAccent.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 10),
          const Text(
            'No RTE fee structures yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to create a new structure for ${widget.className}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _openCreateEditModal(),
            icon: const Icon(Icons.add),
            label: const Text('Create RTE Structure'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_structures.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _structures.length,
        itemBuilder: (context, index) {
          final item = _structures[index] as Map<String, dynamic>;
          final animationIntervalStart = (index / (_structures.length + 1))
              .clamp(0.0, 0.7);
          final animation = CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              animationIntervalStart,
              (animationIntervalStart + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: _RteStructureCard(
                data: item,
                onEdit: () => _openCreateEditModal(existing: item),
                onDelete: () => _deleteStructure(item['id'] as int),
                onToggle: (v) => _toggleStatus(item['id'] as int, v),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BuildClasses(
              schoolId: widget.schoolId.toString(),
              username: widget.username,
              title: 'Class List',
              onTap: ({
                required String schoolId,
                required String username,
                required String className,
                required String section,
                required String classId,
              }) {
                return AdminRteFeeStructureScreen(
                  schoolId: widget.schoolId,
                  username: username,
                  className: className,
                  section: section,
                  classId: int.parse(classId),
                );
              },
              onWillPop: AdminDashboard(
                schoolId: widget.schoolId.toString(),
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
        floatingActionButton: FloatingActionButton.extended(
          elevation: 8,
          heroTag: 'addRteStructure',
          backgroundColor: const Color(0xFF3B5FBC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          icon: AnimatedRotation(
            turns: 0.03,
            duration: const Duration(milliseconds: 400),
            child: const Icon(Icons.add, size: 26, color: Colors.white),
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Add RTE Structure',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          onPressed: () => _openCreateEditModal(),
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'RTE Fee Structures',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'RTE Fee Structures',
                    onBack: () => onWillPop(),
                  ),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(),
      ),
    );
  }
}

class _RteStructureCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _RteStructureCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  String _formatAmount(dynamic v) {
    try {
      final d =
          (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
      return d.toStringAsFixed(d % 1 == 0 ? 0 : 2);
    } catch (_) {
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'RTE Structure';
    final descriptions =
        (data['descriptions'] is List)
            ? List<dynamic>.from(data['descriptions'])
            : <dynamic>[];
    final amounts =
        (data['amounts'] is List)
            ? List<dynamic>.from(data['amounts'])
            : <dynamic>[];
    final total =
        data['total_amount'] ??
        amounts.fold<double>(0.0, (sum, v) {
          final n =
              (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
          return sum + n;
        });
    final status = (data['status']?.toString() ?? 'inactive').toLowerCase();
    final bool isActive = status == 'active';

    final gradientColors =
        isActive
            ? const [Color(0xFF5673F0), Color(0xFF8AB4FF)]
            : const [Color(0xFFD7DDE8), Color(0xFFF5F7FA)];

    return Card(
      elevation: 12,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header with title & actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit,
                          color: isActive ? Colors.white : Colors.black87,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: 'Delete',
                          onPressed: onDelete,
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(descriptions.length, (i) {
                    final desc = descriptions[i]?.toString() ?? '';
                    final amt =
                        (amounts.length > i) ? _formatAmount(amounts[i]) : '-';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black26,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        label: Text(
                          '$desc: ₹$amt',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor:
                            isActive
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.white70,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₹${_formatAmount(total)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        activeColor: Colors.green,
                        value: isActive,
                        onChanged: (v) => onToggle(v),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RteStructureEditor extends StatefulWidget {
  final ScrollController controller;
  final RteFeesService api;
  final int schoolId;
  final int classId;
  final String username;
  final Map<String, dynamic>? existing;

  const _RteStructureEditor({
    required this.controller,
    required this.api,
    required this.schoolId,
    required this.classId,
    required this.username,
    this.existing,
  });

  @override
  State<_RteStructureEditor> createState() => _RteStructureEditorState();
}

class _RteStructureEditorState extends State<_RteStructureEditor>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _descCtrls = [];
  final List<TextEditingController> _amtCtrls = [];

  bool _isActive = false;
  bool _saving = false;
  bool _isEditing = false;
  int? _editingId;

  late final AnimationController _enterCtrl;
  late final Animation<double> _scaleAnim;

  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scaleAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack);
    _enterCtrl.forward();

    if (widget.existing != null) {
      _loadExisting(widget.existing!);
    } else {
      _addRow();
    }

    _recalculateTotal();
  }

  @override
  void dispose() {
    for (final c in _descCtrls) {
      c.dispose();
    }
    for (final c in _amtCtrls) {
      c.dispose();
    }
    _enterCtrl.dispose();
    super.dispose();
  }

  void _loadExisting(Map<String, dynamic> existing) {
    _isEditing = true;
    _editingId = existing['id'] as int?;
    _isActive =
        (existing['status']?.toString() ?? '').toLowerCase() == 'active';

    final descs =
        (existing['descriptions'] is List)
            ? List<dynamic>.from(existing['descriptions'])
            : <dynamic>[];
    final amts =
        (existing['amounts'] is List)
            ? List<dynamic>.from(existing['amounts'])
            : <dynamic>[];

    for (final c in _descCtrls) {
      c.dispose();
    }
    for (final c in _amtCtrls) {
      c.dispose();
    }
    _descCtrls.clear();
    _amtCtrls.clear();

    final len = (descs.length > amts.length) ? descs.length : amts.length;
    if (len == 0) {
      _addRow();
    } else {
      for (int i = 0; i < len; i++) {
        final d = i < descs.length ? (descs[i]?.toString() ?? '') : '';
        final a = i < amts.length ? (_formatAmountForField(amts[i])) : '';
        _addRow(desc: d, amountText: a);
      }
    }
    _recalculateTotal();
  }

  void _addRow({String? desc, String? amountText}) {
    final d = TextEditingController(text: desc ?? '');
    final a = TextEditingController(text: amountText ?? '');
    a.addListener(_recalculateTotal);
    setState(() {
      _descCtrls.add(d);
      _amtCtrls.add(a);
    });
  }

  void _removeRow(int idx) {
    if (_descCtrls.length <= 1) return;
    setState(() {
      _amtCtrls[idx].removeListener(_recalculateTotal);
      _amtCtrls[idx].dispose();
      _descCtrls[idx].dispose();
      _amtCtrls.removeAt(idx);
      _descCtrls.removeAt(idx);
      _recalculateTotal();
    });
  }

  String _formatAmountForField(dynamic v) {
    try {
      final d =
          (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
      if (d % 1 == 0) return d.toInt().toString();
      return d.toString();
    } catch (_) {
      return '';
    }
  }

  double _parseAmount(String raw) {
    if (raw.trim().isEmpty) return 0.0;
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _recalculateTotal() {
    double s = 0.0;
    for (final a in _amtCtrls) {
      s += _parseAmount(a.text);
    }
    setState(() => _total = s);
  }

  String _displayTotal() {
    if (_total % 1 == 0) return _total.toInt().toString();
    return _total.toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool hasValid = false;
    final List<String> descs = [];
    final List<double> amounts = [];
    for (int i = 0; i < _descCtrls.length; i++) {
      final desc = _descCtrls[i].text.trim();
      final amt = _parseAmount(_amtCtrls[i].text);
      if (desc.isNotEmpty || amt > 0) {
        descs.add(desc);
        amounts.add(amt);
      }
      if (desc.isNotEmpty && amt > 0) hasValid = true;
    }
    if (!hasValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('At least one item must have description and amount'),
          ),
        );
      }
      return;
    }

    final payload = {
      'school_id': widget.schoolId,
      'class_id': widget.classId,
      'descriptions': descs,
      'amounts': amounts,
      'total_amount': _total,
      'created_by': widget.username,
      'updated_by': widget.username,
      'status': _isActive ? 'active' : 'inactive',
    };

    setState(() => _saving = true);
    try {
      Map<String, dynamic>? response;
      if (_isEditing && _editingId != null) {
        response = await widget.api.updateStructure(_editingId!, payload);
      } else {
        response = await widget.api.createStructure(payload);
      }

      if (response != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing ? 'Updated successfully' : 'Created successfully',
              ),
            ),
          );
        }
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Save failed')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? prefix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.78),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                left: 16,
                right: 16,
                top: 12,
              ),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    width: 56,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: widget.controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _scaleAnim,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isEditing
                                            ? 'Edit RTE Structure'
                                            : 'Create RTE Structure',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add fee items and configure structure details',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _descCtrls.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, idx) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: TextFormField(
                                            controller: _descCtrls[idx],
                                            decoration: _inputDecoration(
                                              label: 'Description',
                                              hint: 'E.g. Tuition, Books',
                                            ),
                                            validator: (v) {
                                              // allow blank rows as long as at least one row is valid
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 4,
                                          child: TextFormField(
                                            controller: _amtCtrls[idx],
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: _inputDecoration(
                                              label: 'Amount',
                                              prefix: '₹ ',
                                              hint: '0',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                _descCtrls.length <= 1
                                                    ? null
                                                    : () => _removeRow(idx),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _addRow(),
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Add item',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF3B5FBC,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Container()),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.blue.shade100,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Amount',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '₹ ${_displayTotal()}',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.power_settings_new,
                                          color:
                                              _isActive
                                                  ? Colors.green
                                                  : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _isActive
                                                    ? Colors.green
                                                    : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch.adaptive(
                                          value: _isActive,
                                          activeColor: Colors.green,
                                          onChanged:
                                              (v) =>
                                                  setState(() => _isActive = v),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _saving ? null : _save,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF3B5FBC,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 30,
                                              vertical: 14,
                                            ),
                                          ),
                                          child:
                                              _saving
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : Text(
                                                    _isEditing
                                                        ? 'Update'
                                                        : 'Create',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                        ),
                                        const SizedBox(width: 12),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                              ],
                            ),
                          ),
                        ],
                      ),
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
