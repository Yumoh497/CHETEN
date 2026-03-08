import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/services/api_service.dart';

class AgentConfirmVendorPickupScreen extends StatefulWidget {
  final int vendorId;

  const AgentConfirmVendorPickupScreen({super.key, required this.vendorId});

  @override
  State<AgentConfirmVendorPickupScreen> createState() =>
      _AgentConfirmVendorPickupScreenState();
}

class _AgentConfirmVendorPickupScreenState
    extends State<AgentConfirmVendorPickupScreen> {
  final _orderIdController = TextEditingController();

  bool _isLoadingOrder = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _orderId;
  List<Map<String, dynamic>> _items = [];

  final Map<int, bool> _selected = {};
  final Map<int, int> _selectedQty = {};
  final Map<int, int> _availableQty = {};

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic v, {int fallback = 1}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  double get _selectedTotal {
    double sum = 0;
    for (int i = 0; i < _items.length; i++) {
      if (_selected[i] != true) continue;
      final price = _toDouble(_items[i]['price']);
      final qty = _selectedQty[i] ?? 1;
      sum += price * qty;
    }
    return sum;
  }

  bool get _hasSelection => _selected.values.any((v) => v == true);

  Future<void> _loadOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      setState(() => _errorMessage = 'Authentication required. Please login.');
      return;
    }

    final orderId = int.tryParse(_orderIdController.text.trim());
    if (orderId == null) {
      setState(() => _errorMessage = 'Please enter a valid Order ID.');
      return;
    }

    setState(() {
      _isLoadingOrder = true;
      _errorMessage = null;
      _orderId = null;
      _items = [];
      _selected.clear();
      _selectedQty.clear();
    });

    try {
      final response = await ApiService.getOrderById(orderId,
          authToken: authProvider.authToken);
      if (response['success'] == true && response['order'] != null) {
        final order = Map<String, dynamic>.from(response['order']);
        final rawItems = (order['items'] as List?) ?? const [];
        final items = rawItems
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();

        for (int i = 0; i < items.length; i++) {
          final qty = _toInt(items[i]['quantity'], fallback: 1);
          _selected[i] = false;
          _availableQty[i] = qty;
          _selectedQty[i] = qty; // default to full quantity
        }

        setState(() {
          _orderId = orderId;
          _items = items;
          _isLoadingOrder = false;
        });
      } else {
        setState(() {
          _isLoadingOrder = false;
          _errorMessage = response['message'] ?? 'Failed to load order.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingOrder = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _confirmPickup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) return;
    if (_orderId == null) return;
    if (!_hasSelection) {
      setState(
          () => _errorMessage = 'Select at least one item for this vendor.');
      return;
    }

    final selectedItems = <Map<String, dynamic>>[];
    for (int i = 0; i < _items.length; i++) {
      if (_selected[i] != true) continue;
      final item = _items[i];
      final name = item['product_name'] ?? item['name'] ?? 'Item';
      final price = _toDouble(item['price']);
      final qty = _selectedQty[i] ?? 1;
      selectedItems.add({
        'name': name,
        'price': price,
        'quantity': qty,
        if (item['product_id'] != null) 'product_id': item['product_id'],
      });
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.agentConfirmVendorPickup(
        orderId: _orderId!,
        vendorId: widget.vendorId,
        items: selectedItems,
        authToken: authProvider.authToken,
      );
      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Pickup confirmed. Vendor must confirm to receive payment.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = response['message'] ?? 'Failed to confirm pickup.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm vendor pickup'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Vendor ID: ${widget.vendorId}\nSelect the exact order items you picked up from this vendor.',
                  style: TextStyle(color: Colors.green.shade900),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _orderIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Order ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoadingOrder ? null : _loadOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 56),
                  ),
                  child: _isLoadingOrder
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            if (_orderId != null) ...[
              Text(
                'Order #$_orderId items',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                const Text('No items found on this order.')
              else
                ...List.generate(_items.length, (i) {
                  final item = _items[i];
                  final name = item['product_name'] ?? item['name'] ?? 'Item';
                  final price = _toDouble(item['price']);
                  final qty = _selectedQty[i] ?? 1;
                  final available = _availableQty[i] ?? qty;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: CheckboxListTile(
                      value: _selected[i] ?? false,
                      onChanged: (v) {
                        setState(() {
                          _selected[i] = v ?? false;
                        });
                      },
                      title: Text('$name'),
                      subtitle: Text(
                          'KSh ${price.toStringAsFixed(2)} • Selected: $qty / $available'),
                      secondary: (_selected[i] == true && available > 1)
                          ? DropdownButton<int>(
                              value: qty.clamp(1, available),
                              items: List.generate(
                                available,
                                (idx) => DropdownMenuItem(
                                  value: idx + 1,
                                  child: Text('${idx + 1}'),
                                ),
                              ),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedQty[i] = v);
                              },
                            )
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Selected total:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    'KSh ${_selectedTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _confirmPickup,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isSubmitting ? 'Confirming...' : 'Confirm pickup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
