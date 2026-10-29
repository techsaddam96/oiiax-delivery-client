import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';

class SimpleLocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude, String address)
      onLocationSelected;

  const SimpleLocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<SimpleLocationPickerPage> createState() =>
      _SimpleLocationPickerPageState();
}

class _SimpleLocationPickerPageState extends State<SimpleLocationPickerPage> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  // Predefined locations in Jordan
  final List<Map<String, dynamic>> _predefinedLocations = [
    {
      'name': 'Amman',
      'latitude': 31.9539,
      'longitude': 35.9106,
      'address': 'Amman, Jordan'
    },
    {
      'name': 'Zarqa',
      'latitude': 32.0728,
      'longitude': 36.0897,
      'address': 'Zarqa, Jordan'
    },
    {
      'name': 'Irbid',
      'latitude': 32.5556,
      'longitude': 35.8500,
      'address': 'Irbid, Jordan'
    },
    {
      'name': 'Aqaba',
      'latitude': 29.5267,
      'longitude': 35.0078,
      'address': 'Aqaba, Jordan'
    },
    {
      'name': 'Salt',
      'latitude': 32.0392,
      'longitude': 35.7272,
      'address': 'Salt, Jordan'
    },
    {
      'name': 'Madaba',
      'latitude': 31.7161,
      'longitude': 35.7933,
      'address': 'Madaba, Jordan'
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _latitudeController.text = widget.initialLatitude!.toString();
      _longitudeController.text = widget.initialLongitude!.toString();
      _getAddressFromCoordinates(
          widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      setState(() {
        _addressController.text = AppTranslations.getText('location_selected');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPredefinedLocation(Map<String, dynamic> location) {
    setState(() {
      _latitudeController.text = location['latitude'].toString();
      _longitudeController.text = location['longitude'].toString();
      _addressController.text = location['address'];
    });
  }

  void _confirmLocation() {
    final lat = double.tryParse(_latitudeController.text);
    final lng = double.tryParse(_longitudeController.text);

    if (lat != null && lng != null) {
      widget.onLocationSelected(
        lat,
        lng,
        _addressController.text.isNotEmpty
            ? _addressController.text
            : AppTranslations.getText('custom_location'),
      );
      Navigator.pop(context);
    } else {
      AppUtils.showErrorDialog(
          AppTranslations.getText('please_enter_valid_coordinates'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: AppTranslations.getText('select_location'),
        subtitle: AppTranslations.getText(
            'choose_from_predefined_locations_or_enter_coordinates'),
        showBtn: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Predefined Locations Section
            Text(
              AppTranslations.getText('predefined_locations'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Spacing.y(1),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _predefinedLocations.length,
                itemBuilder: (context, index) {
                  final location = _predefinedLocations[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      location['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      location['address'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      '${location['latitude'].toStringAsFixed(4)}, ${location['longitude'].toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                    onTap: () => _selectPredefinedLocation(location),
                  );
                },
              ),
            ),

            Spacing.y(2),

            // Custom Coordinates Section
            Text(
              AppTranslations.getText('custom_coordinates'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Spacing.y(1),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latitudeController,
                          decoration: InputDecoration(
                            labelText: AppTranslations.getText('latitude'),
                            hintText: 'e.g., 31.9539',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      Spacing.x(1),
                      Expanded(
                        child: TextField(
                          controller: _longitudeController,
                          decoration: InputDecoration(
                            labelText: AppTranslations.getText('longitude'),
                            hintText: 'e.g., 35.9106',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Spacing.y(1),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: AppTranslations.getText('address_optional'),
                      hintText: AppTranslations.getText(
                          'enter_address_or_leave_empty_to_auto_detect'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  Spacing.y(1),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  final lat =
                                      double.tryParse(_latitudeController.text);
                                  final lng = double.tryParse(
                                      _longitudeController.text);
                                  if (lat != null && lng != null) {
                                    _getAddressFromCoordinates(lat, lng);
                                  }
                                },
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(_isLoading
                              ? AppTranslations.getText('getting_address')
                              : AppTranslations.getText('get_address')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Spacing.y(2),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppTranslations.getText('confirm_location'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
