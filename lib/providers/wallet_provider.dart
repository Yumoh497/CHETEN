import 'package:cheteni_delivery/services/api_service.dart';
import 'package:flutter/material.dart';

class WalletProvider with ChangeNotifier {
  Map<String, dynamic>? _walletData;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;

  Map<String, dynamic>? get walletData => _walletData;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchWalletData(
      String userType, String userId, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.getWallet(
          userType: userType, userId: userId, authToken: authToken);
      if (response['success']) {
        _walletData = response['data'];
      }
      await fetchTransactions(userType, userId, authToken);
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
  }

  Future<void> fetchTransactions(
      String userType, String userId, String authToken) async {
    try {
      final response = await ApiService.getWalletTransactions(
          userType: userType, userId: userId, authToken: authToken);
      if (response['success']) {
        _transactions = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      // Handle error
    }
    notifyListeners();
  }

  Future<bool> deposit(
      String userType, String userId, double amount, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.depositWallet(
          userType: userType,
          userId: userId,
          amount: amount,
          authToken: authToken);
      if (response['success']) {
        await fetchWalletData(userType, userId, authToken);
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }

  Future<bool> withdraw(
      String userType, String userId, double amount, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.withdrawWallet(
          userType: userType,
          userId: userId,
          amount: amount,
          authToken: authToken);
      if (response['success']) {
        await fetchWalletData(userType, userId, authToken);
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }

  Future<bool> mpesaDeposit(
      String userId, double amount, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.mpesaWalletDeposit(userId, amount,
          authToken: authToken);
      if (response['success']) {
        await fetchWalletData(
            'customer', userId, authToken); // Assuming customer for now
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }

  Future<bool> mpesaWithdraw(
      String userId, double amount, String authToken) async {
    _setLoading(true);
    try {
      final response = await ApiService.mpesaWalletWithdraw(userId, amount,
          authToken: authToken);
      if (response['success']) {
        await fetchWalletData(
            'customer', userId, authToken); // Assuming customer for now
        _setLoading(false);
        return true;
      }
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }

  Future<bool> paypalDeposit(
      String userType, String userId, double amount, String authToken) async {
    _setLoading(true);
    try {
      // Implement PayPal deposit logic here
      // For now, return false as placeholder
      _setLoading(false);
      return false;
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }

  Future<bool> googlePayDeposit(
      String userType, String userId, double amount, String authToken) async {
    _setLoading(true);
    try {
      // Implement Google Pay deposit logic here
      // For now, return false as placeholder
      _setLoading(false);
      return false;
    } catch (e) {
      // Handle error
    }
    _setLoading(false);
    return false;
  }
}
