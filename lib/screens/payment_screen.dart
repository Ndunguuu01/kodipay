import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedMethod = 'M-Pesa';

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    if (_selectedMethod == 'M-Pesa') {
      await paymentProvider.initiateMpesaPayment(
        phone: _phoneController.text,
        amount: double.parse(_amountController.text),
        context: context,
      );
      if (paymentProvider.mpesaError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('M-Pesa Error: ${paymentProvider.mpesaError}')),
        );
      } else if (paymentProvider.mpesaStatus != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paymentProvider.mpesaStatus!)),
        );
      }
    } else {
      // Handle other payment methods if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only M-Pesa is supported in this demo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'KES ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+254 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (_selectedMethod == 'M-Pesa') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^2547\d{8} ').hasMatch(value)) {
                      return 'Enter a valid Safaricom number (e.g. 2547XXXXXXXX)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                items: ['M-Pesa', 'Card', 'Bank Transfer']
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                ),
              ),
              const SizedBox(height: 30),
              Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  return paymentProvider.mpesaLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitPayment,
                          child: const Text('Submit Payment'),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
