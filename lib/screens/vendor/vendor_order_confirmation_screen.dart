import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cheteni_delivery/providers/order_provider.dart';

class VendorOrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  const VendorOrderConfirmationScreen({super.key, required this.orderId});

  @override
  State<VendorOrderConfirmationScreen> createState() => _VendorOrderConfirmationScreenState();
}

class _VendorOrderConfirmationScreenState extends State<VendorOrderConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order'), backgroundColor: Colors.green),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${widget.orderId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: orderProvider.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = orderProvider.cartItems[index];
                            return ListTile(
                              title: Text(item['product_name'] ?? 'Product'),
                              subtitle: Text('Qty: ${item['quantity']}'),
                              trailing: Text('KSh ${item['price']}'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => _confirmOrder(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Confirm Items Picked', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmOrder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order confirmed!')));
    Navigator.pop(context);
  }
}
