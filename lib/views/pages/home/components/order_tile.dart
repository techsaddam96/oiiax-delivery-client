import 'dart:developer';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/constants/logic.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class HomeOrderTile extends StatelessWidget {
  const HomeOrderTile({
    super.key,
    this.clientName,
    required this.createdAt,
    required this.updateAt,
    this.isCompleted = false,
    this.isCancel = false,
    this.padding,
    this.showBtnRow = true,
    this.isInstantScren = false,
    this.imagePath = "assets/images/person.jpeg",
    this.driverPhoto,
    this.orderId = "NOB-67",
    this.actualOrderId,
    this.recipientPhone = "0779735616",
    this.driverName = "Ahmad1",
    this.isPending = true,
    this.accountingStatus = 0,
    this.hasReturn = 0,
    this.clientLocation = "Al-Muttalib Ibn Rabeeah",
    this.shipmentCost = "250.00 (JOD)",
    this.deliveryDate = "25/05/2025",
    this.onDetailTap,
    this.orderStatus,
    this.typeNameEn,
    this.statusNameAr,
    this.typeNameAr,
    this.deliveryCost,
    this.phno,
    this.notes,
    this.driverLat,
    this.driverLng,
  });

  final double? padding;
  final bool? showBtnRow;
  final bool? isInstantScren;
  final bool isCompleted;
  final bool isCancel;
  final String? deliveryCost;
  final String? phno;

  final String imagePath;
  final String? driverPhoto;
  final String updateAt;
  final String orderId;
  final String recipientPhone;
  final String driverName;
  final String createdAt;

  final bool isPending;
  final int
      accountingStatus; // 0=Unaccounted, 1=driveraccounted, 2=clientaccounted
  final int hasReturn;

  final String clientLocation;
  final String shipmentCost;
  final String deliveryDate;
  final VoidCallback? onDetailTap;
  final int? actualOrderId;
  final String? orderStatus;
  final String? typeNameEn;
  final String? statusNameAr;
  final String? typeNameAr;
  final String? clientName;
  final String? notes;
  final double? driverLat;
  final double? driverLng;
  String getShipmentUpdate() {
    DateTime dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(updateAt);
    String onlyDate = DateFormat("yyyy-MM-dd").format(dateTime);
    return onlyDate.toString();
  }

  @override
  Widget build(BuildContext context) {
    log('fdsfsdfsdg;,l ${orderStatus} ${isCompleted}');
    final textTheme = Theme.of(context).textTheme;
    final isRTL = AppLocalizations.isRTL;

    return Padding(
      padding: EdgeInsets.only(
        bottom: SizeConfig.heightMultiplier * 1.5,
        left: padding ?? SizeConfig.widthMultiplier * 0,
        right: padding ?? SizeConfig.widthMultiplier * 0,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.heightMultiplier * 1.5,
          horizontal: SizeConfig.widthMultiplier * 3,
        ),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCancel ? Colors.red : Colors.grey.shade200, width: 1),
        ),
        child: Column(
          children: [
            if (!isCompleted)
              Container(
                height: 120,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (driverLat == null || driverLat == 0.0)
                      ? GoogleMap(
                          myLocationButtonEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(31.9539, 35.9106),
                            zoom: 12,
                          ))
                      : GoogleMap(
                          myLocationButtonEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(driverLat!, driverLng!),
                            zoom: 12,
                          ),
                          markers: {
                              Marker(
                                markerId: const MarkerId('selected'),
                                position:
                                    (driverLat == null || driverLat == 0.0)
                                        ? LatLng(31.9539, 35.9106)
                                        : LatLng(driverLat!, driverLng!),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed,
                                ),
                              ),
                            }),
                ),
              ),
            Spacing.y(1),
            Row(
              children: [
                Container(
                  height: SizeConfig.heightMultiplier * 7,
                  width: SizeConfig.widthMultiplier * 16,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: driverPhoto != null
                          ? NetworkImage(
                              'https://dashboard.blockatie.com${driverPhoto!}')
                          : AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Spacing.x(2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderId,
                        style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? Colors.white : Colors.black)),
                    Text(
                      isCompleted
                          ? getShipmentUpdate()
                          : Logic.getCreatedFrom(createdAt),
                      style: textTheme.bodySmall!.copyWith(
                        fontSize: SizeConfig.textMultiplier * 1,
                        color: isCompleted ? Colors.white : Colors.black,
                      ),
                    ),

                    // Text(
                    //     "${AppTranslations.getText('recipient_number')}: $recipientPhone",
                    //     style: textTheme.bodySmall!.copyWith(
                    //         fontSize: SizeConfig.textMultiplier * 1,
                    //         color: isCompleted ? Colors.white : Colors.black)),
                    // Text(
                    //     "${AppTranslations.getText('name_drivers')}: $driverName",
                    //     style: textTheme.bodySmall!.copyWith(
                    //       color: isCompleted ? Colors.white : Colors.black,
                    //       fontSize: SizeConfig.textMultiplier * 1,
                    //     )),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display order status (status_name_en)
                    if (orderStatus != null)
                      _statusTag(
                        text:
                            _getLocalizedStatusName(orderStatus!, statusNameAr),
                        icon: _getStatusIcon(orderStatus!),
                        color: _getStatusColor(orderStatus!),
                        bgColor: isCompleted
                            ? Colors.white
                            : _getStatusBgColor(orderStatus!),
                      ),
                    // Display shipment type (type_name_en)
                    if (typeNameEn != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _statusTag(
                          text: _getLocalizedTypeName(typeNameEn!, typeNameAr),
                          icon: 'assets/icons/shipment.png',
                          color: isCompleted ? Colors.white : Colors.blue,
                          bgColor: Colors.blue.shade50,
                        ),
                      ),
                    // Display accounting status (accounting_shipment)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _statusTag(
                        text: _getAccountingStatusText(accountingStatus),
                        icon: 'assets/images/non-return.png',
                        color: _getAccountingStatusColor(accountingStatus),
                        bgColor: _getAccountingStatusBgColor(accountingStatus),
                      ),
                    ),
                    // Display return status (returned_shipment)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _statusTag(
                        text: hasReturn == 0
                            ? AppTranslations.getText('no_return')
                            : hasReturn == 2
                                ? AppTranslations.getText('there_is_return')
                                : AppTranslations.getText('returned'),
                        icon: hasReturn == 0
                            ? 'assets/images/non-return.png'
                            : hasReturn == 2
                                ? 'assets/images/return.png'
                                : 'assets/images/return.png',
                        color: hasReturn == 0
                            ? Colors.red
                            : hasReturn == 2
                                ? Colors.green
                                : Colors.grey,
                        bgColor: hasReturn == 0
                            ? Colors.red.withOpacity(0.2)
                            : hasReturn == 2
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ],
                )
              ],
            ),
            Spacing.y(2.5),
            /* ------------------------- First Row info of order ------------------------ */
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _rowInfo(textTheme, AppTranslations.getText('client_name'),
                    clientName ?? "", "assets/images/profile_filled.png"),
                _rowInfo(textTheme, AppTranslations.getText('client_phone'),
                    phno!, "assets/images/phone_filled.png"),
                isCompleted
                    ? _rowInfo(
                        textTheme,
                        AppTranslations.getText('shipment_cost'),
                        shipmentCost,
                        "assets/icons/shipment_cost.png")
                    : _rowInfo(
                        textTheme,
                        AppTranslations.getText('client_location'),
                        clientLocation,
                        "assets/icons/location.png"),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                isCompleted
                    ? _rowInfo(
                        textTheme,
                        AppTranslations.getText('driver_name'),
                        driverName,
                        "assets/images/profile_filled.png")
                    : _rowInfo(
                        textTheme,
                        AppTranslations.getText('shipment_cost'),
                        shipmentCost,
                        "assets/icons/shipment_cost.png"),

                //
                _rowInfo(textTheme, AppTranslations.getText('delivery_cost'),
                    deliveryCost ?? "", "assets/icons/delivered_at.png"),
                _rowInfo(textTheme, AppTranslations.getText('shipment_note'),
                    notes ?? "", "assets/images/profile_filled.png"),
              ],
            ),
            Spacing.y(2.5),
            /* ------------------------ Second Row info of order ------------------------ */
            // if (isCompleted)
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       _rowInfo(
            //           textTheme,
            //           AppTranslations.getText('phone_number'),
            //           phno ?? "Al-Muttalib Ibn Rabeeah",
            //           "assets/images/phone.png"),
            //       // _rowInfo(textTheme, AppTranslations.getText('shipment_cost'),
            //       //     '$shipmentCost(JOD)', "assets/icons/shipment_cost.png"),
            //       _rowInfo(textTheme, AppTranslations.getText('delivery_cost'),
            //           '$deliveryCost(JOD)', "assets/icons/delivered_at.png"),
            //       Expanded(child: SizedBox())
            //     ],
            //   ),
            if (!showBtnRow!)
              SizedBox(
                width: SizeConfig.widthMultiplier * 85,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  label: Text(AppTranslations.getText('accept_order')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

            if (!isCompleted)
              InkWell(
                onTap: onDetailTap ??
                    () {
                      if (actualOrderId != null) {
                        Nav.to(
                          OrderDetailPage(orderId: actualOrderId),
                          withNav: true,
                          navIndex: 1,
                        );
                      }
                    },
                child: Container(
                  height: SizeConfig.heightMultiplier * 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isCancel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Center(
                    child: Text(
                      AppTranslations.getText('order_details'),
                      style: textTheme.bodyMedium!.copyWith(
                          color: isCancel ? Colors.white : AppColors.primary),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _statusTag({
    required String text,
    required String icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Image.asset(
            icon,
            width: 10,
            height: 10,
            color: color,
          ),
          Spacing.x(1),
          Text(
            text,
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(
      TextTheme textTheme, String title, String subtitle, String icon) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            icon,
            height: 10,
            color: isCompleted ? Colors.white : Colors.black,
          ),
          Spacing.x(1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: textTheme.bodySmall!.copyWith(
                        fontSize: SizeConfig.textMultiplier * 1.1,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.white : Colors.black)),
                Spacing.y(.3),
                Text(subtitle,
                    style: textTheme.bodySmall!.copyWith(
                        fontSize: SizeConfig.textMultiplier * 1,
                        color: isCompleted ? Colors.white : Colors.black),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for status styling
  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'assets/images/pending.png';
      case 'processing':
        return 'assets/images/inprogress.png';
      case 'dispatched':
        return 'assets/images/shipment.png';
      case 'in transit':
        return 'assets/images/shipment.png';
      case 'out for delivery':
        return 'assets/images/shipment.png';
      case 'delivered':
        return 'assets/images/shipment.png';
      case 'completed':
        return 'assets/images/shipment.png';
      case 'cancelled':
        return 'assets/images/cancelled.png';
      case 'returned':
        return 'assets/images/return.png';
      case 'failed delivery':
        return 'assets/images/cancelled.png';
      case 'awaiting pickup':
        return 'assets/images/pending.png';
      default:
        return 'assets/images/pending.png';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'in transit':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'delivered':
        return Colors.green;
      case 'dispatched':
        return Colors.indigo;
      case 'out for delivery':
        return Colors.teal;
      case 'awaiting pickup':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      case 'failed delivery':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Color _getStatusBgColor(String status) {
  //   switch (status.toLowerCase()) {
  //     case 'pending':
  //       return Colors.orange.shade50;
  //     case 'processing':
  //       return Colors.blue.shade50;
  //     case 'in transit':
  //       return Colors.purple.shade50;
  //     case 'completed':
  //       return Colors.green.shade50;
  //     case 'delivered':
  //       return Colors.green.shade50;
  //     case 'dispatched':
  //       return Colors.indigo.shade50;
  //     case 'out for delivery':
  //       return Colors.teal.shade50;
  //     case 'awaiting pickup':
  //       return Colors.amber.shade50;
  //     case 'cancelled':
  //     case 'returned':
  //     case 'failed delivery':
  //       return Colors.red.shade50;
  //     default:
  //       return Colors.grey.shade50;
  //   }
  // }
  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue.withAlpha(30);
      case 'processing':
        return Colors.orange.withAlpha(30);
      case 'in transit':
        return Colors.purple.withAlpha(30);
      case 'completed':
        return Colors.green.withAlpha(30);
      case 'delivered':
        return Colors.green.withAlpha(30);
      case 'dispatched':
        return Colors.indigo.withAlpha(30);
      case 'out for delivery':
        return Colors.teal.withAlpha(30);
      case 'awaiting pickup':
        return Colors.amber.withAlpha(30);
      case 'cancelled':
        return Colors.red.withAlpha(30);
      case 'failed delivery':
        return Colors.red;
      default:
        return Colors.grey.withAlpha(30);
    }
  }

  // Helper methods for accounting status
  String _getAccountingStatusText(int accountingStatus) {
    switch (accountingStatus) {
      case 0:
        return AppTranslations.getText('unaccounted');
      case 1:
        return AppTranslations.getText('driver_accounted');
      case 2:
        return AppTranslations.getText('client_accounted');
      default:
        return AppTranslations.getText('unknown');
    }
  }

  Color _getAccountingStatusColor(int accountingStatus) {
    switch (accountingStatus) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getAccountingStatusBgColor(int accountingStatus) {
    switch (accountingStatus) {
      case 0:
        return Colors.orange.shade50;
      case 1:
        return Colors.blue.shade50;
      case 2:
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  // Localization methods for status and type names
  String _getLocalizedStatusName(String statusName, String? arName) {
    if (AppLocalizations.isRTL && arName != null && arName.isNotEmpty) {
      return arName;
    }
    return statusName;
  }

  String _getLocalizedTypeName(String typeName, String? arName) {
    if (AppLocalizations.isRTL && arName != null && arName.isNotEmpty) {
      return arName;
    }
    return typeName;
  }
}
