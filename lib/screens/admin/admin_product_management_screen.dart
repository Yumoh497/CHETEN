import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminProductManagementScreen extends StatefulWidget {
  const AdminProductManagementScreen({super.key});

  @override
  State<AdminProductManagementScreen> createState() => _AdminProductManagementScreenState();
}

class _AdminProductManagementScreenState extends State<AdminProductManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: adminProvider.products.length,
              itemBuilder: (context, index) {
                final product = adminProvider.products[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(product['name'] ?? ''),
                    subtitle: Text(
                        'KSh ${product['price'] ?? '0.00'}/${product['unit'] ?? 'N/A'}\nStock: ${product['stock'] ?? 'N/A'}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(child: Text('Edit'), value: 'edit'),
                        const PopupMenuItem(child: Text('Delete'), value: 'delete'),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          if (!mounted) return;
                          Navigator.pushNamed(context, '/admin_edit_product',
                              arguments: product);
                        } else if (value == 'delete') {
                          final success = await adminProvider.deleteProduct(
                              product['id'], authProvider.authToken!);
                          
                          if (!mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product deleted successfully')),
                            );
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to delete product')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin_edit_product');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
