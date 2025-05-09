import 'package:flutter/material.dart';

class GeneralInvoiceScreen extends StatelessWidget {
  const GeneralInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Invoice'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: const Center(
        child: Text('General Invoice Screen - To be implemented'),
      ),
    );
  }
}