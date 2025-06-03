import 'package:flutter/material.dart';
import 'package:kodipay/services/api.dart';

class PasswordResetScreen extends StatefulWidget {
  final String resetToken;

  const PasswordResetScreen({Key? key, required this.resetToken}) : super(key: key);

  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
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
      final response = await ApiService.put(
        '/auth/reset-password/${widget.resetToken}',
        {
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Password reset successful. You can now log in with your new password.';
        });
      } else {
        setState(() {
          _error = 'Failed to reset password.';
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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
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
                child: _isLoading ? const CircularProgressIndicator() : const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
