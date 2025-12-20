import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:school_attendance/admin/pages/app_payment/widget/widgets.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/services/api_service.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../dashboard/admin_dashboard.dart';

class AppPayment extends StatefulWidget {
  const AppPayment({super.key, required this.schoolId, required this.username});
  final String schoolId;
  final String username;

  @override
  State<AppPayment> createState() => AppPaymentState();
}

class AppPaymentState extends State<AppPayment> {
  int totalStudents = 0;
  List<Map<String, dynamic>> schoolData = [];
  Map<String, dynamic>? paymentInfo;
  bool isLoading = true;
  static String selectedPlan = 'MONTHLY';
  double calculatedAmount = 0;
  List<dynamic> paymentHistory = [];

  // Payment status tracking
  bool hasCompletedPayment = false;
  bool hasPendingOrFailedPayment = false;
  Map<String, dynamic> pendingOrFailedPayment = {};
  DateTime? nextDueDate;
  bool isPaymentUpToDate = false;

  // Razorpay
  late Razorpay _razorpay;
  int? currentPaymentId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    init();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (currentPaymentId != null) {
      try {
        // Update payment status to COMPLETED
        await ApiService.updatePaymentStatus(
          paymentId: currentPaymentId!,
          status: 'COMPLETED',
          transactionId: response.paymentId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh data
        await init();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Payment Error!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    if (currentPaymentId != null) {
      try {
        // Update payment status to FAILED
        await ApiService.updatePaymentStatus(
          paymentId: currentPaymentId!,
          status: 'FAILED',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Payment failed: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Refresh data
        await init();
      } catch (e) {
        return;
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> init() async {
    setState(() => isLoading = true);

    try {
      totalStudents = await AdminApiService.countStudentUsernames(
        widget.schoolId,
      );
      schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      paymentInfo = await ApiService.getDueAmount(schoolId: widget.schoolId);

      // Load payment history
      await loadHistory();

      // Calculate amount for selected plan
      await calculateAmount();
    } catch (e) {
      setState(() => isLoading = false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadHistory() async {
    try {
      final history = await ApiService.getPaymentHistory(widget.schoolId);

      setState(() {
        paymentHistory = history;
      });

      // Check payment status
      checkPaymentStatus();
    } catch (e) {
      return;
    }
  }

  void checkPaymentStatus() {
    // Find PENDING or FAILED payment
    try {
      pendingOrFailedPayment = paymentHistory.firstWhere(
        (payment) =>
            payment['status'] == 'PENDING' || payment['status'] == 'FAILED',
      );
      hasPendingOrFailedPayment = true;

      // Auto-fill data from pending/failed payment
      setState(() {
        selectedPlan = pendingOrFailedPayment['paymentPlan'];
        calculatedAmount = pendingOrFailedPayment['amount'].toDouble();
      });
    } catch (e) {
      // No pending or failed payment found
      hasPendingOrFailedPayment = false;
      pendingOrFailedPayment = {};
    }

    // Check for completed payment
    final completedPayments =
        paymentHistory
            .where((payment) => payment['status'] == 'COMPLETED')
            .toList();

    if (completedPayments.isNotEmpty) {
      hasCompletedPayment = true;

      // Sort by period end date to get the latest
      completedPayments.sort((a, b) {
        DateTime dateA = DateTime.parse(a['periodEnd']);
        DateTime dateB = DateTime.parse(b['periodEnd']);
        return dateB.compareTo(dateA);
      });

      final latestPayment = completedPayments.first;
      DateTime periodEndDate = DateTime.parse(latestPayment['periodEnd']);

      // Get school's due date
      if (schoolData.isNotEmpty && schoolData[0]['dueDate'] != null) {
        DateTime schoolDueDate = DateTime.parse(schoolData[0]['dueDate']);

        // Check if payment is up to date (periodEnd == dueDate)
        if (periodEndDate.year == schoolDueDate.year &&
            periodEndDate.month == schoolDueDate.month &&
            periodEndDate.day == schoolDueDate.day) {
          isPaymentUpToDate = true;
          nextDueDate = schoolDueDate;
        }
      }
    }
  }

  Future<void> calculateAmount() async {
    try {
      final result = await ApiService.calculatePayment(
        studentsCount: totalStudents,
        paymentPlan: selectedPlan,
      );
      setState(() {
        calculatedAmount = result['amount'].toDouble();
      });
    } catch (e) {
      return;
    }
  }

  Future<void> initiatePayment() async {
    try {
      Map<String, dynamic> payment;

      if (hasPendingOrFailedPayment) {
        // Use existing pending/failed payment
        payment = pendingOrFailedPayment;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Using existing ${pendingOrFailedPayment['status'].toLowerCase()} payment',
            ),
          ),
        );
      } else {
        // Create new payment record
        payment = await ApiService.createPayment(
          schoolId: int.parse(widget.schoolId),
          studentsCount: totalStudents,
          paymentPlan: selectedPlan,
        );
      }

      // Store payment ID for callback
      currentPaymentId = payment['id'];

      // Open Razorpay
      openRazorpay(payment);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void openRazorpay(Map<String, dynamic> payment) {
    var options = {
      'key':
          'rzp_live_RTDsYRSviCdE7N', // Replace with your Razorpay key (rzp_test_XXXXX or rzp_live_XXXXX)
      'amount': (payment['amount'] * 100).toInt(), // Amount in paise
      'name': 'Ramchin Smart School',
      'description':
          '${payment['paymentPlan']} Payment - ${payment['studentsCount']} Students',
      'prefill': {'contact': '', 'email': ''},
      'theme': {
        'color': '#2B7CA8', // Your app color
      },
      'notes': {
        'school_id': widget.schoolId,
        'payment_id': payment['id'].toString(),
        'payment_plan': payment['paymentPlan'],
        'students_count': payment['studentsCount'].toString(),
        'paid_by': widget.username,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening payment gateway: $e')),
      );
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'App Payment',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'App Payment',
                    onBack: () {
                      onWillPop();
                    },
                  ),
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      schoolCard(
                        context: context,
                        schoolData: schoolData,
                        totalStudents: totalStudents,
                      ),

                      SizedBox(height: 16),

                      // Payment Up-to-Date Status Card
                      if (isPaymentUpToDate && nextDueDate != null)
                        paymentPaidCard(
                          nextDueDate: nextDueDate!,
                          isPaymentUpToDate: isPaymentUpToDate,
                        ),

                      // Pending/Failed Payment Alert
                      if (hasPendingOrFailedPayment)
                        failedOrPendingCard(
                          pendingOrFailedPayment: pendingOrFailedPayment,
                          hasPendingOrFailedPayment: hasPendingOrFailedPayment,
                          isPaymentUpToDate: isPaymentUpToDate,
                        ),

                      if (hasPendingOrFailedPayment || isPaymentUpToDate)
                        SizedBox(height: 16),

                      // Trial Status Card (only show if not paid up to date)
                      if (!isPaymentUpToDate && paymentInfo != null)
                        freeTrialCard(
                          paymentInfo: paymentInfo!,
                          isPaymentUpToDate: isPaymentUpToDate,
                        ),

                      if (!isPaymentUpToDate && paymentInfo != null)
                        SizedBox(height: 16),

                      // Payment Plan Selection
                      // Show if: NOT paid up to date (allows new payments OR pending/failed retries)
                      if (!isPaymentUpToDate) // ✅ Changed: Removed the isEmpty check
                        pendingPaymentCard(
                          selectedPlan: selectedPlan,
                          calculatedAmount: calculatedAmount,
                          hasPendingOrFailedPayment: hasPendingOrFailedPayment,
                          pendingOrFailedPayment: pendingOrFailedPayment,
                          initiatePayment: initiatePayment,
                          calculateAmount: calculateAmount,
                        ),

                      SizedBox(height: 16),

                      // Payment History
                      if (paymentHistory.isNotEmpty)
                        paymentHistorys(paymentHistory: paymentHistory),
                    ],
                  ),
                ),
      ),
    );
  }
}
