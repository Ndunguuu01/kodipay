import 'package:flutter/material.dart';

class PaidHousesScreen extends StatelessWidget {
  const PaidHousesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paid Houses'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: const Center(
        child: Text('Paid Houses Screen - To be implemented'),
      ),
    );
  }
}