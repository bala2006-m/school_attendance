import 'package:flutter/material.dart';

import '../../../../services/term_fee_structure_api.dart';

Future<void> payByCash(
  String username,
  int schoolId,
  int classId,
  double totalAmount,
  double paidAmount,
  String createdBy,
  String remarks, {
  required BuildContext context,
  required int feeId,
  required init,
  required fetchStudentFees,
}) async {
  try {
    final createdFee = await TermFeeStructureApi.createStudentFee({
      'school_id': schoolId,
      'class_id': classId,
      'username': username,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': paidAmount >= totalAmount ? 'PAID' : 'PARTIALLY_PAID',
      'createdBy': createdBy,
      'remarks': remarks,
      'createdAt': DateTime.now().toIso8601String(),
      'id': feeId,
    });

    final studentFeeId = createdFee['aId'];
    if (studentFeeId == null) {
      throw Exception('Failed to get student fee id');
    }

    await TermFeeStructureApi.createFeePayment({
      'student_fee_id': studentFeeId,
      'amount': paidAmount,
      'payment_date': DateTime.now().toIso8601String(),
      'method': 'cash',
      'transaction_id': null,
      'status': 'PAID',
    });
    init();
    fetchStudentFees(username: username);
    // ✅ Check if widget is still active
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cash payment of ₹$paidAmount processed'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to process cash payment: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

Future<void> payOnline(
  String username,
  int schoolId,
  int classId,
  double totalAmount,
  double paidAmount,
  String createdBy,
  String remarks, {
  required BuildContext context,
  required int feeId,
  required fetchStudentFees,
}) async {
  try {
    final createdFee = await TermFeeStructureApi.createStudentFee({
      'school_id': schoolId,
      'class_id': classId,
      'username': username,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': paidAmount >= totalAmount ? 'PAID' : 'PARTIAL',
      'createdBy': createdBy,
      'remarks': remarks,
      'createdAt': DateTime.now().toIso8601String(),
      'id': feeId,
    });

    final studentFeeId = createdFee['aId'];
    if (studentFeeId == null) {
      throw Exception('Failed to get student fee id');
    }

    await TermFeeStructureApi.createFeePayment({
      'student_fee_id': studentFeeId,
      'amount': paidAmount,
      'payment_date': DateTime.now().toIso8601String(),
      'method': 'online',
      'transaction_id': null,
      'status': 'PAID',
    });
    fetchStudentFees(username: username);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Online payment of ₹$paidAmount processed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process online payment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
