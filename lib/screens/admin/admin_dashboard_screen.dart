import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:cheteni_delivery/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminAuthProvider = Provider.of<AdminAuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    // Fetch data when the screen is built
    if (adminAuthProvider.isAdminLoggedIn && adminAuthProvider.authToken != null) {
      adminProvider.fetchAdminData(adminAuthProvider.authToken!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) => NotificationBadge(
              child: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              adminAuthProvider.logoutAdmin();
              Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
        ],
      ),
      endDrawer: const NotificationPanel(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 40, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome ${adminAuthProvider.adminData?['username'] ?? 'Admin'}!',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text('System administration & management'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Quick Stats
              if (!adminProvider.isLoading && adminProvider.reports.isNotEmpty)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Orders',
                            '${adminProvider.reports['total_orders'] ?? 0}',
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Sales',
                            'KSh ${(adminProvider.reports['total_sales'] ?? 0).toStringAsFixed(0)}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Active Drivers',
                            '${adminProvider.reports['active_drivers'] ?? 0}',
                            Icons.delivery_dining,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pending Orders',
                            '${adminProvider.reports['pending_orders'] ?? 0}',
                            Icons.pending_actions,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              Expanded(
                child: adminProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        children: [
                          _buildFeatureCard(
                            context,
                            'Order Management',
                            Icons.receipt_long,
                            Colors.blue,
                            () => Navigator.pushNamed(context, '/order_management'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Customer Management',
                            Icons.people,
                            Colors.purple,
                            () => Navigator.pushNamed(context, '/customer_management'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Agent Management',
                            Icons.people_alt,
                            Colors.blue,
                            () => Navigator.pushNamed(context, '/agent_management'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Driver Management',
                            Icons.delivery_dining,
                            Colors.green,
                            () => Navigator.pushNamed(context, '/driver_management'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Payout Management',
                            Icons.payment,
                            Colors.orange,
                            () => Navigator.pushNamed(context, '/payout_management'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Product Management',
                            Icons.shopping_basket,
                            Colors.teal,
                            () => Navigator.pushNamed(context, '/product_management'),
                          ),
                          _buildFeatureCard(
                            context,
                            'System Reports',
                            Icons.bar_chart,
                            Colors.indigo,
                            () => Navigator.pushNamed(context, '/reports'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Delivery Rates',
                            Icons.price_change,
                            Colors.amber,
                            () => Navigator.pushNamed(context, '/delivery_rates'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Commodity Prices',
                            Icons.local_grocery_store,
                            Colors.brown,
                            () => Navigator.pushNamed(context, '/commodity_prices'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Financial Management',
                            Icons.account_balance_wallet,
                            Colors.teal,
                            () => Navigator.pushNamed(context, '/financial_management'),
                          ),
                          _buildFeatureCard(
                            context,
                            'Change Password',
                            Icons.lock,
                            Colors.grey,
                            () => Navigator.pushNamed(context, '/admin_change_password'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
