import 'package:cheteni_delivery/providers/admin_auth_provider.dart';
import 'package:cheteni_delivery/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminEditSubscriptionPlanScreen extends StatefulWidget {
  final Map<String, dynamic>? plan;

  const AdminEditSubscriptionPlanScreen({super.key, this.plan});

  @override
  State<AdminEditSubscriptionPlanScreen> createState() => _AdminEditSubscriptionPlanScreenState();
}

class _AdminEditSubscriptionPlanScreenState extends State<AdminEditSubscriptionPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveriesController = TextEditingController();
  final _durationController = TextEditingController();
  String _frequency = 'monthly';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _nameController.text = widget.plan!['name'] ?? '';
      _descriptionController.text = widget.plan!['description'] ?? '';
      _priceController.text = widget.plan!['price']?.toString() ?? '';
      _deliveriesController.text = widget.plan!['deliveries_per_period']?.toString() ?? '1';
      _durationController.text = widget.plan!['duration_days']?.toString() ?? '';
      _frequency = widget.plan!['frequency'] ?? 'monthly';
      _isActive = widget.plan!['is_active'] == true;
    } else {
      _deliveriesController.text = '1';
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    
    final planData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'frequency': _frequency,
      'deliveries_per_period': int.tryParse(_deliveriesController.text) ?? 1,
      'duration_days': _durationController.text.isNotEmpty ? int.tryParse(_durationController.text) : null,
      'is_active': _isActive,
    };

    bool success = false;
    if (widget.plan != null) {
      success = await adminProvider.updateSubscriptionPlan(
          widget.plan!['id'], planData, authProvider.authToken!);
    } else {
      success = await adminProvider.createSubscriptionPlan(planData, authProvider.authToken!);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save subscription plan')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan != null ? 'Edit Subscription Plan' : 'Add Subscription Plan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Weekly Fresh Produce',
                ),
                validator: (value) => value!.isEmpty ? 'Enter plan name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what this plan includes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (KSh)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2999.99',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Enter price';
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  setState(() {
                    _frequency = value!;
                  });
                },
                validator: (value) => value == null ? 'Select frequency' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveriesController,
                decoration: const InputDecoration(
                  labelText: 'Deliveries per period',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 1 (default)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Enter number of deliveries';
                  final deliveries = int.tryParse(value);
                  if (deliveries == null || deliveries < 1) return 'Enter at least 1 delivery';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (days) - optional',
                  border: OutlineInputBorder(),
                  hintText: 'Leave empty for ongoing subscription',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value!;
                      });
                    },
                  ),
                  const Text('Active Plan'),
                  const SizedBox(width: 8),
                  Icon(
                    _isActive ? Icons.check_circle : Icons.remove_circle,
                    color: _isActive ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _savePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Subscription Plan',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}