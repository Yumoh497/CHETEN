import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/screens/customer/customer_home_screen.dart';
import 'package:cheteni_delivery/screens/driver/driver_home_screen.dart';
import 'package:cheteni_delivery/screens/agent/agent_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.userType) {
      case 'customer':
        return const CustomerHomeScreen();
      case 'driver':
        return const DriverHomeScreen();
      case 'agent':
        return const AgentHomeScreen();
      default:
        // Should not happen, but as a fallback:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error: Unknown user type.'),
                ElevatedButton(
                  onPressed: () {
                    authProvider.logout();
                    Navigator.pushReplacementNamed(context, '/welcome');
                  },
                  child: const Text('Go to Welcome Screen'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
