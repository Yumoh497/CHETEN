import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userType;
  Map<String, dynamic>? _userData;
  String? _authToken;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userType => _userType;
  Map<String, dynamic>? get userData => _userData;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;

  Future<bool> login(String userType, Map<String, dynamic> credentials) async {
    _isLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic> response;
      
      if (userType == 'customer') {
        response = await ApiService.customerLogin(phone: credentials['phone']);
      } else if (userType == 'driver') {
        response = await ApiService.driverLogin(phone: credentials['phone']);
      } else if (userType == 'agent') {
        response = await ApiService.agentLogin(
          email: credentials['email'],
          password: credentials['password']
        );
      } else if (userType == 'vendor') {
        response = await ApiService.vendorLogin(
          email: credentials['email'],
          password: credentials['password']
        );
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (response['success'] == true) {
        _isLoggedIn = true;
        _userType = userType;
        _userData = response['user'] ?? response['agent'] ?? response['vendor'] ?? credentials;
        _authToken = response['token'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> vendorLogin({
    required String email,
    required String password,
  }) async {
    return await login('vendor', {'email': email, 'password': password});
  }

  Future<bool> register(String userType, Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (userType == 'customer') {
        final response = await ApiService.registerCustomer(
            name: userData['name'], phone: userData['phone'], email: userData['email']);
        _isLoading = false;
        notifyListeners();
        return response['success'] ?? false;
      } else if (userType == 'driver') {
        final response = await ApiService.registerDriver(
            name: userData['name'], phone: userData['phone'], plateNumber: userData['plate_number'], route: userData['route']);
        _isLoading = false;
        notifyListeners();
        return response['success'] ?? false;
      } else if (userType == 'agent') {
        final response = await ApiService.registerAgent(
          name: userData['name'],
          idNumber: userData['id_number'],
          email: userData['email'],
          phone: userData['phone'],
          password: userData['password'],
          marketLocation: userData['market_location'],
        );
        _isLoading = false;
        notifyListeners();
        return response['success'] ?? false;
      } else if (userType == 'vendor') {
        final response = await ApiService.registerVendor(
          vendorName: userData['vendor_name'],
          idNumber: userData['id_number'],
          mpesaNumber: userData['mpesa_number'],
          market: userData['market'],
          email: userData['email'],
          password: userData['password'],
        );
        _isLoading = false;
        notifyListeners();
        return response['success'] ?? false;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerVendor({
    required String vendorName,
    required String idNumber,
    required String mpesaNumber,
    required String market,
    required String email,
    required String password,
  }) async {
    return await register('vendor', {
      'vendor_name': vendorName,
      'id_number': idNumber,
      'mpesa_number': mpesaNumber,
      'market': market,
      'email': email,
      'password': password,
    });
  }

  void logout() {
    _isLoggedIn = false;
    _userType = null;
    _userData = null;
    _authToken = null;
    notifyListeners();
  }
}
