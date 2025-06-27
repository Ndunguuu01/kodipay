import 'package:flutter/material.dart';

class DirectMessageErrorScreen extends StatelessWidget {
  final String recipientId;

  const DirectMessageErrorScreen({super.key, required this.recipientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Message Error'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'The phone number parameter is missing for recipient ID: \$recipientId.\n'
            'Please provide a valid phone number to open the direct message.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
