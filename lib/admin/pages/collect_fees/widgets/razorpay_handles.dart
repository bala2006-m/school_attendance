// // Razorpay payment success handler.
// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
//
// import '../collect_student_fees.dart';
//
// void handlePaymentSuccess(PaymentSuccessResponse response) async {
//   // You can add payment record creation API call here.
//   showSnack(
//     'Razorpay payment successful: ${response.paymentId}',
//     color: Colors.green,
//     icon: Icons.check_circle,
//   );
//
//   // Refresh payments for the selected student to update payment status
//   // if (CollectStudentFeesState.selectedStudentIndex != null) {
//   //   // final username = CollectStudentFeesState.students[CollectStudentFeesState.selectedStudentIndex!]['username'];
//   //   // await fetchStudentFees(username: username);
//   // }
// }
//
// void handlePaymentError(PaymentFailureResponse response) {
//   showSnack(
//     'Payment failed: ${response.message}',
//     color: Colors.red,
//     icon: Icons.error,
//   );
// }
//
// void handleExternalWallet(ExternalWalletResponse response) {
//   showSnack(
//     'External wallet selected: ${response.walletName}',
//     color: Colors.deepPurple,
//     icon: Icons.account_balance_wallet,
//   );
// }
//
// void payWithRazorpay(int amount) {
//   var options = {
//     'key': 'rzp_live_RTDsYRSviCdE7N',
//     'amount': amount * 100, // amount in paise
//     'name': 'School Attendance',
//     'description': 'Fee Payment',
//     'prefill': {'contact': '', 'email': ''},
//   };
//   try {
//     CollectStudentFeesState.razorpay?.open(options);
//   } catch (e) {
//
//   }
// }
