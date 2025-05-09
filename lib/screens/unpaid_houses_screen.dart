import 'package:flutter/material.dart';

class UnpaidHousesScreen extends StatelessWidget {
  const UnpaidHousesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid Houses'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: const Center(
        child: Text('Unpaid Houses Screen - To be implemented'),
      ),
    );
  }
}