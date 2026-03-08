import 'package:cheteni_delivery/providers/agent_provider.dart';
import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersonnelManagementScreen extends StatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  State<PersonnelManagementScreen> createState() => _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState extends State<PersonnelManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personnel Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: agentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: agentProvider.personnel.length,
              itemBuilder: (context, index) {
                final person = agentProvider.personnel[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.delivery_dining, color: Colors.white),
                    ),
                    title: Text(person['name'] ?? ''),
                    subtitle: Text(
                        '${person['phone'] ?? ''}\n${person['plate_number'] ?? ''}'),
                    trailing: Chip(
                      label: Text(person['status'] ?? ''),
                      backgroundColor: person['status'] == 'Available'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text('Change Status'),
                                content: Text(
                                    'Change status for ${person['name'] ?? ''}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () async {
                                      final newStatus = person['status'] == 'Available'
                                          ? 'Busy'
                                          : 'Available';
                                      final success = await agentProvider.updatePersonnelStatus(
                                          person['id'], newStatus, authProvider.authToken!);
                                      
                                      if (!mounted) return;

                                      if (success) {
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to update status')),
                                        );
                                      }
                                    },
                                    child: const Text('Change'),
                                  ),
                                ],
                              ));
                    },
                  ),
                );
              },
            ),
    );
  }
}
