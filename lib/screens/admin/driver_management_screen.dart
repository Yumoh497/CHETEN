import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DriverManagementScreen extends StatelessWidget {
  const DriverManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: adminProvider.drivers.length,
              itemBuilder: (context, index) {
                final driver = adminProvider.drivers[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(driver['name'] ?? ''),
                    subtitle: Text(
                        '${driver['phone'] ?? ''}\nRating: ${driver['rating']?.toStringAsFixed(1) ?? 'N/A'} ⭐'),
                    trailing: Chip(
                      label: Text(driver['status'] ?? ''),
                      backgroundColor: _getStatusColor(driver['status'] ?? ''),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/driver_detail',
                        arguments: driver,
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/driver_registration');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Busy':
        return Colors.orange;
      case 'Offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
