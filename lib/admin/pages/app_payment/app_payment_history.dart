import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/api_service.dart';

class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key, required this.schoolId});
  final String schoolId;

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  List<dynamic> paymentHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final history = await ApiService.getPaymentHistory(widget.schoolId);
      setState(() {
        paymentHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment History')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : paymentHistory.isEmpty
              ? Center(child: Text('No payment history'))
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: paymentHistory.length,
                itemBuilder: (context, index) {
                  final payment = paymentHistory[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        '${payment['paymentPlan']} - ₹${payment['amount']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Students: ${payment['studentsCount']}'),
                          Text(
                            'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(payment['paidAt']))}',
                          ),
                          if (payment['transactionId'] != null)
                            Text('Transaction ID: ${payment['transactionId']}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(payment['status']),
                        backgroundColor:
                            payment['status'] == 'COMPLETED'
                                ? Colors.green
                                : payment['status'] == 'FAILED'
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
