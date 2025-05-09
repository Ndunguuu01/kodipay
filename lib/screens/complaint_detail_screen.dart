import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/models/complaint.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/complaint_provider.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.complaint.title;
    _descriptionController.text = widget.complaint.description;
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    await complaintProvider.updateComplaintStatus(widget.complaint.id, status, context);

    if (complaintProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint status updated')),
      );
      context.go('/tenant-home/complaints');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(complaintProvider.errorMessage!)),
      );
    }
  }

  Future<void> _editComplaint(BuildContext context) async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await complaintProvider.editComplaint(widget.complaint.id, title, description, context);

    if (complaintProvider.errorMessage == null) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint updated')),
      );
      context.go('/tenant-home/complaints');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(complaintProvider.errorMessage!)),
      );
    }
  }

  Future<void> _deleteComplaint(BuildContext context) async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    await complaintProvider.deleteComplaint(widget.complaint.id, context);

    if (complaintProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint deleted')),
      );
      context.go('/tenant-home/complaints');
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isLandlord = authProvider.auth?.role == 'landlord';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: const Color(0xFF90CAF9),
        actions: [
          if (!isLandlord && widget.complaint.status == 'pending')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
            ),
          if (!isLandlord)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteComplaint(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing)
              Column(
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
                    onPressed: () => _editComplaint(context),
                    child: const Text('Save Changes'),
                  ),
                ],
              )
            else ...[
              Text(
                widget.complaint.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(widget.complaint.description),
              const SizedBox(height: 20),
              Text('Status: ${widget.complaint.status}'),
              const SizedBox(height: 10),
              Text(
                'Submitted At: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.complaint.submittedAt)}',
              ),
              const SizedBox(height: 10),
              Text(
                'Resolved At: ${widget.complaint.resolvedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.complaint.resolvedAt!) : 'Not resolved'}',
              ),
              const SizedBox(height: 10),
              Text(
                'Resolution Notes: ${widget.complaint.resolutionNotes ?? 'No notes provided'}',
              ),
              const SizedBox(height: 20),
              if (isLandlord && widget.complaint.status == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateStatus(context, 'resolved'),
                      child: const Text('Mark as Resolved'),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}