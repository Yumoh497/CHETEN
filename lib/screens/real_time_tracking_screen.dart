import 'package:cheteni_delivery/providers/auth_provider.dart';
import 'package:cheteni_delivery/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class RealTimeTrackingScreen extends StatefulWidget {
  final String orderId;

  const RealTimeTrackingScreen({super.key, required this.orderId});

  @override
  State<RealTimeTrackingScreen> createState() => _RealTimeTrackingScreenState();
}

class _RealTimeTrackingScreenState extends State<RealTimeTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.authToken != null) {
      orderProvider.trackOrder(widget.orderId, authProvider.authToken!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final trackingData = orderProvider.trackingData;
    final driverLocation = trackingData?['driver']?['location'];
    final customerLocation = trackingData?['customer']?['location'];

    if (driverLocation != null && customerLocation != null) {
      final driverLatLng = LatLng(driverLocation['latitude'], driverLocation['longitude']);
      final customerLatLng = LatLng(customerLocation['latitude'], customerLocation['longitude']);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              driverLatLng.latitude < customerLatLng.latitude ? driverLatLng.latitude : customerLatLng.latitude,
              driverLatLng.longitude < customerLatLng.longitude ? driverLatLng.longitude : customerLatLng.longitude,
            ),
            northeast: LatLng(
              driverLatLng.latitude > customerLatLng.latitude ? driverLatLng.latitude : customerLatLng.latitude,
              driverLatLng.longitude > customerLatLng.longitude ? driverLatLng.longitude : customerLatLng.longitude,
            ),
          ),
          100.0, // Padding
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final trackingData = orderProvider.trackingData;

    final driverLocation = trackingData?['driver']?['location'];
    final customerLocation = trackingData?['customer']?['location'];

    final Set<Marker> markers = {};
    if (driverLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(driverLocation['latitude'], driverLocation['longitude']),
        infoWindow: const InfoWindow(title: 'Driver'),
      ));
    }
    if (customerLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(customerLocation['latitude'], customerLocation['longitude']),
        infoWindow: const InfoWindow(title: 'Customer'),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : trackingData == null
              ? const Center(child: Text('No tracking information available.'))
              : Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: driverLocation != null
                              ? LatLng(driverLocation['latitude'], driverLocation['longitude'])
                              : const LatLng(0, 0),
                          zoom: 14,
                        ),
                        markers: markers,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildStatusStep(
                                'Order Placed',
                                trackingData['status'] != 'Pending',
                                trackingData['status'] == 'Pending'),
                            _buildStatusStep(
                                'Preparing',
                                trackingData['status'] != 'Preparing',
                                trackingData['status'] == 'Preparing'),
                            _buildStatusStep(
                                'Out for Delivery',
                                trackingData['status'] == 'In Transit',
                                trackingData['status'] == 'In Transit'),
                            _buildStatusStep(
                                'Delivered', trackingData['status'] == 'Delivered', false),
                            const SizedBox(height: 20),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Driver: ${trackingData['driver']?['name'] ?? 'N/A'}'),
                                    Text('Vehicle: ${trackingData['driver']?['plate_number'] ?? 'N/A'}'),
                                    Text('Phone: ${trackingData['driver']?['phone'] ?? 'N/A'}'),
                                    Text('ETA: ${trackingData['eta'] ?? 'N/A'}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatusStep(String title, bool isCompleted, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : (isActive ? Colors.orange : Colors.grey),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? Colors.green : (isActive ? Colors.orange : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
