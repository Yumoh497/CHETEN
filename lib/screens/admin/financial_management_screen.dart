import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FinancialManagementScreen extends StatefulWidget {
  const FinancialManagementScreen({super.key});

  @override
  State<FinancialManagementScreen> createState() => _FinancialManagementScreenState();
}

class _FinancialManagementScreenState extends State<FinancialManagementScreen> {
  String _selectedUserType = 'all'; // all, customer, driver, agent
  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  double _totalBalance = 0.0;
  double _totalDeposits = 0.0;
  double _totalWithdrawals = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // This would need backend endpoints to get all wallets and transactions
      // For now, we'll show the structure
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _wallets = [];
          _transactions = [];
          _totalBalance = 0.0;
          _totalDeposits = 0.0;
          _totalWithdrawals = 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$month $day, $year • $hour:$minute';
    } catch (e) {
      return dateString;
    }
  }

  List<Map<String, dynamic>> _getFilteredWallets() {
    if (_selectedUserType == 'all') return _wallets;
    return _wallets.where((wallet) => 
      wallet['user_type']?.toString().toLowerCase() == _selectedUserType.toLowerCase()
    ).toList();
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    if (_selectedUserType == 'all') return _transactions;
    return _transactions.where((tx) => 
      tx['user_type']?.toString().toLowerCase() == _selectedUserType.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialData,
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
                _buildFilterTab('customer', 'Customers'),
                _buildFilterTab('driver', 'Drivers'),
                _buildFilterTab('agent', 'Agents'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Balance',
                    'KSh ${_totalBalance.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Deposits',
                    'KSh ${_totalDeposits.toStringAsFixed(2)}',
                    Icons.arrow_downward,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Withdrawals',
                    'KSh ${_totalWithdrawals.toStringAsFixed(2)}',
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
          // Tabs for Wallets and Transactions
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.account_balance_wallet), text: 'Wallets'),
                    Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Wallets Tab
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _getFilteredWallets().isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No wallets found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadFinancialData,
                                  child: ListView.builder(
                                    itemCount: _getFilteredWallets().length,
                                    itemBuilder: (context, index) {
                                      final wallet = _getFilteredWallets()[index];
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
                                            backgroundColor: _getUserTypeColor(
                                              wallet['user_type'] ?? ''
                                            ).withOpacity(0.2),
                                            child: Icon(
                                              _getUserTypeIcon(wallet['user_type'] ?? ''),
                                              color: _getUserTypeColor(
                                                wallet['user_type'] ?? ''
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            wallet['user_id'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${wallet['user_type']?.toString().toUpperCase() ?? 'UNKNOWN'} • '
                                            'ID: ${wallet['id'] ?? 'N/A'}',
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'KSh ${wallet['balance']?.toStringAsFixed(2) ?? '0.00'}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                              Chip(
                                                label: Text(
                                                  wallet['user_type'] ?? 'unknown',
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                                backgroundColor: _getUserTypeColor(
                                                  wallet['user_type'] ?? ''
                                                ).withOpacity(0.2),
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                      // Transactions Tab
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _getFilteredTransactions().isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No transactions found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadFinancialData,
                                  child: ListView.builder(
                                    itemCount: _getFilteredTransactions().length,
                                    itemBuilder: (context, index) {
                                      final tx = _getFilteredTransactions()[index];
                                      final isDeposit = tx['type'] == 'deposit';
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isDeposit
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              isDeposit
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color: isDeposit
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              size: 24,
                                            ),
                                          ),
                                          title: Text(
                                            tx['description'] ?? 'Transaction',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${tx['user_type']?.toString().toUpperCase() ?? 'UNKNOWN'} • '
                                                'User: ${tx['user_id'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(tx['timestamp']),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${isDeposit ? '+' : '-'}KSh ${tx['amount']?.toStringAsFixed(2) ?? '0.00'}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDeposit
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700,
                                                ),
                                              ),
                                              if (tx['mpesa_receipt'] != null)
                                                Text(
                                                  'Receipt: ${tx['mpesa_receipt']}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedUserType == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUserType = value;
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

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
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

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'customer':
        return Colors.blue;
      case 'driver':
        return Colors.green;
      case 'agent':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'customer':
        return Icons.person;
      case 'driver':
        return Icons.delivery_dining;
      case 'agent':
        return Icons.business;
      default:
        return Icons.account_circle;
    }
  }
}

