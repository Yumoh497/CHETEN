import 'package:cheteni_delivery/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({Key? key}) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(product?['name'] ?? 'Product Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product?['image'] != null
                    ? Image.network(
                        product!['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.green.shade100,
                            child: Icon(
                              Icons.local_florist,
                              size: 80,
                              color: Colors.green.shade400,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.green.shade100,
                        child: Icon(
                          Icons.local_florist,
                          size: 80,
                          color: Colors.green.shade400,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              product?['name'] ?? 'Product Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'KSh ${product?['price'] ?? 0}/${product?['unit'] ?? 'KG'}',
              style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (product?['origin'] != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Origin: ${product?['origin']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 12),
            Text(
              product?['description'] ?? 'Fresh and high quality produce delivered straight from the farm to your doorstep.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (product?['nutrition'] != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.green.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nutrition: ${product?['nutrition']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 30),
            Row(
              children: [
                Text('Quantity: ', style: TextStyle(fontSize: 18)),
                IconButton(
                  onPressed: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                  icon: Icon(Icons.remove_circle_outline),
                ),
                Text('$quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => quantity++),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                orderProvider.addToCart({
                  'product_id': product?['id'],
                  'quantity': quantity,
                  'price': product?['price'],
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $quantity ${product?['name']} to cart')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                  'Add to Cart - KSh ${((product?['price'] ?? 0) * quantity).toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
    );
  }
}
