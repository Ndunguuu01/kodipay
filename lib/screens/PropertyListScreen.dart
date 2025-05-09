import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/auth_provider.dart'; 
import 'package:kodipay/screens/add_property_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      final landlordId = authProvider.auth?.id ?? '';
      print('Logged in landlordId: $landlordId');

      if (landlordId.isNotEmpty) {
        propertyProvider.fetchProperties(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final properties = context.watch<PropertyProvider>().properties;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Properties')),
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : properties.isEmpty
              ? const Center(child: Text("No properties found."))
              : ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return ListTile(
                      title: Text(property.name),
                      subtitle: Text('${property.occupiedRooms}/${property.totalRooms} rooms occupied'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Property'),
                              content: const Text('Are you sure you want to delete this property?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await propertyProvider.deleteProperty(property.id, context);
                          }
                        },
                      ),
                      onTap: () {
                        context.go('/landlord-home/properties/${property.id}');
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddPropertyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
