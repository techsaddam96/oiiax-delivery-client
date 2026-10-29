import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude, String address)
      onLocationSelected;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(31.9539, 35.9106);
  String _selectedAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final initialLat = widget.initialLatitude;
    final initialLng = widget.initialLongitude;

    if (initialLat != null &&
        initialLng != null &&
        initialLat >= -90 &&
        initialLat <= 90 &&
        initialLng >= -180 &&
        initialLng <= 180) {
      _selectedLocation = LatLng(initialLat, initialLng);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _getAddressFromCoordinates(_selectedLocation);
      });
    } else {
      _getUserCurrentLocation();
    }
  }

  Future<void> _getUserCurrentLocation() async {
    final canAccessLocation = await _checkForLocationPermission();
    if (!canAccessLocation) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) {
      return;
    }

    _selectedLocation = LatLng(position.latitude, position.longitude);
    await _getAddressFromCoordinates(_selectedLocation);

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _selectedLocation, zoom: 15),
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<bool> _checkForLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppUtils.showErrorDialog('Location services are disabled.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppUtils.showErrorDialog('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppUtils.showErrorDialog(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return false;
    }

    return true;
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        if (!mounted) {
          return;
        }
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedAddress = AppTranslations.getText('location_selected');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _getAddressFromCoordinates(position);
  }

  void _confirmLocation() {
    widget.onLocationSelected(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
      _selectedAddress,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: AppTranslations.getText('select_location'),
        subtitle: AppTranslations.getText('tap_on_map_to_select_your_location'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation,
                            zoom: 15,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          onTap: _onMapTap,
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: _selectedLocation,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          },
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xff0F172A).withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xffEEF5FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.place_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.getText('selected_location'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xff0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isLoading
                                          ? AppTranslations.getText(
                                              'getting_address',
                                            )
                                          : (_selectedAddress.isNotEmpty
                                              ? _selectedAddress
                                              : AppTranslations.getText(
                                                  'tap_on_map_to_select_location',
                                                )),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.4,
                                        color: Color(0xff64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xffE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff0F172A).withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricCard(
                          label: AppTranslations.getText('coordinates'),
                          value:
                              '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                          icon: Icons.my_location_rounded,
                        ),
                        _MetricCard(
                          label: AppTranslations.getText('selected_location'),
                          value: _selectedAddress.isNotEmpty
                              ? _selectedAddress
                              : AppTranslations.getText(
                                  'tap_on_map_to_select_location',
                                ),
                          icon: Icons.location_on_outlined,
                          expand: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _getUserCurrentLocation,
                            icon: const Icon(Icons.my_location_rounded),
                            label: Text(
                              AppTranslations.getText('location_selected'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: Color(0xffD8E8FF)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _selectedAddress.isNotEmpty ? _confirmLocation : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              AppTranslations.getText('confirm_location'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.expand = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xffEEF5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: expand ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: content);
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width > 380 ? 160 : double.infinity,
      child: content,
    );
  }
}
