import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return 'https://cheteni-001-pkwq.vercel.app';
  }

  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'API Error: ${response.statusCode} ${response.reasonPhrase}\n${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? extraHeaders}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final headers = {..._headers, ...?extraHeaders};
      final response = await http.get(uri, headers: headers).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body,
      {Map<String, String>? extraHeaders}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final headers = {..._headers, ...?extraHeaders};
      final response = await http
          .post(uri, headers: headers, body: json.encode(body))
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body,
      {Map<String, String>? extraHeaders}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final headers = {..._headers, ...?extraHeaders};
      final response = await http
          .put(uri, headers: headers, body: json.encode(body))
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> _delete(String path,
      {Map<String, String>? extraHeaders}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final headers = {..._headers, ...?extraHeaders};
      final response =
          await http.delete(uri, headers: headers).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== AUTHENTICATION ====================
  static Future<Map<String, dynamic>> adminLogin(
      {required String username, required String password}) async {
    return await _post(
        '/admin/login', {'username': username, 'password': password});
  }

  static Future<Map<String, dynamic>> customerLogin(
      {required String phone}) async {
    return await _post('/customer/login', {'phone': phone});
  }

  static Future<Map<String, dynamic>> driverLogin(
      {required String phone}) async {
    return await _post('/driver/login', {'phone': phone});
  }

  static Future<Map<String, dynamic>> agentLogin(
      {required String email, required String password}) async {
    return await _post('/agent/login', {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> adminChangePassword(
      {required String username,
      required String oldPassword,
      required String newPassword,
      required String token}) async {
    return await _post('/admin/change_password', {'new_password': newPassword},
        extraHeaders: {'Authorization': 'Bearer $token'});
  }

  // ==================== USER REGISTRATION ====================
  static Future<Map<String, dynamic>> registerCustomer(
      {required String name, required String phone, String? email}) async {
    return await _post(
        '/register_customer', {'name': name, 'phone': phone, 'email': email});
  }

  static Future<Map<String, dynamic>> registerDriver(
      {required String name,
      required String phone,
      required String plateNumber,
      required String route}) async {
    return await _post('/register_delivery_personnel', {
      'name': name,
      'phone': phone,
      'plate_number': plateNumber,
      'route': route
    });
  }

  static Future<Map<String, dynamic>> registerAgent({
    required String name,
    required String idNumber,
    required String email,
    required String phone,
    required String password,
    required String marketLocation,
  }) async {
    return await _post('/register_agent', {
      'name': name,
      'id_number': idNumber,
      'email': email,
      'phone': phone,
      'password': password,
      'market_location': marketLocation
    });
  }

  // ==================== ORDER ENDPOINTS ====================
  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData,
      {String? authToken}) async {
    return await _post('/place_order', orderData,
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getOrders(
      {String? customerPhone, String? status, String? authToken}) async {
    String path = '/orders';
    List<String> params = [];
    if (customerPhone != null) params.add('customer_phone=$customerPhone');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    return await _get(path,
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getOrderById(int orderId,
      {String? authToken}) async {
    return await _get('/orders/$orderId',
        extraHeaders:
            authToken != null ? {'Authorization': 'Bearer $authToken'} : null);
  }

  static Future<Map<String, dynamic>> trackOrder(String orderId,
      {String? authToken}) async {
    return await _get('/track_delivery?order_id=$orderId',
        extraHeaders:
            authToken != null ? {'Authorization': 'Bearer $authToken'} : null);
  }

  static Future<Map<String, dynamic>> trackDeliveryByPhone(String customerPhone,
      {String? authToken}) async {
    return await _get('/track_delivery?customer_phone=$customerPhone',
        extraHeaders:
            authToken != null ? {'Authorization': 'Bearer $authToken'} : null);
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
      int orderId, String status,
      {String? authToken}) async {
    return await _put('/orders/$orderId/status', {'status': status},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> ratePersonnel(
      {required String personnelPhone,
      required String customerPhone,
      required int rating,
      String? review,
      String? authToken}) async {
    return await _post('/personnel/rate', {
      'personnel_phone': personnelPhone,
      'customer_phone': customerPhone,
      'rating': rating,
      'review': review
    }, extraHeaders: {
      'Authorization': 'Bearer $authToken'
    });
  }

  static Future<Map<String, dynamic>> confirmDelivery(
      {required String orderId, String? authToken}) async {
    return await _post('/confirm_delivery', {'order_id': orderId},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // ==================== PRODUCT ENDPOINTS ====================
  static Future<Map<String, dynamic>> getProducts({String? authToken}) async {
    return await _get('/products',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // ==================== WALLET ENDPOINTS ====================
  static Future<Map<String, dynamic>> getWallet(
      {required String userType,
      required String userId,
      String? authToken}) async {
    return await _get('/$userType/wallet/$userId',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getWalletTransactions(
      {required String userType,
      required String userId,
      String? authToken}) async {
    return await _get('/$userType/wallet/$userId/transactions',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> depositWallet(
      {required String userType,
      required String userId,
      required double amount,
      String? authToken}) async {
    return await _post('/$userType/wallet/$userId/deposit', {'amount': amount},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> withdrawWallet(
      {required String userType,
      required String userId,
      required double amount,
      String? authToken}) async {
    return await _post('/$userType/wallet/$userId/withdraw', {'amount': amount},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // ==================== M-PESA ENDPOINTS ====================
  static Future<Map<String, dynamic>> mpesaWalletDeposit(
      String userId, double amount,
      {String? authToken}) async {
    return await _post('/mpesa/deposit', {'user_id': userId, 'amount': amount},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> mpesaWalletWithdraw(
      String userId, double amount,
      {String? authToken}) async {
    return await _post('/mpesa/withdraw', {'user_id': userId, 'amount': amount},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // ==================== PAYPAL ENDPOINTS ====================
  static Future<Map<String, dynamic>> paypalCreatePayment(
      String userId, double amount, String userType,
      {String? authToken}) async {
    return await _post('/paypal/create_payment',
        {'user_id': userId, 'amount': amount, 'user_type': userType},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> paypalExecutePayment(
      String paymentId, String payerId, String userId, String userType,
      {String? authToken}) async {
    return await _post('/paypal/execute_payment', {
      'payment_id': paymentId,
      'payer_id': payerId,
      'user_id': userId,
      'user_type': userType
    }, extraHeaders: {
      'Authorization': 'Bearer $authToken'
    });
  }

  // ==================== GOOGLE PAY ENDPOINTS ====================
  static Future<Map<String, dynamic>> googlePayDeposit(
      String userId, double amount, String userType, String paymentToken,
      {String? authToken}) async {
    return await _post('/google_pay/create_payment', {
      'user_id': userId,
      'amount': amount,
      'user_type': userType,
      'payment_token': paymentToken
    }, extraHeaders: {
      'Authorization': 'Bearer $authToken'
    });
  }

  static Future<Map<String, dynamic>> googlePayWithdraw(
      String userId, double amount, String userType,
      {String? authToken}) async {
    return await _post('/google_pay/withdraw',
        {'user_id': userId, 'amount': amount, 'user_type': userType},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // ==================== DRIVER ENDPOINTS ====================
  static Future<Map<String, dynamic>> getDriverOrders(String driverName,
      {String? authToken}) async {
    return await _get('/driver/orders?driver_name=$driverName',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getDriverProfile(String driverName,
      {String? authToken}) async {
    return await _get('/driver/profile?driver_name=$driverName',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> updateDriverOrderStatus(
      {required String customerPhone,
      required String status,
      required String driverName,
      String? authToken}) async {
    return await _post('/driver/update_status', {
      'customer_phone': customerPhone,
      'status': status,
      'driver_name': driverName
    }, extraHeaders: {
      'Authorization': 'Bearer $authToken'
    });
  }

  static Future<Map<String, dynamic>> driverConfirmDelivery(
      {required String customerPhone,
      required String driverName,
      required dynamic recipientPhoto,
      String? authToken}) async {
    return await _post('/driver/confirm_delivery', {
      'customer_phone': customerPhone,
      'driver_name': driverName,
      'photo_path': recipientPhoto.toString()
    }, extraHeaders: {
      'Authorization': 'Bearer $authToken'
    });
  }

  // ==================== AGENT ENDPOINTS ====================
  static Future<Map<String, dynamic>> getAgentOrders(
      {String? authToken}) async {
    return await _get('/agent/orders',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getAgentPersonnel(
      {String? authToken}) async {
    return await _get('/agent/personnel',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> assignOrderToPersonnel(
      {required String orderId,
      required String personnelId,
      String? authToken}) async {
    return await _post('/agent/assign_order',
        {'order_id': orderId, 'personnel_id': personnelId},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getAgentDashboardStats(
      {String? authToken}) async {
    return await _get('/agent/dashboard',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> updatePersonnelStatus(
      String personnelId, String status,
      {String? authToken}) async {
    return await _post('/agent/personnel_status',
        {'personnel_id': personnelId, 'status': status},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getAgentPricing(
      {String? authToken}) async {
    return await _get('/agent/pricing',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> updateAgentProductPricing(
      Map<String, double> productPricing,
      {String? authToken}) async {
    return await _post(
        '/agent/pricing/products', {'product_pricing': productPricing},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // ==================== ADMIN ENDPOINTS ====================
  static Future<Map<String, dynamic>> getAllAgents(
      {required String authToken}) async {
    return await _get('/admin/agents',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getAllDrivers(
      {required String authToken}) async {
    return await _get('/admin/drivers',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getAllProducts(
      {required String authToken}) async {
    return await _get('/admin/products',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getDeliveryCharges(
      {String? authToken}) async {
    return await _get('/delivery_charges',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getAdminReports(
      {String? authToken}) async {
    return await _get('/admin/reports',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> updateDeliveryCharges(
      Map<String, dynamic> rates,
      {String? authToken}) async {
    return await _post('/admin/delivery_charges', rates,
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> deleteProduct(int productId,
      {required String authToken}) async {
    return await _delete('/admin/products/$productId',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> processPayout({
    required int orderId,
    required String authToken,
  }) async {
    return await _post('/admin/pay_personnel', {'order_id': orderId},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // ==================== VENDOR ENDPOINTS ====================
  static Future<Map<String, dynamic>> vendorLogin({
    required String email,
    required String password,
  }) async {
    return await _post('/vendor/login', {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> registerVendor({
    required String vendorName,
    required String idNumber,
    required String mpesaNumber,
    required String market,
    required String email,
    required String password,
  }) async {
    return await _post('/register_vendor', {
      'name': vendorName,
      'id_number': idNumber,
      'mpesa_number': mpesaNumber,
      'market_location': market,
      'email': email,
      'password': password
    });
  }

  static Future<Map<String, dynamic>> getVendorOrders({
    String? vendorId,
    String? status,
    String? authToken,
  }) async {
    String path = '/vendor/orders';
    List<String> params = [];
    if (vendorId != null) params.add('vendor_id=$vendorId');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    return await _get(path,
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getVendorProfile({
    required String vendorId,
    String? authToken,
  }) async {
    return await _get('/vendor/profile/$vendorId',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> updateVendorOrderStatus({
    required String orderId,
    required String status,
    String? authToken,
  }) async {
    return await _put('/vendor/orders/$orderId/status', {'status': status},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> getVendorItems({
    required String vendorId,
    String? authToken,
  }) async {
    return await _get('/vendor/$vendorId/items',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> createVendorItem({
    required String vendorId,
    required String itemName,
    required double price,
    required int quantity,
    String? description,
    String? authToken,
  }) async {
    return await _post('/vendor/$vendorId/items', {
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
      'description': description,
    }, extraHeaders: {
      'Authorization': 'Bearer $authToken'
    });
  }

  static Future<Map<String, dynamic>> updateVendorItem({
    required String vendorId,
    required String itemId,
    String? itemName,
    double? price,
    int? quantity,
    String? description,
    String? authToken,
  }) async {
    final body = <String, dynamic>{};
    if (itemName != null) body['item_name'] = itemName;
    if (price != null) body['price'] = price;
    if (quantity != null) body['quantity'] = quantity;
    if (description != null) body['description'] = description;

    return await _put('/vendor/$vendorId/items/$itemId', body,
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // Vendor pickup confirmation (vendor confirms agent picked up → required for payment)
  static Future<Map<String, dynamic>> getVendorPendingPickups(
      {String? authToken}) async {
    return await _get('/vendor/pending_pickups',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> vendorConfirmPickup({
    required int pickupId,
    String? authToken,
  }) async {
    return await _post('/vendor/confirm_pickup', {'pickup_id': pickupId},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // Agent: confirm pickup from vendor (e.g. after scanning vendor QR)
  static Future<Map<String, dynamic>> agentConfirmVendorPickup({
    required int orderId,
    required int vendorId,
    double? amount,
    List<Map<String, dynamic>>? items,
    String? authToken,
  }) async {
    return await _post('/agent/confirm_vendor_pickup', {
      'order_id': orderId,
      'vendor_id': vendorId,
      if (amount != null) 'amount': amount,
      if (items != null) 'items': items,
    }, extraHeaders: {
      'Authorization': 'Bearer $authToken'
    });
  }

  static Future<Map<String, dynamic>> getAgentVendorPickups(
      {String? authToken}) async {
    return await _get('/agent/vendor_pickups',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  // Admin: vendor payouts (feedback for automatic payment)
  static Future<Map<String, dynamic>> getAdminVendorPayouts(
      {required String authToken}) async {
    return await _get('/admin/vendor_payouts',
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }

  static Future<Map<String, dynamic>> adminPayVendor({
    required int pickupId,
    required String authToken,
  }) async {
    return await _post('/admin/pay_vendor', {'pickup_id': pickupId},
        extraHeaders: {'Authorization': 'Bearer $authToken'});
  }
}
