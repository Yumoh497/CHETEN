import 'package:flutter/material.dart';

class DriverDetailScreen extends StatefulWidget {
  final Map<String, dynamic> driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _driverDetails;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _ratings = [];

  @override
  void initState() {
    super.initState();
    _loadDriverDetails();
  }

  Future<void> _loadDriverDetails() async {
    setState(() => _isLoading = true);
    // This would fetch detailed driver information from backend
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _driverDetails = widget.driver;
        _orders = [];
        _ratings = [];
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = _driverDetails ?? widget.driver;
    final rating = driver['rating'] ?? 0.0;
    final totalRatings = _ratings.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(driver['name'] ?? 'Driver Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            driver['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  Icons.star,
                                  size: 20,
                                  color: index < rating.round()
                                      ? Colors.orange
                                      : Colors.grey.shade300,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${rating.toStringAsFixed(1)} ($totalRatings)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(driver['status'] ?? 'Unknown'),
                            backgroundColor: _getStatusColor(
                              driver['status'] ?? ''
                            ).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _getStatusColor(driver['status'] ?? ''),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Contact & Vehicle Information
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact & Vehicle Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.phone, 'Phone', driver['phone'] ?? 'N/A'),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.directions_car,
                            'Plate Number',
                            driver['plate_number'] ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.route,
                            'Route',
                            driver['route'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Deliveries',
                          '${_orders.length}',
                          Icons.local_shipping,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Earnings',
                          'KSh ${driver['total_earnings']?.toStringAsFixed(2) ?? '0.00'}',
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
                          'Available Balance',
                          'KSh ${driver['balance']?.toStringAsFixed(2) ?? '0.00'}',
                          Icons.account_balance_wallet,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Pending Payouts',
                          '${driver['pending_payouts'] ?? 0}',
                          Icons.pending_actions,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Actions
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blue),
                          title: const Text('Edit Driver'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Navigate to edit driver screen
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            driver['status'] == 'Active' ? Icons.block : Icons.check_circle,
                            color: driver['status'] == 'Active' ? Colors.red : Colors.green,
                          ),
                          title: Text(
                            driver['status'] == 'Active' ? 'Deactivate Driver' : 'Activate Driver',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _toggleDriverStatus();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.payment, color: Colors.green),
                          title: const Text('Process Payout'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pushNamed(context, '/payout_management');
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete Driver'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _deleteDriver();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Recent Ratings
                  if (_ratings.isNotEmpty) ...[
                    const Text(
                      'Recent Ratings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._ratings.map((rating) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: Text(
                                '${rating['rating']}',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(rating['review'] ?? 'No review'),
                            subtitle: Text(rating['customer_name'] ?? 'Anonymous'),
                            trailing: Text(
                              rating['timestamp'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDriverStatus() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.driver['status'] == 'Active'
              ? 'Deactivate Driver?'
              : 'Activate Driver?',
        ),
        content: Text(
          widget.driver['status'] == 'Active'
              ? 'Are you sure you want to deactivate this driver?'
              : 'Are you sure you want to activate this driver?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.driver['status'] == 'Active'
                  ? Colors.red
                  : Colors.green,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Call API to update driver status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.driver['status'] == 'Active'
                ? 'Driver deactivated'
                : 'Driver activated',
          ),
        ),
      );
      _loadDriverDetails();
    }
  }

  Future<void> _deleteDriver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver?'),
        content: const Text(
          'Are you sure you want to delete this driver? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Call API to delete driver
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver deleted')),
      );
      Navigator.pop(context);
    }
  }
}

