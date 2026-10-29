import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'status_indicator.dart';

class StoreDeliveryDetails extends StatelessWidget {
  const StoreDeliveryDetails({super.key, this.orderDetails});

  final OrderDetailsData? orderDetails;

  void _showDriverLocationOnMap(BuildContext context) {
    if (orderDetails?.driver.latitude.isEmpty == true ||
        orderDetails?.driver.longitude.isEmpty == true) {
      AppUtils.showWarningDialog(
        AppTranslations.getText('driver_location_not_available'),
      );
      return;
    }

    final lat = double.tryParse(orderDetails!.driver.latitude);
    final lng = double.tryParse(orderDetails!.driver.longitude);

    if (lat == null || lng == null) {
      AppUtils.showErrorDialog(
        AppTranslations.getText('invalid_driver_location_coordinates'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverLocationMapPage(
          driverName: orderDetails!.driver.name,
          latitude: lat,
          longitude: lng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(Nav.context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                StatusIndicator(
                  containersize: 30,
                  radius: 8,
                  iconColor: AppColors.primary,
                  continercolor: AppColors.bgColor,
                  iconsize: 15,
                  icon: 'assets/images/store_detail.png',
                  label: '',
                  isActive: false,
                  isCompleted: false,
                  showLabel: false,
                ),
                Container(
                  width: 1.5,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                StatusIndicator(
                  containersize: 30,
                  radius: 8,
                  iconColor: AppColors.primary,
                  continercolor: AppColors.bgColor,
                  iconsize: 15,
                  icon: 'assets/images/deliverydetail.png',
                  label: '',
                  isActive: false,
                  isCompleted: false,
                  showLabel: false,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getText('client_details'),
                              style: textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Spacing.y(.2),
                            Text(
                              orderDetails?.details.recipientName ??
                                  AppTranslations.getText(
                                    'store_name_not_available',
                                  ),
                              style: textTheme.bodySmall!.copyWith(
                                letterSpacing: -0.3,
                                fontSize: 10,
                                color: AppColors.textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacing.y(.2),
                            Text(
                              orderDetails?.details.deliveryAddress ??
                                  AppTranslations.getText(
                                    'address_not_available',
                                  ),
                              style: textTheme.bodySmall!.copyWith(
                                letterSpacing: -0.3,
                                fontSize: 10,
                                color: AppColors.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'tel:${orderDetails?.details.recipientPhone}',
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/images/phone.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getText('driver_details'),
                              style: textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Spacing.y(.2),
                            Text(
                              orderDetails?.driver.name ??
                                  AppTranslations.getText(
                                    'driver_name_not_available',
                                  ),
                              style: textTheme.bodySmall!.copyWith(
                                letterSpacing: -0.3,
                                fontSize: 10,
                                color: AppColors.textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacing.y(.2),
                            Text(
                              orderDetails?.driver.phone ??
                                  AppTranslations.getText(
                                    'phone_not_available',
                                  ),
                              style: textTheme.bodySmall!.copyWith(
                                letterSpacing: -0.3,
                                fontSize: 10,
                                color: AppColors.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _showDriverLocationOnMap(context),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.map,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Spacing.x(4),
                      InkWell(
                        onTap: () {
                          launchUrl(
                            Uri.parse('tel:${orderDetails?.driver.phone}'),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/images/phone.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverLocationMapPage extends StatelessWidget {
  const DriverLocationMapPage({
    super.key,
    required this.driverName,
    required this.latitude,
    required this.longitude,
  });

  final String driverName;
  final double latitude;
  final double longitude;

  Future<void> _openMap(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final driverLocation = LatLng(latitude, longitude);
    final title = AppTranslations.getText('driver_location');
    final subtitle = driverName.trim().isNotEmpty
        ? driverName
        : AppTranslations.getText('driver_current_location');
    final coordinates =
        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: title,
        subtitle: subtitle,
        onBack: Nav.back,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0F172A).withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppTranslations.getText('driver_current_location'),
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          coordinates,
                          style: const TextStyle(
                            color: Color(0xff334155),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openMap(latitude, longitude),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                    ),
                    label: Text(
                      AppLocalizations.isRTL
                          ? '\u0641\u062A\u062D \u0627\u0644\u062E\u0631\u064A\u0637\u0629'
                          : 'Open map',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xffE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff0F172A).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: driverLocation,
                      zoom: 15,
                    ),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: driverLocation,
                        infoWindow: InfoWindow(
                          title: driverName.isNotEmpty ? driverName : title,
                          snippet: AppTranslations.getText(
                            'driver_current_location',
                          ),
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
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
