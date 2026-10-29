// location_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:location/location.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Location location = Location();
  // StreamSubscription<LocationData>? _locationSubscription;
  Timer? _periodicCheck;
  bool _isMonitoring = false;

  // Callback to show popup when location is disabled
  Function(BuildContext)? _onLocationDisabled;

  // Initialize location monitoring
  Future<void> initializeLocationMonitoring(BuildContext context) async {
    _onLocationDisabled = (context) => _showLocationDialog(context);

    if (!_isMonitoring) {
      _startPeriodicLocationCheck(context);
      _isMonitoring = true;
    }
  }

  // Start periodic location service check
  void _startPeriodicLocationCheck(BuildContext context) {
    // _periodicCheck = Timer.periodic(const Duration(seconds: 5), (timer) async {
    //   if (!_isMonitoring) return;

    //   try {
    //     bool serviceEnabled = await location.serviceEnabled();
    //     if (!serviceEnabled && _onLocationDisabled != null) {
    //       _onLocationDisabled!(context);
    //     }
    //   } catch (e) {
    //     debugPrint('Error checking location service: $e');
    //   }
    // });
  }

  // Show location dialog
  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Please Enable Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              const Text(
                'You must allow the application to access your location. Click "Retry" or enable location in your browser settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _requestLocationService(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Request location service
  Future<void> _requestLocationService(BuildContext context) async {
    // try {
    //   bool serviceEnabled = await location.serviceEnabled();
    //   if (!serviceEnabled) {
    //     serviceEnabled = await location.requestService();
    //     if (!serviceEnabled) {
    //       // Show dialog again if still not enabled
    //       _showLocationDialog(context);
    //       return;
    //     }
    //   }

    //   // Check permission as well
    //   PermissionStatus permissionGranted = await location.hasPermission();
    //   if (permissionGranted == PermissionStatus.denied) {
    //     permissionGranted = await location.requestPermission();
    //     if (permissionGranted != PermissionStatus.granted) {
    //       _showLocationDialog(context);
    //       return;
    //     }
    //   }

    //   // If we reach here, location is enabled
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Location enabled successfully!'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    // } catch (e) {
    //   debugPrint('Error requesting location service: $e');
    //   _showLocationDialog(context);
    // }
  }

  // Handle initial location permission (for GetStarted page)
  Future<bool> handleLocationPermission(BuildContext context) async {
    // try {
    //   bool serviceEnabled = await location.serviceEnabled();
    //   if (!serviceEnabled) {
    //     serviceEnabled = await location.requestService();
    //     if (!serviceEnabled) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(
    //           content: Text("Please enable location services to continue."),
    //           ),
    //         );
    //       return false;
    //     }
    //   }

    //   PermissionStatus permissionGranted = await location.hasPermission();
    //   if (permissionGranted == PermissionStatus.denied) {
    //     permissionGranted = await location.requestPermission();
    //     if (permissionGranted != PermissionStatus.granted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(
    //           content: Text("Location permission is required to proceed."),
    //           ),
    //         );
    //       return false;
    //       }
    //   }

    //   return true;
    // } catch (e) {
    //   debugPrint('Error handling location permission: $e');
    //   return false;
    // }
    return true; // Temporarily return true
  }

  // Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _periodicCheck?.cancel();
    // _locationSubscription?.cancel();
    _periodicCheck = null;
    // _locationSubscription = null;
  }

  // Dispose
  void dispose() {
    stopMonitoring();
  }
}
