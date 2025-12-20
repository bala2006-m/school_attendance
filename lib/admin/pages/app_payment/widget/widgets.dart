import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_payment.dart';

Widget enhancedInfoRow({
  required IconData icon,
  required String label,
  required String value,
  required Color iconColor,
  bool showBadge = false,
}) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.05),
          spreadRadius: 1,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        // if (showBadge)
        //   Container(
        //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //     decoration: BoxDecoration(
        //       color: iconColor.withValues(alpha: 0.1),
        //       borderRadius: BorderRadius.circular(20),
        //     ),
        //     child: Text(
        //       'Active',
        //       style: TextStyle(
        //         color: iconColor,
        //         fontSize: 11,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
      ],
    ),
  );
}

Widget schoolCard({
  context,
  required List<Map<String, dynamic>> schoolData,
  required int totalStudents,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.withValues(alpha: 0.05), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.15),
          spreadRadius: 2,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        // side: BorderSide(color: Colors.blue.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Icon and Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'School Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColorDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Institution Details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Status Badge
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                //   decoration: BoxDecoration(
                //     color: Colors.green.withValues(alpha: 0.1),
                //     borderRadius: BorderRadius.circular(20),
                //     border: Border.all(
                //       color: Colors.green.withValues(alpha: 0.3),
                //       width: 1,
                //     ),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Container(
                //         width: 8,
                //         height: 8,
                //         decoration: BoxDecoration(
                //           color: Colors.green,
                //           shape: BoxShape.circle,
                //         ),
                //       ),
                //       SizedBox(width: 6),
                //       // Text(
                //       //   'Active',
                //       //   style: TextStyle(
                //       //     color: Colors.green[700],
                //       //     fontSize: 12,
                //       //     fontWeight: FontWeight.w600,
                //       //   ),
                //       // ),
                //     ],
                //   ),
                // ),
              ],
            ),

            SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.blue.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Content
            if (schoolData.isNotEmpty) ...[
              enhancedInfoRow(
                icon: Icons.business_rounded,
                label: 'School Name',
                value: schoolData[0]['name'] ?? 'N/A',
                iconColor: Colors.blue,
              ),
              SizedBox(height: 16),
              enhancedInfoRow(
                icon: Icons.location_on_rounded,
                label: 'Address',
                value: schoolData[0]['address'] ?? 'N/A',
                iconColor: Colors.red,
              ),
              SizedBox(height: 16),
              enhancedInfoRow(
                icon: Icons.people_rounded,
                label: 'Total Students',
                value: '$totalStudents',
                iconColor: Colors.green,
                showBadge: true,
              ),

              // Additional Info Section
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment calculated based on total enrolled students',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No school data available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please contact support',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget paymentPaidCard({
  required DateTime nextDueDate,
  required bool isPaymentUpToDate,
}) {
  return Card(
    color: Colors.green.shade50,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                '✅ Payment is Paid',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              //  border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green.shade700),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Payment Due Date:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(nextDueDate),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget freeTrialCard({
  required Map<String, dynamic> paymentInfo,
  required bool isPaymentUpToDate,
}) {
  final bool isTrialActive = paymentInfo['isFreeTrialActive'] ?? false;
  final DateTime? trialEndDate =
      paymentInfo['trialEndDate'] != null
          ? DateTime.parse(paymentInfo['trialEndDate'])
          : null;
  final DateTime? dueDate =
      paymentInfo['dueDate'] != null
          ? DateTime.parse(paymentInfo['dueDate'])
          : null;

  // Calculate days remaining if trial is active
  int? daysRemaining;
  if (isTrialActive && trialEndDate != null) {
    daysRemaining = trialEndDate.difference(DateTime.now()).inDays;
  }

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors:
            isTrialActive
                ? [
                  Colors.green.shade50,
                  Colors.green.shade100.withValues(alpha: 0.3),
                ]
                : [
                  Colors.orange.shade50,
                  Colors.orange.shade100.withValues(alpha: 0.3),
                ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: (isTrialActive ? Colors.green : Colors.orange).withValues(
            alpha: 0.15,
          ),
          spreadRadius: 2,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // side: BorderSide(
        //   color: (isTrialActive ? Colors.green : Colors.orange).withValues(
        //     alpha: 0.3,
        //   ),
        //   width: 1.5,
        // ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Icon and Status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isTrialActive ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTrialActive ? Icons.celebration : Icons.warning_amber,
                    color:
                        isTrialActive
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTrialActive ? 'Free Trial Active' : 'Trial Ended',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isTrialActive
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isTrialActive
                            ? 'Enjoy full access during trial'
                            : 'Payment required to continue',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                if (isTrialActive && daysRemaining != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          daysRemaining <= 3
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            daysRemaining <= 3
                                ? Colors.red.withValues(alpha: 0.4)
                                : Colors.green.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$daysRemaining days',
                      style: TextStyle(
                        color:
                            daysRemaining <= 3
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    (isTrialActive ? Colors.green : Colors.orange).withValues(
                      alpha: 0.2,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Trial End Date
            if (trialEndDate != null)
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isTrialActive ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isTrialActive ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color:
                            isTrialActive
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trial End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(trialEndDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (daysRemaining != null && daysRemaining <= 3)
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 22,
                      ),
                  ],
                ),
              ),

            // Next Due Date (if not paid up to date)
            if (dueDate != null && !isPaymentUpToDate) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payment_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Payment Due',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(dueDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Warning Message for Expired Trial
            if (!isTrialActive) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade800,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please complete payment to continue using the application',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Success Message for Active Trial
            if (isTrialActive &&
                daysRemaining != null &&
                daysRemaining > 3) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade100.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade800,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your trial is active. Explore all features without limitations!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Warning for Trial Ending Soon
            if (isTrialActive &&
                daysRemaining != null &&
                daysRemaining <= 3) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your trial is ending soon! Make a payment to avoid service interruption.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget failedOrPendingCard({
  required Map<String, dynamic> pendingOrFailedPayment,
  required bool hasPendingOrFailedPayment,
  required bool isPaymentUpToDate,
}) {
  final bool isFailed = pendingOrFailedPayment['status'] == 'FAILED';
  final Color statusColor = isFailed ? Colors.red : Colors.orange;

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [statusColor, statusColor.withValues(alpha: 0.3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: statusColor.withValues(alpha: 0.2),
          spreadRadius: 2,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFailed ? Icons.error : Icons.pending_actions,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFailed ? 'Payment Failed' : 'Payment Pending',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isFailed
                            ? 'Please retry payment'
                            : 'Complete your payment',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pendingOrFailedPayment['status'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    statusColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Payment Details
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '₹${pendingOrFailedPayment['amount']}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Plan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              pendingOrFailedPayment['paymentPlan'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(height: 1),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Created: ${DateFormat('dd MMM yyyy').format(DateTime.parse(pendingOrFailedPayment['createdAt']))}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget pendingPaymentCard({
  required String selectedPlan,
  required double calculatedAmount,
  required bool hasPendingOrFailedPayment,
  required Map<String, dynamic> pendingOrFailedPayment,
  required VoidCallback initiatePayment,
  required VoidCallback calculateAmount,
}) {
  // Calculate base amount and GST (18%)
  final baseAmount = calculatedAmount / 1.18;
  final gstAmount = calculatedAmount - baseAmount;

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade50, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withValues(alpha: 0.1),
          spreadRadius: 2,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        //side: BorderSide(color: Colors.blue.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasPendingOrFailedPayment
                        ? Icons.refresh
                        : Icons.payment_rounded,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPendingOrFailedPayment
                            ? 'Complete Payment'
                            : 'Select Payment Plan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        hasPendingOrFailedPayment
                            ? 'Retry your payment'
                            : 'Choose your preferred plan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Plan Selection
            AbsorbPointer(
              absorbing: hasPendingOrFailedPayment,
              child: Opacity(
                opacity: hasPendingOrFailedPayment ? 0.6 : 1.0,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color:
                            selectedPlan == 'MONTHLY'
                                ? Colors.blue.shade50
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selectedPlan == 'MONTHLY'
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                          width: selectedPlan == 'MONTHLY' ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        title: Text(
                          'Monthly Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '₹5.90 per student/month (incl. GST)',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        value: 'MONTHLY',
                        groupValue: selectedPlan,
                        activeColor: Colors.blue,
                        onChanged:
                            hasPendingOrFailedPayment
                                ? null
                                : (value) {
                                  AppPaymentState.selectedPlan = value!;
                                  calculateAmount();
                                },
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            selectedPlan == 'YEARLY'
                                ? Colors.green.shade50
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selectedPlan == 'YEARLY'
                                  ? Colors.green
                                  : Colors.grey.shade300,
                          width: selectedPlan == 'YEARLY' ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                Text(
                                  'Yearly Plan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'SAVE 2 MONTHS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '₹59 per student/year (Pay for 10 months)',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            value: 'YEARLY',
                            groupValue: selectedPlan,
                            activeColor: Colors.green,
                            onChanged:
                                hasPendingOrFailedPayment
                                    ? null
                                    : (value) {
                                      AppPaymentState.selectedPlan = value!;
                                      calculateAmount();
                                    },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (hasPendingOrFailedPayment)
              Padding(
                padding: EdgeInsets.only(top: 12, left: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Using existing payment details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Amount Breakdown
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Base Amount:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '₹${baseAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GST (18%):',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '₹${gstAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '₹${calculatedAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Payment Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: initiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasPendingOrFailedPayment
                          ? (pendingOrFailedPayment['status'] == 'FAILED'
                              ? Colors.red.shade600
                              : Colors.orange.shade600)
                          : Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor:
                      hasPendingOrFailedPayment
                          ? (pendingOrFailedPayment['status'] == 'FAILED'
                              ? Colors.red.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3))
                          : Colors.green.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasPendingOrFailedPayment ? Icons.refresh : Icons.payment,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      hasPendingOrFailedPayment
                          ? (pendingOrFailedPayment['status'] == 'FAILED'
                              ? 'Retry Payment'
                              : 'Complete Pending Payment')
                          : 'Pay with Razorpay',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Secure Payment Badge
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 6),
                  Text(
                    'Secure payment powered by Razorpay',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget paymentHistorys({required List<dynamic> paymentHistory}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.grey.shade50, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 2,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Colors.purple.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${paymentHistory.length} transaction${paymentHistory.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Payment Items
            ...paymentHistory.map((payment) {
              Color statusColor;
              IconData statusIcon;
              String statusLabel;

              switch (payment['status']) {
                case 'COMPLETED':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  statusLabel = 'Completed';
                  break;
                case 'FAILED':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  statusLabel = 'Failed';
                  break;
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.pending;
                  statusLabel = 'Pending';
              }

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 24),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    payment['paymentPlan'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                '₹${payment['amount']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    Divider(height: 1),
                    SizedBox(height: 16),

                    // Details
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            Icons.people,
                            'Students',
                            '${payment['studentsCount']}',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            Icons.calendar_today,
                            'Date',
                            DateFormat(
                              'dd MMM',
                            ).format(DateTime.parse(payment['paidAt'])),
                          ),
                        ),
                      ],
                    ),

                    if (payment['status'] == 'COMPLETED') ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Valid: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment['periodStart']))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment['periodEnd']))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (payment['transactionId'] != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'TXN: ${payment['transactionId']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDetailItem(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      SizedBox(width: 6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ],
  );
}
