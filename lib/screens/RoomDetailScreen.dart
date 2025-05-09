import 'package:flutter/material.dart';

class RoomDetailScreen extends StatelessWidget {
  final Room room;
  final Tenant? tenant;

  const RoomDetailScreen({required this.room, this.tenant, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(room.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room Name: ${room.name}'),
            Text('Occupied: ${room.occupied ? 'Yes' : 'No'}'),
            if (tenant != null) ...[
              const SizedBox(height: 20),
              Text('Tenant Info', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Name: ${tenant!.name}'),
              Text('Phone: ${tenant!.phone}'),
              Text('Email: ${tenant!.email}'),
            ]
          ],
        ),
      ),
    );
  }
}
