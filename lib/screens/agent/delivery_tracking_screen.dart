import 'package:cheteni_delivery/providers/agent_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({super.key, required this.orderId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  @override
  void initState() {
    super.initState();
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    agentProvider.trackOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final delivery = agentProvider.deliveryTracking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Tracking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: agentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : delivery == null
              ? const Center(child: Text('No tracking information available'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('Order #${delivery['id'] ?? ''}'),
                          subtitle: Text(
                              'Driver: ${delivery['driver']?['name'] ?? ''}\nCustomer: ${delivery['customer']?['name'] ?? ''}\nETA: ${delivery['eta'] ?? 'N/A'}'),
                          trailing: Chip(
                            label: Text(delivery['status'] ?? ''),
                            backgroundColor: delivery['status'] == 'Delivered'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                      // TODO: Add map view for real-time tracking
                    ],
                  ),
                ),
    );
  }
}
