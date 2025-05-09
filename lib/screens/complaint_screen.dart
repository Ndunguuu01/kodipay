import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/complaint_provider.dart';
import 'package:kodipay/providers/lease_provider.dart';


class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    complaintProvider.fetchComplaints(authProvider.auth!.id, context);
  }

  Future<void> _submitComplaint(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final leaseProvider = Provider.of<LeaseProvider>(context, listen: false);
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);

    if (authProvider.auth == null || leaseProvider.lease == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lease found. Cannot submit complaint.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    await complaintProvider.submitComplaint(
      title,
      description,
      authProvider.auth!.id,
      leaseProvider.lease!.propertyId, // Use the first lease's propertyId
      context,
    );

    if (complaintProvider.errorMessage == null) {
      _titleController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(complaintProvider.errorMessage!)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        backgroundColor: const Color(0xFF90CAF9),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/tenant-home/add-complaint');
            },
          ),
        ],
      ),
      body: complaintProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : complaintProvider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(complaintProvider.errorMessage!),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          complaintProvider.clearError();
                          complaintProvider.fetchComplaints(authProvider.auth!.id, context);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Complaint Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _submitComplaint(context),
                            child: const Text('Submit Complaint'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: complaintProvider.complaints.isEmpty
                          ? const Center(child: Text('No complaints found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: complaintProvider.complaints.length,
                              itemBuilder: (context, index) {
                                final complaint = complaintProvider.complaints[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(
                                    title: Text(complaint.title),
                                    subtitle: Text(complaint.description),
                                    trailing: Text(complaint.status),
                                    onTap: () {
                                      // Navigate to ComplaintDetailScreen if needed
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}