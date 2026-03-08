import 'package:cheteni_delivery/providers/agent_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersonnelSelectionModal extends StatelessWidget {
  final Function(String) onSelect;

  const PersonnelSelectionModal({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final availablePersonnel = agentProvider.personnel
        .where((p) => p['status'] == 'Available')
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Personnel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...availablePersonnel.map((person) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(person['name'] ?? ''),
                  subtitle: Text('Vehicle: ${person['plate_number'] ?? ''}'),
                  trailing: Chip(
                    label: Text(person['status'] ?? ''),
                    backgroundColor: Colors.green,
                  ),
                  onTap: () {
                    onSelect(person['id']);
                  },
                ),
              )).toList(),
        ],
      ),
    );
  }
}
