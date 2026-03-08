import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PayoutManagementScreen extends StatefulWidget {
  const PayoutManagementScreen({super.key});

  @override
  State<PayoutManagementScreen> createState() => _PayoutManagementScreenState();
}

class _PayoutManagementScreenState extends State<PayoutManagementScreen> {
  List<Map<String, dynamic>> _pendingPayouts = [];
  List<Map<String, dynamic>> _vendorPayouts = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, drivers, agents, vendors

  @override
  void initState() {
    super.initState();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await ApiService.getAdminVendorPayouts(
          authToken: authProvider.authToken!);
      if (mounted && response['success'] == true && response['data'] != null) {
        setState(() {
          _vendorPayouts =
              List<Map<String, dynamic>>.from(response['data'] as List);
        });
      }
    } catch (_) {}
    // Placeholder for driver/agent payouts
    if (mounted) {
      setState(() {
        _pendingPayouts = _pendingPayouts;
        _isLoading = false;
      });
    }
  }

  Future<void> _processVendorPayout(Map<String, dynamic> payout) async {
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    if (authProvider.authToken == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay vendor'),
        content: Text(
          'Pay KSh ${payout['amount']?.toStringAsFixed(2) ?? '0.00'} to ${payout['vendor_name'] ?? 'Vendor'}? '
          'This completes the automatic payment after pickup confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await ApiService.adminPayVendor(
        pickupId: payout['id'] as int,
        authToken: authProvider.authToken!,
      );
      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor paid successfully')),
          );
          _loadPayouts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _processPayout(Map<String, dynamic> payout) async {
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    if (authProvider.authToken == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payout'),
        content: Text(
          'Process payout of KSh ${payout['amount']?.toStringAsFixed(2) ?? '0.00'} '
          'to ${payout['name'] ?? 'Unknown'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.processPayout(
        orderId: payout['order_id'] as int,
        authToken: authProvider.authToken!,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payout processed successfully')),
          );
          _loadPayouts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Failed to process payout')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payoutsToShow =
        _selectedFilter == 'vendors' ? _vendorPayouts : _pendingPayouts;
    final pendingCount = _pendingPayouts.length + _vendorPayouts.length;
    final totalAmount = _pendingPayouts.fold<double>(
          0,
          (sum, p) => sum + (p['amount'] ?? 0.0),
        ) +
        _vendorPayouts.fold<double>(
          0,
          (sum, p) => sum + (p['amount'] ?? 0.0),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayouts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab('all', 'All'),
                _buildFilterTab('drivers', 'Drivers'),
                _buildFilterTab('agents', 'Agents'),
                _buildFilterTab('vendors', 'Vendors'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '$pendingCount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pending Payouts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'KSh ${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Payouts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : payoutsToShow.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending payouts',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPayouts,
                        child: ListView.builder(
                          itemCount: payoutsToShow.length,
                          itemBuilder: (context, index) {
                            final payout = payoutsToShow[index];
                            final isVendor = _selectedFilter == 'vendors';
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isVendor
                                      ? Colors.purple.shade100
                                      : payout['type'] == 'driver'
                                          ? Colors.green.shade100
                                          : Colors.blue.shade100,
                                  child: Icon(
                                    isVendor
                                        ? Icons.store
                                        : payout['type'] == 'driver'
                                            ? Icons.delivery_dining
                                            : Icons.business,
                                    color: isVendor
                                        ? Colors.purple.shade700
                                        : payout['type'] == 'driver'
                                            ? Colors.green.shade700
                                            : Colors.blue.shade700,
                                  ),
                                ),
                                title: Text(
                                  isVendor
                                      ? (payout['vendor_name'] ?? 'Vendor')
                                      : (payout['name'] ?? 'Unknown'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Order #${payout['order_id'] ?? 'N/A'}'),
                                    if (isVendor &&
                                        (payout['agent_name'] != null))
                                      Text('Agent: ${payout['agent_name']}'),
                                    Text(
                                      'Amount: KSh ${payout['amount']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => isVendor
                                      ? _processVendorPayout(payout)
                                      : _processPayout(payout),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Pay'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
