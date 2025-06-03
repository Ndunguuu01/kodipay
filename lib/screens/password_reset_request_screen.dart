import 'package:flutter/material.dart';
import 'package:kodipay/services/api.dart';

class PasswordResetRequestScreen extends StatefulWidget {
  const PasswordResetRequestScreen({Key? key}) : super(key: key);

  @override
  _PasswordResetRequestScreenState createState() => _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState extends State<PasswordResetRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _error = null;
    });

    try {
      final response = await ApiService.post(
        '/auth/request-password-reset',
        {
          'email': _emailController.text.isNotEmpty ? _emailController.text : null,
          'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Password reset email sent. Please check your inbox.';
        });
      } else {
        setState(() {
          _error = 'Failed to send password reset email.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Password Reset')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if ((value == null || value.isEmpty) && _phoneController.text.isEmpty) {
                    return 'Please enter email or phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if ((value == null || value.isEmpty) && _emailController.text.isEmpty) {
                    return 'Please enter email or phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_message != null) Text(_message!, style: const TextStyle(color: Colors.green)),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Send Reset Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
