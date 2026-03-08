import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RatePersonnelScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  RatePersonnelScreen({required this.order});

  @override
  _RatePersonnelScreenState createState() => _RatePersonnelScreenState();
}

class _RatePersonnelScreenState extends State<RatePersonnelScreen> {
  int rating = 0;
  final _reviewController = TextEditingController();

  Future<void> _submitRating() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await orderProvider.ratePersonnel(
      widget.order['delivery_personnel']['phone'],
      authProvider.userData!['phone'],
      rating,
      _reviewController.text,
      authProvider.authToken!,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thank you for your rating!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final personnel = widget.order['delivery_personnel'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Driver'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      personnel?['name'] ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Vehicle: ${personnel?['plate_number'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'How was your delivery experience?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: IconButton(
                    onPressed: () => setState(() => rating = index + 1),
                    icon: Icon(
                      Icons.star,
                      size: 50,
                      color:
                          index < rating ? Colors.orange : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            if (rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                rating == 1
                    ? 'Poor'
                    : rating == 2
                        ? 'Fair'
                        : rating == 3
                            ? 'Good'
                            : rating == 4
                                ? 'Very Good'
                                : 'Excellent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
            const SizedBox(height: 30),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: 'Write a review (optional)',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: rating > 0 ? _submitRating : null,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Submit Rating',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
