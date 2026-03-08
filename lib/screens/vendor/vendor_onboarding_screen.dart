import 'package:flutter/material.dart';

class VendorOnboardingScreen extends StatelessWidget {
  const VendorOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          _buildPage('Welcome to Cheteni Vendor', 'Sell your products directly to customers', Icons.store),
          _buildPage('Easy Registration', 'Register with your details and start selling', Icons.app_registration),
          _buildPage('Manage Orders', 'Track and manage all your orders in one place', Icons.shopping_cart),
          _buildPage('Secure Payments', 'Receive payments directly to your M-Pesa account', Icons.payment),
        ],
      ),
    );
  }

  Widget _buildPage(String title, String subtitle, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.white),
          const SizedBox(height: 30),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
