import 'package:cheteni_delivery/providers/agent_provider.dart';
import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PricingManagementScreen extends StatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  State<PricingManagementScreen> createState() =>
      _PricingManagementScreenState();
}

class _PricingManagementScreenState extends State<PricingManagementScreen> {
  Map<String, double> _productPrices = {};

  @override
  void initState() {
    super.initState();
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    agentProvider.fetchProductPricing(authToken: authProvider.authToken);
    _productPrices = agentProvider.productPricing;
  }

  Future<void> _savePrices() async {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await agentProvider.updateProductPricing(
        _productPrices, authProvider.authToken!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update prices')),
      );
    }
  }

  void _editPrice(String product) {
    final controller = TextEditingController(text: _productPrices[product].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Price for $product'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Price per KG'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _productPrices[product] =
                    double.tryParse(controller.text) ?? _productPrices[product]!;
              });
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
    final agentProvider = Provider.of<AgentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: agentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Manage product prices for your market',
                      style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _productPrices.length,
                    itemBuilder: (context, index) {
                      String product = _productPrices.keys.elementAt(index);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(product),
                          subtitle: Text(
                              'Current price: KSh ${_productPrices[product]} per KG'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editPrice(product),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _savePrices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Save All Changes'),
                  ),
                ),
              ],
            ),
    );
  }
}
