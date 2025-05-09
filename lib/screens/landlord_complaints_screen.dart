import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/complaint_provider.dart';

class LandlordComplaintsScreen extends StatefulWidget {
  const LandlordComplaintsScreen({super.key});

  @override
  State<LandlordComplaintsScreen> createState() => _LandlordComplaintsScreenState();
}

class _LandlordComplaintsScreenState extends State<LandlordComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    complaintProvider.fetchLandlordComplaints(authProvider.auth!.id, context);
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Landlord Complaints'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: complaintProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : complaintProvider.errorMessage != null
              ? Center(child: Text(complaintProvider.errorMessage!))
              : complaintProvider.complaints.isEmpty
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
                          ),
                        );
                      },
                    ),
    );
  }
}