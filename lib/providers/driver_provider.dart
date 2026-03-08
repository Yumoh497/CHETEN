import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class DriverProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = false;

  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic>? get driverProfile => _driverProfile;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchDriverData(String driverName, String authToken) async {
    await Future.wait([
      fetchOrders(driverName, authToken),
      fetchProfile(driverName, authToken),
    ]);
  }

  Future<void> fetchOrders(String driverName, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.getDriverOrders(driverName, authToken: authToken);
      if (response['success']) {
        _orders = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
  }

  Future<void> fetchProfile(String driverName, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.getDriverProfile(driverName, authToken: authToken);
      if (response['success']) {
        _driverProfile = Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
  }

  Future<bool> updateOrderStatus(String customerPhone, String status, String driverName, String authToken) async {
    try {
      final response = await ApiService.updateDriverOrderStatus(
        customerPhone: customerPhone,
        status: status,
        driverName: driverName,
        authToken: authToken,
      );
      if (response['success'] == true) {
        await fetchOrders(driverName, authToken);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<bool> confirmDelivery(String customerPhone, String driverName, dynamic recipientPhoto, String authToken) async {
    try {
      final response = await ApiService.driverConfirmDelivery(
        customerPhone: customerPhone,
        driverName: driverName,
        recipientPhoto: recipientPhoto,
        authToken: authToken,
      );
      if (response['success'] == true) {
        await fetchOrders(driverName, authToken);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }
}
