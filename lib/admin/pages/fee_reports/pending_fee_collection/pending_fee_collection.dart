import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../services/api_service.dart';
import '../../../../services/term_fee_structure_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
import 'widget/build_pending_fee_collection_pdf.dart';

class PendingFeeCollection extends StatefulWidget {
  const PendingFeeCollection({
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
  State<PendingFeeCollection> createState() => _PendingFeeCollectionState();
}

class Student {
  final String? id;
  final String? username;
  final String? name;
  final String? route;
  final String? mobile;
  final List<Map<String, dynamic>>? studentFees;

  Student({
    required this.id,
    required this.username,
    required this.name,
    required this.route,
    required this.mobile,
    required this.studentFees,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id']?.toString(),
      username: map['username']?.toString(),
      name: map['name']?.toString(),
      route: map['route']?.toString(),
      mobile: map['mobile']?.toString(),
      studentFees:
          (map['studentFees'] is List)
              ? List<Map<String, dynamic>>.from(
                (map['studentFees'] as List).whereType<Map<String, dynamic>>(),
              )
              : null,
    );
  }
}

extension PendingAmountCalculator on Student {
  num calculatedPending(List<Map<String, dynamic>> classFeeStructures) {
    // If studentFees is empty, return sum of all active fee structure amounts
    if (studentFees == null || studentFees!.isEmpty) {
      return classFeeStructures.fold<num>(0, (sum, fs) {
        final amount = num.tryParse(fs['total_amount']?.toString() ?? '0') ?? 0;
        return sum + amount;
      });
    }

    // Otherwise, aggregate paid and total amounts from studentFees
    final Map<int, Map<String, num>> feesMap = {};
    for (final sf in studentFees!) {
      final fsId = sf['feeStructure']?['id'] ?? sf['id'] ?? 0;
      final total = num.tryParse(sf['total_amount']?.toString() ?? '0') ?? 0;
      final payments = sf['payments'] as List<dynamic>? ?? [];
      final paidSum = payments.fold<num>(0, (sum, p) {
        return sum + (num.tryParse(p['amount']?.toString() ?? '0') ?? 0);
      });

      if (!feesMap.containsKey(fsId)) {
        feesMap[fsId] = {'total': total, 'paid': paidSum};
      } else {
        feesMap[fsId]!['paid'] = feesMap[fsId]!['paid']! + paidSum;
      }
    }

    // Calculate pending: sum of (total - paid) for each active fee structure
    num pending = 0;
    for (final fs in classFeeStructures) {
      final fsId = fs['id'] as int? ?? 0;
      final total = num.tryParse(fs['total_amount']?.toString() ?? '0') ?? 0;

      if (feesMap.containsKey(fsId)) {
        final paid = feesMap[fsId]!['paid'] ?? 0;
        final diff = total - paid;
        if (diff > 0) pending += diff;
      } else {
        pending += total;
      }
    }

    return pending;
  }

  bool hasPendingFees(List<Map<String, dynamic>> classFeeStructures) =>
      calculatedPending(classFeeStructures) > 0;
}

class _PendingFeeCollectionState extends State<PendingFeeCollection> {
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  Map<String, dynamic> rawPendingFees = {};

  List<Student> get students =>
      rawPendingFees['students'] is List
          ? List<dynamic>.from(
            rawPendingFees['students'],
          ).whereType<Map<String, dynamic>>().map(Student.fromMap).toList()
          : <Student>[];

  int get totalPendingStudents {
    final List<Map<String, dynamic>> classFeeStructures =
        (rawPendingFees['feeStructures'] as List?)
            ?.where((f) {
              return f['status'] == 'active';
            })
            .map((f) => f as Map<String, dynamic>)
            .toList() ??
        [];
    return students.where((s) => s.hasPendingFees(classFeeStructures)).length;
  }

  int get totalStudents =>
      rawPendingFees['totalStudents'] != null
          ? int.parse(rawPendingFees['totalStudents'].toString())
          : students.length;

  int get paidCount =>
      (totalStudents - totalPendingStudents) < 0
          ? 0
          : (totalStudents - totalPendingStudents);

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    await Future.wait([_fetchSchoolInfo(), _fetchPendingFees()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        final s0 = schoolData[0];
        setState(() {
          schoolName = s0['name']?.toString();
          schoolAddress = s0['address']?.toString();
          if (s0['photo'] != null && s0['photo'] is String) {
            try {
              schoolPhotoBytes = base64Decode(s0['photo'] as String);
            } catch (_) {
              schoolPhotoBytes = null;
            }
          }
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _fetchPendingFees() async {
    try {
      final data = await TermFeeStructureApi.getAllPendingFeesClass(
        schoolId: int.parse(widget.schoolId),
        classId: int.parse(widget.classId),
      );
      //{"school_id":1,"totalStudents":8,"totalPending":8,"students":[{"id":561,"username":"2025000","name":"BALA","mobile":"+916352875696","class_id":29,"father_name":"MURUGAN","route":"TCR","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[]},{"id":562,"username":"2025001","name":"MITHUN","mobile":"+916352875696","class_id":29,"father_name":"MURUGAN","route":"TCR","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[]},{"id":563,"username":"2025002","name":"SELVI","mobile":"+916352875696","class_id":29,"father_name":"MURUGAN","route":"TCR","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[]},{"id":564,"username":"2025003","name":"SARAN","mobile":"+916352875696","class_id":29,"father_name":"MURUGAN","route":"TCR","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[]},{"id":601,"username":"1001","name":"SUTHA A","mobile":"+919638527411","class_id":29,"father_name":"RAMAR","route":"TIRUCHENDUR","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[{"aId":150,"id":64,"school_id":1,"class_id":29,"username":"1001","total_amount":10000,"paid_amount":1000,"status":"PARTIALLY_PAID","createdBy":"1234567890","createdAt":"2025-11-29T14:51:19.311Z","remarks":"","feeStructure":{"id":64,"school_id":1,"class_id":29,"title":"I TERM","descriptions":["fee"],"amounts":[10000],"total_amount":10000,"status":"inactive"},"payments":[{"id":153,"student_fee_id":150,"amount":1000,"payment_date":"2025-11-29T14:51:20.480Z","method":"online","transaction_id":null,"status":"PAID"}]},{"aId":152,"id":64,"school_id":1,"class_id":29,"username":"1001","total_amount":10000,"paid_amount":9000,"status":"PARTIALLY_PAID","createdBy":"1234567890","createdAt":"2025-11-29T15:03:08.758Z","remarks":"","feeStructure":{"id":64,"school_id":1,"class_id":29,"title":"I TERM","descriptions":["fee"],"amounts":[10000],"total_amount":10000,"status":"inactive"},"payments":[{"id":155,"student_fee_id":152,"amount":9000,"payment_date":"2025-11-29T15:03:09.050Z","method":"online","transaction_id":null,"status":"PAID"}]}]},{"id":616,"username":"2025008","name":"RAGU P","mobile":"+919638527410","class_id":29,"father_name":"PANDIAN","route":"TIRUCHENDUR","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[]},{"id":617,"username":"25009","name":"PARVATI S","mobile":"+919638527411","class_id":29,"father_name":"SRIDAR","route":"KURINCHINAGAR","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[{"aId":151,"id":64,"school_id":1,"class_id":29,"username":"25009","total_amount":10000,"paid_amount":1000,"status":"PARTIALLY_PAID","createdBy":"1234567890","createdAt":"2025-11-29T14:51:33.135Z","remarks":"","feeStructure":{"id":64,"school_id":1,"class_id":29,"title":"I TERM","descriptions":["fee"],"amounts":[10000],"total_amount":10000,"status":"inactive"},"payments":[{"id":154,"student_fee_id":151,"amount":1000,"payment_date":"2025-11-29T14:51:33.489Z","method":"online","transaction_id":null,"status":"PAID"}]}]},{"id":619,"username":"123","name":"bala","mobile":"+912345678989","class_id":29,"father_name":"murugan","route":"null","class":{"id":29,"class":"I","section":"A","school_id":1},"studentFees":[{"aId":148,"id":64,"school_id":1,"class_id":29,"username":"123","total_amount":10000,"paid_amount":1000,"status":"PARTIALLY_PAID","createdBy":"1234567890","createdAt":"2025-11-29T12:40:34.521Z","remarks":"","feeStructure":{"id":64,"school_id":1,"class_id":29,"title":"I TERM","descriptions":["fee"],"amounts":[10000],"total_amount":10000,"status":"inactive"},"payments":[{"id":151,"student_fee_id":148,"amount":1000,"payment_date":"2025-11-29T12:40:34.935Z","method":"online","transaction_id":null,"status":"PAID"}]},{"aId":149,"id":64,"school_id":1,"class_id":29,"username":"123","total_amount":10000,"paid_amount":9000,"status":"PARTIALLY_PAID","createdBy":"1234567890","createdAt":"2025-11-29T12:42:27.115Z","remarks":"","feeStructure":{"id":64,"school_id":1,"class_id":29,"title":"I TERM","descriptions":["fee"],"amounts":[10000],"total_amount":10000,"status":"inactive"},"payments":[{"id":152,"student_fee_id":149,"amount":9000,"payment_date":"2025-11-29T12:42:27.369Z","method":"online","transaction_id":null,"status":"PAID"}]}]}],"feeStructures":[{"id":64,"school_id":1,"class_id":29,"title":"I TERM","descriptions":["fee"],"amounts":[10000],"total_amount":10000,"start_date":"2025-11-19T00:00:00.000Z","end_date":"2025-11-20T00:00:00.000Z","created_by":"1234567890","created_at":"2025-11-19T10:04:10.345Z","updated_by":"1234567890","updated_at":"2025-11-29T09:47:46.689Z","status":"inactive"}]}
      rawPendingFees = data;
    } catch (e) {
      rawPendingFees = {};
    }
  }

  Future<void> _handleBuild({required String title}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => buildPdf(
                    title: title,
                    fees: rawPendingFees,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                  ),
              title: 'Pending Fee Collection',
              fileName: 'pending_fee_collection',
            ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
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
                username: widget.username,
              ),
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final bool canGenerate = hasActiveFeeStructures;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) _onWillPop();
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
                    title: 'Pending Collection',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: _onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Pending Fee Collection',
                    onBack: () => _onWillPop(),
                  ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : !canGenerate
                ? Center(child: Text('No fee found'))
                : RefreshIndicator(
                  onRefresh: _fetchAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSummary(),
                        const SizedBox(height: 20),
                        _buildPendingListSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        floatingActionButton: _buildGenerateButton(),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class: ${widget.className} - ${widget.section}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryTile(
                icon: Icons.people_alt,
                label: 'Total',
                value: totalStudents.toString(),
                color: Colors.white70,
              ),
              _summaryTile(
                icon: Icons.check_circle_outline,
                label: 'Paid',
                value: paidCount.toString(),
                color: Colors.greenAccent.shade100,
              ),
              _summaryTile(
                icon: Icons.warning_amber_rounded,
                label: 'Pending',
                value: totalPendingStudents.toString(),
                color: Colors.orangeAccent.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingListSection() {
    final List<Map<String, dynamic>> classFeeStructures =
        (rawPendingFees['feeStructures'] as List?)
            ?.where((f) {
              return f['status'] == 'active';
            })
            .map((f) => f as Map<String, dynamic>)
            .toList() ??
        [];

    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: Colors.green.shade600,
              size: 60,
            ),
            const SizedBox(height: 12),
            Text(
              'No pending fee records found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _StudentTile(
          student: student,
          classFeeStructures: classFeeStructures,
        );
      },
    );
  }

  bool get hasActiveFeeStructures {
    final List feeStructures = (rawPendingFees['feeStructures'] as List?) ?? [];
    return feeStructures.any((f) => f['status'] == 'active');
  }

  Widget _buildGenerateButton() {
    final bool canGenerate = hasActiveFeeStructures;

    return ElevatedButton.icon(
      onPressed:
          canGenerate
              ? () => _handleBuild(title: 'Pending Fee Collection')
              : null,
      icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
      label: const Text(
        'Generate Pending Report',
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canGenerate ? Colors.blue : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.classFeeStructures});

  final Student student;
  final List<Map<String, dynamic>> classFeeStructures;

  @override
  Widget build(BuildContext context) {
    final pendingAmount = student.calculatedPending(classFeeStructures);
    final displayPending =
        pendingAmount > 0 ? '₹${pendingAmount.toStringAsFixed(2)}' : 'Paid';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            (student.name?.isNotEmpty == true)
                ? student.name!.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Adm No: ${student.username ?? student.id ?? '-'}${student.mobile != null ? '\n${student.mobile}' : ''}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:
                pendingAmount > 0 ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pendingAmount > 0
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_outline,
                color: pendingAmount > 0 ? Colors.red : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                displayPending,
                style: TextStyle(
                  color: pendingAmount > 0 ? Colors.red : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
