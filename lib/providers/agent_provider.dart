import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class AgentProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _personnel = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _deliveryTracking;
  Map<String, double> _productPricing = {};
  bool _isLoading = false;

  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get personnel => _personnel;
  Map<String, dynamic> get stats => _stats;
  Map<String, dynamic>? get deliveryTracking => _deliveryTracking;
  Map<String, double> get productPricing => _productPricing;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchOrders(String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.getAgentOrders(authToken: authToken);
      if (response['success']) {
        _orders = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
  }

  Future<void> fetchPersonnel(String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.getAgentPersonnel(authToken: authToken);
      if (response['success']) {
        _personnel = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
  }

  Future<bool> assignOrder(
      String orderId, String personnelId, String authToken) async {
    try {
      final response = await ApiService.assignOrderToPersonnel(
          orderId: orderId, personnelId: personnelId, authToken: authToken);
      if (response['success']) {
        await fetchOrders(authToken);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<void> fetchStats(String authToken) async {
    _setLoading(true);
    try {
      final response =
          await ApiService.getAgentDashboardStats(authToken: authToken);
      if (response['success']) {
        _stats = Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
  }

  Future<void> trackOrder(String orderId, {String? authToken}) async {
    _setLoading(true);
    try {
      final response =
          await ApiService.trackOrder(orderId, authToken: authToken);
      if (response['success']) {
        _deliveryTracking = response['data'];
      }
    } catch (e) {
      // handle error
    }
    _setLoading(false);
  }

  Future<bool> updatePersonnelStatus(
      String personnelId, String status, String authToken) async {
    try {
      final response = await ApiService.updatePersonnelStatus(
          personnelId, status,
          authToken: authToken);
      if (response['success']) {
        await fetchPersonnel(authToken);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<void> fetchProductPricing({String? authToken}) async {
    _setLoading(true);
    try {
      final response = await ApiService.getAgentPricing(authToken: authToken);
      if (response['success'] && response['data'] != null) {
        final data = response['data'];
        if (data['product_pricing'] != null) {
          final pricing = Map<String, dynamic>.from(data['product_pricing']);
          _productPricing = pricing.map((key, value) =>
              MapEntry(key, (value is num) ? value.toDouble() : 0.0));
        }
      }
    } catch (e) {
      // Handle error - fallback to default pricing if API fails
      _productPricing = {
        'Rice': 50.0,
        'Beans': 80.0,
        'Tomatoes': 40.0,
        'Onions': 30.0,
        'Potatoes': 35.0,
      };
    }
    _setLoading(false);
  }

  Future<bool> updateProductPricing(
      Map<String, double> pricing, String authToken) async {
    try {
      final response = await ApiService.updateAgentProductPricing(pricing,
          authToken: authToken);
      if (response['success']) {
        _productPricing = pricing;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }
}
