import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order?['id'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Customer: ${order?['customer']?['name'] ?? 'N/A'}'),
            Text('Amount: KSh ${order?['total_price'] ?? 0}'),
            Text('Status: ${order?['status'] ?? 'N/A'}'),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await driverProvider.updateOrderStatus(
                        order!['customer']['phone'],
                        'In Transit',
                        authProvider.userData!['name'],
                        authProvider.authToken!,
                      );
                      if (success) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Pick Up'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/delivery_confirmation', arguments: order);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Deliver'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
