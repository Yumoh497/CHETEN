import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class ProductProvider with ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _subscriptionPlans = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get subscriptionPlans => _subscriptionPlans;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchProducts(String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.getProducts(authToken: authToken);
      if (response['success']) {
        _products = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      // handle error
    }
    _setLoading(false);
  }

  Future<void> loadSubscriptionPlans() async {
    _setLoading(true);
    try {
      final response = await ApiService.getSubscriptionPlans();
      if (response['success'] == true) {
        _subscriptionPlans = List<Map<String, dynamic>>.from(response['data'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
    _setLoading(false);
  }
}
