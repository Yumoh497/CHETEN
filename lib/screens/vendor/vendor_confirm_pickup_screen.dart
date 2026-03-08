import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/services/api_service.dart';

class VendorConfirmPickupScreen extends StatefulWidget {
  const VendorConfirmPickupScreen({super.key});

  @override
  State<VendorConfirmPickupScreen> createState() =>
      _VendorConfirmPickupScreenState();
}

class _VendorConfirmPickupScreenState extends State<VendorConfirmPickupScreen> {
  List<Map<String, dynamic>> _pendingPickups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingPickups();
  }

  Future<void> _loadPendingPickups() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in again';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.getVendorPendingPickups(
          authToken: authProvider.authToken);
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _pendingPickups =
              List<Map<String, dynamic>>.from(response['data'] as List);
          _isLoading = false;
        });
      } else {
        setState(() {
          _pendingPickups = [];
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Failed to load';
        });
      }
    } catch (e) {
      setState(() {
        _pendingPickups = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmPickup(int pickupId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) return;
    try {
      final response = await ApiService.vendorConfirmPickup(
        pickupId: pickupId,
        authToken: authProvider.authToken,
      );
      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Pickup confirmed. You will receive payment after admin processes it.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPendingPickups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to confirm'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Pickup'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPendingPickups,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingPickups,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.green.shade700, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Confirm when the agent has picked up the item. You will receive payment after admin processes it.',
                                style: TextStyle(
                                    color: Colors.green.shade900, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    if (_pendingPickups.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No pickups awaiting your confirmation',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._pendingPickups.map((p) {
                        final items = (p['items'] as List?) ?? const [];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                                'Order #${p['order_id']} • Agent: ${p['agent_name'] ?? 'N/A'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KSh ${(p['amount'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                if (items.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Items: ${items.map((e) => (e is Map && e['name'] != null) ? e['name'] : e.toString()).join(', ')}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _confirmPickup(p['id'] as int),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: const Text('Confirm Pickup'),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
