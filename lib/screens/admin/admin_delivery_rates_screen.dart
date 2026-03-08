import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDeliveryRatesScreen extends StatefulWidget {
  const AdminDeliveryRatesScreen({super.key});

  @override
  State<AdminDeliveryRatesScreen> createState() => _AdminDeliveryRatesScreenState();
}

class _AdminDeliveryRatesScreenState extends State<AdminDeliveryRatesScreen> {
  Future<void> _editRate(BuildContext context, String location, double currentRate) async {
    final rateController = TextEditingController(text: currentRate.toString());
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final adminAuthProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Rate for $location'),
        content: TextField(
          controller: rateController,
          decoration: const InputDecoration(labelText: 'New Rate'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newRate = double.tryParse(rateController.text);
              if (newRate != null) {
                final success = await adminProvider.updateDeliveryRates(
                  {location: newRate},
                  adminAuthProvider.authToken!,
                );
                if (!mounted) return;
                if (success) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update rate')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final rates = adminProvider.deliveryRates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Rates'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: rates.length,
              itemBuilder: (context, index) {
                String location = rates.keys.elementAt(index);
                // The rates can be of type int or double, so we need to handle both
                final rateValue = rates[location];
                final rateAsDouble = (rateValue is int) ? rateValue.toDouble() : (rateValue ?? 0.0);

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(location),
                    subtitle: Text('KSh $rateAsDouble'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editRate(context, location, rateAsDouble);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
