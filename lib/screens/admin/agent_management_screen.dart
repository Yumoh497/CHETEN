import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgentManagementScreen extends StatelessWidget {
  const AgentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: adminProvider.agents.length,
              itemBuilder: (context, index) {
                final agent = adminProvider.agents[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.business, color: Colors.white),
                    ),
                    title: Text(agent['name'] ?? ''),
                    subtitle: Text(
                        '${agent['email'] ?? ''}\n${agent['market_location'] ?? ''}'),
                    trailing: Chip(
                      label: Text(agent['status'] ?? ''),
                      backgroundColor:
                          agent['status'] == 'Active' ? Colors.green : Colors.red,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/agent_detail',
                        arguments: agent,
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/agent_registration');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
