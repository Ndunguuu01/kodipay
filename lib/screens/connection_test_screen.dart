import 'package:flutter/material.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/utils/logger.dart';
import 'package:flutter/foundation.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResult;
  String? _error;
  DateTime? _lastCheck;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    setState(() {
      _isConnected = ApiService.isConnected;
      _lastCheck = ApiService.lastConnectionCheck;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
      _error = null;
    });

    try {
      final result = await ApiService.testConnection();
      setState(() {
        _testResult = result;
        _isLoading = false;
        _isConnected = result['success'] ?? false;
        _lastCheck = DateTime.now();
      });
    } catch (e) {
      Logger.error('Error during connection test: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isConnected = false;
      });
    }
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'API Endpoint: ${ApiService.baseUrl}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Environment: ${kReleaseMode ? 'Production' : kDebugMode ? 'Development' : 'Staging'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_lastCheck != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last Check: ${_lastCheck!.toLocal().toString()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult() {
    if (_testResult == null) return const SizedBox.shrink();

    return Card(
      color: _testResult!['success'] ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _testResult!['message'],
              style: TextStyle(
                color: _testResult!['success'] ? Colors.green.shade900 : Colors.red.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_testResult!['version'] != null) ...[
              const SizedBox(height: 8),
              Text('Version: ${_testResult!['version']}'),
            ],
            if (_testResult!['environment'] != null) ...[
              const SizedBox(height: 4),
              Text('Environment: ${_testResult!['environment']}'),
            ],
            if (_testResult!['latency'] != null) ...[
              const SizedBox(height: 4),
              Text('Latency: ${_testResult!['latency']}ms'),
            ],
            if (_testResult!['error'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${_testResult!['error']}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    if (_error == null) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error Details',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _testConnection,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _testConnection,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Connection'),
            ),
            const SizedBox(height: 16),
            _buildTestResult(),
            const SizedBox(height: 16),
            _buildErrorCard(),
          ],
        ),
      ),
    );
  }
} 