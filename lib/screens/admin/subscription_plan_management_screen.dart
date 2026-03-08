import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubscriptionPlanManagementScreen extends StatefulWidget {
  const SubscriptionPlanManagementScreen({super.key});

  @override
  State<SubscriptionPlanManagementScreen> createState() => _SubscriptionPlanManagementScreenState();
}

class _SubscriptionPlanManagementScreenState extends State<SubscriptionPlanManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load subscription plans when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      adminProvider.loadSubscriptionPlans(authProvider.authToken!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.subscriptionPlans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.subscriptions,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subscription plans yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first plan',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: adminProvider.subscriptionPlans.length,
                  itemBuilder: (context, index) {
                    final plan = adminProvider.subscriptionPlans[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(plan['name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KSh ${plan['price'] ?? '0.00'}/${plan['frequency'] ?? 'monthly'}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${plan['deliveries_per_period'] ?? 1} delivery(s) per ${plan['frequency'] ?? 'period'}',
                            ),
                            if (plan['duration_days'] != null)
                              Text('Duration: ${plan['duration_days']} days'),
                            Text(
                              plan['is_active'] == true ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: plan['is_active'] == true ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(child: Text('Edit'), value: 'edit'),
                            const PopupMenuItem(child: Text('Delete'), value: 'delete'),
                            PopupMenuItem(
                              child: Text(plan['is_active'] == true ? 'Deactivate' : 'Activate'),
                              value: 'toggle_active',
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              if (!mounted) return;
                              Navigator.pushNamed(context, '/admin_edit_subscription_plan',
                                  arguments: plan);
                            } else if (value == 'delete') {
                              final confirmed = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Plan'),
                                  content: const Text('Are you sure you want to delete this subscription plan?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmed == true) {
                                final success = await adminProvider.deleteSubscriptionPlan(
                                    plan['id'], authProvider.authToken!);
                                
                                if (!mounted) return;
                                
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Plan deleted successfully')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to delete plan')),
                                  );
                                }
                              }
                            } else if (value == 'toggle_active') {
                              final success = await adminProvider.toggleSubscriptionPlanActive(
                                  plan['id'], !(plan['is_active'] == true), authProvider.authToken!);
                              
                              if (!mounted) return;
                              
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Plan ${plan['is_active'] == true ? 'deactivated' : 'activated'}')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to update plan')),
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
          Navigator.pushNamed(context, '/admin_edit_subscription_plan');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}