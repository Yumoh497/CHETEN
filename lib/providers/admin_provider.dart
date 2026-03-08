import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class AdminProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _subscriptionPlans = [];
  Map<String, dynamic> _deliveryRates = {};
  Map<String, dynamic> _reports = {};

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get agents => _agents;
  List<Map<String, dynamic>> get drivers => _drivers;
  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get subscriptionPlans => _subscriptionPlans;
  Map<String, dynamic> get deliveryRates => _deliveryRates;
  Map<String, dynamic> get reports => _reports;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchAdminData(String authToken) async {
    _setLoading(true);
    await Future.wait([
      fetchAgents(authToken),
      fetchDrivers(authToken),
      fetchProducts(authToken),
      fetchDeliveryRates(authToken),
      fetchReports(authToken),
    ]);
    _setLoading(false);
  }

  Future<void> fetchAgents(String authToken) async {
    try {
      final response = await ApiService.getAllAgents(authToken: authToken);
      if (response['success'] == true) {
        _agents = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> fetchDrivers(String authToken) async {
    try {
      final response = await ApiService.getAllDrivers(authToken: authToken);
      if (response['success'] == true) {
        _drivers = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> fetchProducts(String authToken) async {
    try {
      final response = await ApiService.getAllProducts(authToken: authToken);
      if (response['success'] == true) {
        _products = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> fetchDeliveryRates(String authToken) async {
    try {
      final response = await ApiService.getDeliveryCharges(authToken: authToken);
      if (response['success'] == true) {
        _deliveryRates = Map<String, dynamic>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

    Future<void> fetchReports(String authToken) async {
    try {
      final response = await ApiService.getAdminReports(authToken: authToken);
      if (response['success'] == true) {
        _reports = Map<String, dynamic>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

  Future<bool> updateDeliveryRates(Map<String, dynamic> rates, String authToken) async {
     try {
      final response = await ApiService.updateDeliveryCharges(rates, authToken: authToken);
      if (response['success'] == true) {
        fetchDeliveryRates(authToken);
        return true;
      }
    } catch (e) {
      // handle error
    }
    return false;
  }

  Future<bool> createProduct(Map<String, dynamic> productData, String authToken) async {
    // TODO: Implement API call
    return true;
  }

  Future<bool> updateProduct(int productId, Map<String, dynamic> productData, String authToken) async {
    // TODO: Implement API call
    return true;
  }

  Future<bool> deleteProduct(int productId, String authToken) async {
    try {
      final response = await ApiService.deleteProduct(productId, authToken: authToken);
      if (response['success'] == true) {
        fetchProducts(authToken);
        return true;
      }
    } catch (e) {
      // handle error
    }
    return false;
  }

  // Subscription Plan Methods
  Future<void> loadSubscriptionPlans(String authToken) async {
    try {
      final response = await ApiService.getSubscriptionPlans(authToken: authToken);
      if (response['success'] == true) {
        _subscriptionPlans = List<Map<String, dynamic>>.from(response['data'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

  Future<bool> createSubscriptionPlan(Map<String, dynamic> planData, String authToken) async {
    try {
      final response = await ApiService.createSubscriptionPlan(planData, authToken: authToken);
      if (response['success'] == true) {
        await loadSubscriptionPlans(authToken);
        return true;
      }
    } catch (e) {
      // handle error
    }
    return false;
  }

  Future<bool> updateSubscriptionPlan(int planId, Map<String, dynamic> planData, String authToken) async {
    try {
      final response = await ApiService.updateSubscriptionPlan(planId, planData, authToken: authToken);
      if (response['success'] == true) {
        await loadSubscriptionPlans(authToken);
        return true;
      }
    } catch (e) {
      // handle error
    }
    return false;
  }

  Future<bool> deleteSubscriptionPlan(int planId, String authToken) async {
    try {
      final response = await ApiService.deleteSubscriptionPlan(planId, authToken: authToken);
      if (response['success'] == true) {
        await loadSubscriptionPlans(authToken);
        return true;
      }
    } catch (e) {
      // handle error
    }
    return false;
  }

  Future<bool> toggleSubscriptionPlanActive(int planId, bool isActive, String authToken) async {
    try {
      final response = await ApiService.updateSubscriptionPlan(
        planId, 
        {'is_active': isActive}, 
        authToken: authToken
      );
      if (response['success'] == true) {
        await loadSubscriptionPlans(authToken);
        return true;
      }
    } catch (e) {
      // handle error
    }
    return false;
  }
}
