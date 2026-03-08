import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommodityPriceManagementScreen extends StatelessWidget {
  const CommodityPriceManagementScreen({super.key});

  Future<void> _editPrice(BuildContext context, String commodity, double currentPrice) async {
    final priceController = TextEditingController(text: currentPrice.toString());
    // In a real app, you would use a provider to update the price
    // final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Price for $commodity'),
        content: TextField(
          controller: priceController,
          decoration: const InputDecoration(labelText: 'Price per KG'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: Call provider to update price
              Navigator.pop(context);
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
    // Using a placeholder for now, as the API doesn't provide this yet.
    final Map<String, double> prices = {
      'Rice': 50.0,
      'Maize': 45.0,
      'Beans': 80.0,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commodity Prices'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: prices.length,
              itemBuilder: (context, index) {
                String commodity = prices.keys.elementAt(index);
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(commodity),
                    subtitle: Text('KSh ${prices[commodity]} per KG'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editPrice(context, commodity, prices[commodity] ?? 0.0),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
