import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:cheteni_delivery/providers/agent_provider.dart';
import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/providers/driver_provider.dart';
import 'package:cheteni_delivery/providers/order_provider.dart';
import 'package:cheteni_delivery/providers/product_provider.dart';
import 'package:cheteni_delivery/providers/wallet_provider.dart';
import 'package:cheteni_delivery/screens/admin/admin_change_password_screen.dart';
import 'package:cheteni_delivery/screens/admin/admin_dashboard_screen.dart';
import 'package:cheteni_delivery/screens/admin/admin_delivery_rates_screen.dart';
import 'package:cheteni_delivery/screens/admin/admin_edit_product_screen.dart';
import 'package:cheteni_delivery/screens/admin/admin_login_screen.dart';
import 'package:cheteni_delivery/screens/admin/admin_product_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/agent_detail_screen.dart';
import 'package:cheteni_delivery/screens/admin/agent_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/commodity_price_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/customer_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/driver_detail_screen.dart';
import 'package:cheteni_delivery/screens/admin/driver_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/financial_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/order_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/payout_management_screen.dart';
import 'package:cheteni_delivery/screens/admin/reports_screen.dart';
import 'package:cheteni_delivery/screens/auth/agent_login_screen.dart';
import 'package:cheteni_delivery/screens/auth/agent_registration_screen.dart';
import 'package:cheteni_delivery/screens/auth/customer_login_screen.dart';
import 'package:cheteni_delivery/screens/auth/customer_registration_screen.dart';
import 'package:cheteni_delivery/screens/auth/driver_login_screen.dart';
import 'package:cheteni_delivery/screens/auth/driver_registration_screen.dart';
import 'package:cheteni_delivery/screens/auth/role_selection_screen.dart';
import 'package:cheteni_delivery/screens/cart_screen.dart';
import 'package:cheteni_delivery/screens/home_screen.dart';
import 'package:cheteni_delivery/screens/onboarding_screen.dart';
import 'package:cheteni_delivery/screens/splash_screen.dart';
import 'package:cheteni_delivery/screens/vendor/vendor_confirm_pickup_screen.dart';
import 'package:cheteni_delivery/screens/vendor/vendor_home_screen.dart';
import 'package:cheteni_delivery/screens/vendor/vendor_login_screen.dart';
import 'package:cheteni_delivery/screens/vendor/vendor_my_qr_screen.dart';
import 'package:cheteni_delivery/screens/vendor/vendor_place_order_screen.dart';
import 'package:cheteni_delivery/screens/vendor/vendor_registration_screen.dart';
import 'package:cheteni_delivery/screens/vendor/vendor_wallet_screen.dart';
import 'package:cheteni_delivery/screens/agent/agent_home_screen.dart';
import 'package:cheteni_delivery/screens/agent/agent_scan_vendor_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const CheteniApp());
}

class CheteniApp extends StatelessWidget {
  const CheteniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AgentProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'Cheteni',
        theme: ThemeData(primarySwatch: Colors.green),
        home: SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/welcome': (context) => WelcomeScreen(),
          '/role_selection': (context) => RoleSelectionScreen(),
          '/customer_login': (context) => CustomerLoginScreen(),
          '/customer_registration': (context) =>
              const CustomerRegistrationScreen(),
          '/driver_login': (context) => DriverLoginScreen(),
          '/driver_registration': (context) => const DriverRegistrationScreen(),
          '/agent_login': (context) => AgentLoginScreen(),
          '/agent_registration': (context) => const AgentRegistrationScreen(),
          '/agent_home': (context) => const AgentHomeScreen(),
          '/agent_scan_vendor_qr': (context) => const AgentScanVendorQrScreen(),
          '/admin_login': (context) => AdminLoginScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/home': (context) => const HomeScreen(),
          '/agent_management': (context) => const AgentManagementScreen(),
          '/driver_management': (context) => const DriverManagementScreen(),
          '/product_management': (context) =>
              const AdminProductManagementScreen(),
          '/admin_edit_product': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>?;
            return AdminEditProductScreen(product: args);
          },
          '/reports': (context) => ReportsScreen(),
          '/delivery_rates': (context) => const AdminDeliveryRatesScreen(),
          '/admin_change_password': (context) => AdminChangePasswordScreen(),
          '/order_management': (context) => const OrderManagementScreen(),
          '/customer_management': (context) => const CustomerManagementScreen(),
          '/payout_management': (context) => const PayoutManagementScreen(),
          '/financial_management': (context) =>
              const FinancialManagementScreen(),
          '/commodity_prices': (context) =>
              const CommodityPriceManagementScreen(),
          '/agent_detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return AgentDetailScreen(agent: args);
          },
          '/driver_detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return DriverDetailScreen(driver: args);
          },
          '/cart': (context) => const CartScreen(),

          // Vendor routes
          '/vendor_login': (context) => const VendorLoginScreen(),
          '/vendor_register': (context) => const VendorRegistrationScreen(),
          '/vendor_home': (context) => const VendorHomeScreen(),
          '/vendor_wallet': (context) => const VendorWalletScreen(),
          '/vendor_place_order': (context) => const VendorPlaceOrderScreen(),
          '/vendor_confirm_pickup': (context) =>
              const VendorConfirmPickupScreen(),
          '/vendor_my_qr': (context) => const VendorMyQrScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cheteni Delivery'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin_login'),
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            label: const Text('Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 200),
              const SizedBox(height: 30),
              const Text(
                'Welcome to Cheteni',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'Your one-stop shop for fresh produce, delivered.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/role_selection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      const Text('Get Started', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
