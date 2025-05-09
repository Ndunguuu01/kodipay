import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/payment_provider.dart';
import 'package:intl/intl.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<PaymentProvider>(context, listen: false)
        .fetchPayments(authProvider.auth!.id, context);
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: paymentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentProvider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(paymentProvider.errorMessage!),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          paymentProvider.clearError();
                          paymentProvider.fetchPayments(authProvider.auth!.id, context);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : paymentProvider.payments.isEmpty
                  ? const Center(child: Text('No receipts found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: paymentProvider.payments.length,
                      itemBuilder: (context, index) {
                        final payment = paymentProvider.payments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text('Payment of KES ${payment.amount}'),
                            subtitle: Text(
                              'Date: ${DateFormat('dd/MM/yyyy').format(payment.paymentDate)}',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}