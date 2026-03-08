import 'package:flutter/material.dart';

class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // App strings
  String get appTitle => 'Cheteni Delivery';
  String get welcome => 'Welcome to Cheteni';
  String get login => 'Login';
  String get register => 'Register';
  String get customer => 'Customer';
  String get driver => 'Driver';
  String get agent => 'Agent';
  String get admin => 'Admin';
  
  // Common strings
  String get name => 'Name';
  String get phone => 'Phone Number';
  String get email => 'Email';
  String get password => 'Password';
  String get submit => 'Submit';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get delete => 'Delete';
  String get edit => 'Edit';
  
  // Order strings
  String get placeOrder => 'Place Order';
  String get trackOrder => 'Track Order';
  String get orderStatus => 'Order Status';
  String get pending => 'Pending';
  String get assigned => 'Assigned';
  String get delivered => 'Delivered';
  
  // Wallet strings
  String get wallet => 'Wallet';
  String get balance => 'Balance';
  String get deposit => 'Deposit';
  String get withdraw => 'Withdraw';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations();

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}