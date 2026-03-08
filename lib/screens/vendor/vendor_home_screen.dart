import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cheteni_delivery/providers/wallet_provider.dart';
import 'package:cheteni_delivery/providers/auth_provider.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    if (authProvider.isLoggedIn && authProvider.userData != null) {
      final vendorId = authProvider.userData!['id']?.toString() ??
          authProvider.userData!['vendor_id']?.toString() ??
          authProvider.userData!['phone'] ??
          '';

      if (vendorId.isNotEmpty && authProvider.authToken != null) {
        await walletProvider.fetchWalletData(
          'vendor',
          vendorId,
          authProvider.authToken!,
        );
      }
    }

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Consumer<WalletProvider>(
                builder: (context, walletProvider, _) {
                  if (walletProvider.isLoading && !_isInitialized) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'KSh ${walletProvider.walletData?['balance']?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _buildMenuCard(
                    context,
                    'Confirm Pickup',
                    Icons.check_circle,
                    Colors.teal,
                    '/vendor_confirm_pickup',
                  ),
                  _buildMenuCard(
                    context,
                    'My QR Code',
                    Icons.qr_code_2,
                    Colors.indigo,
                    '/vendor_my_qr',
                  ),
                  _buildMenuCard(
                    context,
                    'My Orders',
                    Icons.shopping_bag,
                    Colors.blue,
                    '/vendor_orders',
                  ),
                  _buildMenuCard(
                    context,
                    'Wallet',
                    Icons.wallet_giftcard,
                    Colors.orange,
                    '/vendor_wallet',
                  ),
                  _buildMenuCard(
                    context,
                    'Place Order',
                    Icons.add_shopping_cart,
                    Colors.green,
                    '/vendor_place_order',
                  ),
                  _buildMenuCard(
                    context,
                    'Profile',
                    Icons.person,
                    Colors.purple,
                    '/vendor_profile',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.lerp(color, Colors.black, 0.25) ?? color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
