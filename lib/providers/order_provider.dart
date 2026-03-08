import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class OrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  final List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _customerSubscriptions = [];
  Map<String, dynamic>? _trackingData;
  bool _isLoading = false;

  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<Map<String, dynamic>> get customerSubscriptions => _customerSubscriptions;
  Map<String, dynamic>? get trackingData => _trackingData;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void addToCart(Map<String, dynamic> item) {
    final existingIndex = _cartItems.indexWhere((cartItem) => cartItem['product_id'] == item['product_id']);
    if (existingIndex != -1) {
      _cartItems[existingIndex]['quantity'] += item['quantity'];
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item['product_id'] == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> fetchOrders(String customerPhone, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.getOrders(customerPhone: customerPhone, authToken: authToken);
      if (response['success']) {
        _orders = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
  }

  Future<bool> placeOrder({
    required Map<String, dynamic> orderData,
    required String authToken,
  }) async {
    _setLoading(true);
    try {
      final response = await ApiService.placeOrder(orderData, authToken: authToken);
      if (response['success']) {
        clearCart();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }

  Future<bool> placeOrderWithWallet({
    required Map<String, dynamic> orderData,
    required String authToken,
  }) async {
    _setLoading(true);
    try {
      // In a real app, you would have a separate endpoint for this.
      // For now, we will simulate it by calling the regular placeOrder endpoint.
      final response = await ApiService.placeOrder(orderData, authToken: authToken);
      if (response['success']) {
        clearCart();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }

  Future<void> trackOrder(String orderId, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.trackOrder(orderId, authToken: authToken);
      if (response['success']) {
        _trackingData = response['data'];
      }
    } catch (e) {
      // handle error
    }
    _setLoading(false);
  }

  Future<bool> ratePersonnel(String personnelPhone, String customerPhone, int rating, String? review, String authToken) async {
    try {
      final response = await ApiService.ratePersonnel(
        personnelPhone: personnelPhone,
        customerPhone: customerPhone,
        rating: rating,
        review: review,
        authToken: authToken,
      );
      return response['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Subscription Methods
  Future<void> loadCustomerSubscriptions(String customerPhone) async {
    _setLoading(true);
    try {
      final response = await ApiService.getCustomerSubscriptions(customerPhone);
      if (response['success'] == true) {
        _customerSubscriptions = List<Map<String, dynamic>>.from(response['data'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
    _setLoading(false);
  }

  Future<bool> createSubscription({
    required String customerPhone,
    required int planId,
    required Map<String, dynamic> planData,
  }) async {
    _setLoading(true);
    try {
      final subscriptionData = {
        'customer_phone': customerPhone,
        'plan_id': planId,
        'frequency': planData['frequency'],
        'items_json': '[]', // Empty items for now, can be customized later
        'next_delivery': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };
      
      final response = await ApiService.createSubscription(subscriptionData);
      if (response['success'] == true) {
        await loadCustomerSubscriptions(customerPhone);
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // handle error
    }
    _setLoading(false);
    return false;
  }

  Future<bool> cancelSubscription(int subscriptionId, String customerPhone) async {
    _setLoading(true);
    try {
      final response = await ApiService.cancelSubscription(subscriptionId, {'status': 'cancelled'});
      if (response['success'] == true) {
        await loadCustomerSubscriptions(customerPhone);
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // handle error
    }
    _setLoading(false);
    return false;
  }
}
