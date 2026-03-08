import 'package:cheteni_delivery/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DriverProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final profile = driverProvider.driverProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: driverProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileRow('Name', profile?['name'] ?? ''),
                          _buildProfileRow('Phone', profile?['phone'] ?? ''),
                          _buildProfileRow(
                              'Vehicle', profile?['plate_number'] ?? ''),
                          _buildProfileRow('Route', profile?['route'] ?? ''),
                          _buildProfileRow('Rating',
                              '${profile?['rating']?.toStringAsFixed(1) ?? 'N/A'} ⭐'),
                          _buildProfileRow('Deliveries',
                              '${profile?['deliveries']?.toString() ?? '0'}'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Edit Profile'),
                          content: Text('Profile editing feature coming soon'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK')),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('Edit Profile'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
