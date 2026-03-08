import 'package:cheteni_delivery/providers/agent_provider.dart';
import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/screens/agent/personnel_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderDetailsModal extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsModal({super.key, required this.order});

  @override
  State<OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<OrderDetailsModal> {
  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Order ID', widget.order['id'] ?? ''),
          _buildDetailRow('Customer', widget.order['customer']?['name'] ?? ''),
          _buildDetailRow('Amount', 'KSh ${widget.order['total_price'] ?? '0.00'}'),
          _buildDetailRow('Status', widget.order['status'] ?? ''),
          _buildDetailRow('Items', (widget.order['items'] as List<dynamic>).map((item) => '${item['quantity']}x ${item['product']?['name'] ?? ''}').join(', ')),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => PersonnelSelectionModal(
                        onSelect: (personnelId) async {
                          final success = await agentProvider.assignOrder(
                              widget.order['id'], personnelId, authProvider.authToken!);
                          
                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(context); // Close personnel selection
                            Navigator.pop(context); // Close order details
                          }
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Assign Driver'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/delivery_tracking', arguments: widget.order['id']);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Track Order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
