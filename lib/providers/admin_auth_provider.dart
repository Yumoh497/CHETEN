import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class AdminAuthProvider with ChangeNotifier {
  bool _isAdminLoggedIn = false;
  Map<String, dynamic>? _adminData;
  String? _authToken;
  bool _isLoading = false;

  bool get isAdminLoggedIn => _isAdminLoggedIn;
  Map<String, dynamic>? get adminData => _adminData;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;

  Future<bool> loginAdmin(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.adminLogin(username: username, password: password);
      if (response['success']) {
        _isAdminLoggedIn = true;
        _adminData = response['data'];
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

  void logoutAdmin() {
    _isAdminLoggedIn = false;
    _adminData = null;
    _authToken = null;
    notifyListeners();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (_authToken == null || _adminData == null) return;

    try {
      await ApiService.adminChangePassword(
        username: _adminData!['username'],
        oldPassword: oldPassword,
        newPassword: newPassword,
        token: _authToken!,
      );
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
