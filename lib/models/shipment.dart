import 'package:intl/intl.dart';

import 'package:blockatie/utils/time/jordan_time.dart';

class ShipmentsResponse {
  final String status;
  final String message;
  final int clientId;
  final int count;
  final List<Shipment> shipments;

  ShipmentsResponse({
    required this.status,
    required this.message,
    required this.clientId,
    required this.count,
    required this.shipments,
  });

  factory ShipmentsResponse.fromJson(Map<String, dynamic> json) {
    return ShipmentsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      clientId:
          json['clientId'] != null ? int.parse(json['clientId'].toString()) : 0,
      count: json['count'] != null ? int.parse(json['count'].toString()) : 0,
      shipments:
          (json['shipments'] as List).map((e) => Shipment.fromJson(e)).toList(),
    );
  }
}

class Shipment {
  static const Set<int> _rateableDriverStatuses = {6, 7, 8, 9, 11};

  final int id;
  final String shipmentDate;
  final String policyNum;
  final String? barcode;
  final String recipientName;
  final String recipientPhone;
  final int storeId;
  final int governorateId;
  final String deliveryAddress;
  final int? driverId;
  final String deliveryTypeNameEn;
  final String shipmentCost;
  final String deliveryCost;
  final int percentDriver;
  final String shipmentNote;
  final int employeeId;
  final int deliveryTypeId;
  final int productTypeId;
  final int shipmentStatus;
  final int accountingShipment;
  final int returnedShipment;
  final String createdAt;
  final String updatedAt;
  final int shipmentStatusId;
  final String? statusNameEn;
  final String? statusNameAr;
  final String? typeColor;
  final String? messageEn;
  final String? messageAr;
  final String? typeNameEn;
  final String? typeNameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? driverName;
  final String? driverPhone;
  final String? driverImg;
  final double? driverLatitude;
  final double? driverLongitude;
  final double? storeLatitude;
  final double? storeLongitude;
  final bool isDriverRated;
  final bool canRateDriver;
  final int? driverRating;

  /// `shipment_cost` is the final client-facing shipment amount returned by
  /// the existing API. `delivery_cost` is kept separately for operational data
  /// and must not be added again to the customer total.
  double get totalCost => _parseMoney(shipmentCost);

  Shipment({
    required this.id,
    required this.shipmentDate,
    required this.policyNum,
    required this.barcode,
    required this.deliveryTypeNameEn,
    required this.recipientName,
    required this.recipientPhone,
    required this.storeId,
    required this.governorateId,
    required this.deliveryAddress,
    required this.driverId,
    required this.shipmentCost,
    required this.deliveryCost,
    required this.percentDriver,
    required this.shipmentNote,
    required this.employeeId,
    required this.deliveryTypeId,
    required this.productTypeId,
    required this.shipmentStatus,
    required this.accountingShipment,
    required this.returnedShipment,
    required this.createdAt,
    required this.updatedAt,
    required this.shipmentStatusId,
    required this.statusNameEn,
    required this.statusNameAr,
    required this.typeColor,
    required this.messageEn,
    required this.messageAr,
    required this.typeNameEn,
    required this.typeNameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.driverName,
    required this.driverPhone,
    required this.driverImg,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.isDriverRated,
    required this.canRateDriver,
    required this.driverRating,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final parsedDriverId = json['driver_id'] != null
        ? int.tryParse(json['driver_id'].toString())
        : null;
    final parsedStatusId = json['shipment_status_id'] != null
        ? int.tryParse(json['shipment_status_id'].toString()) ?? 0
        : json['order_status_id'] != null
            ? int.tryParse(json['order_status_id'].toString()) ?? 0
            : json['shipment_status_id_raw'] != null
                ? int.tryParse(json['shipment_status_id_raw'].toString()) ?? 0
                : json['shipment_status'] != null
                    ? int.tryParse(json['shipment_status'].toString()) ?? 0
                    : 0;
    final parsedDriverRating = _parseNullableInt(json['driver_rating']);
    final parsedIsDriverRated = json.containsKey('is_driver_rated')
        ? _parseBool(json['is_driver_rated'])
        : parsedDriverRating != null;
    final parsedCanRateDriver = json.containsKey('can_rate_driver')
        ? _parseBool(json['can_rate_driver'])
        : (parsedDriverId != null &&
            parsedDriverId > 0 &&
            _rateableDriverStatuses.contains(parsedStatusId) &&
            !parsedIsDriverRated);

    return Shipment(
      id: json['shipment_id'] != null
          ? int.tryParse(json['shipment_id'].toString()) ?? 0
          : json['id'] != null
              ? int.tryParse(json['id'].toString()) ?? 0
              : 0,
      shipmentDate: json['shipment_date']?.toString() ?? '',
      policyNum: json['policy_num']?.toString() ?? '',
      deliveryTypeNameEn: json['delivery_type_name_en']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      recipientName: json['recipient_name']?.toString() ?? '',
      recipientPhone: json['recipient_phone']?.toString() ?? '',
      storeId: json['store_id'] != null
          ? int.tryParse(json['store_id'].toString()) ?? 0
          : 0,
      governorateId: json['governorate_id'] != null
          ? int.tryParse(json['governorate_id'].toString()) ?? 0
          : 0,
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      driverId: parsedDriverId,
      shipmentCost: json['shipment_cost']?.toString() ?? '0.00',
      deliveryCost: json['delivery_cost']?.toString() ?? '0.00',
      percentDriver: json['percent_driver'] != null
          ? int.tryParse(json['percent_driver'].toString()) ?? 0
          : 0,
      shipmentNote: json['shipment_note']?.toString() ?? '',
      employeeId: json['employee_id'] != null
          ? int.tryParse(json['employee_id'].toString()) ?? 0
          : 0,
      deliveryTypeId: json['delivery_type_id'] != null
          ? int.tryParse(json['delivery_type_id'].toString()) ?? 0
          : 0,
      productTypeId: json['product_type_id'] != null
          ? int.tryParse(json['product_type_id'].toString()) ?? 0
          : 0,
      shipmentStatus: json['shipment_status'] != null
          ? int.tryParse(json['shipment_status'].toString()) ?? 0
          : 0,
      accountingShipment: json['accounting_shipment'] != null
          ? int.tryParse(json['accounting_shipment'].toString()) ?? 0
          : 0,
      returnedShipment: json['returned_shipment'] != null
          ? int.tryParse(json['returned_shipment'].toString()) ?? 0
          : 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      shipmentStatusId: parsedStatusId,
      statusNameEn: json['status_name_en'] != null
          ? json['status_name_en']?.toString()
          : json['order_status_name_en']?.toString(),
      statusNameAr: json['status_name_ar'] != null
          ? json['status_name_ar']?.toString()
          : json['order_status_name_ar']?.toString(),
      typeColor: json['type_color']?.toString(),
      messageEn: json['message_en']?.toString(),
      messageAr: json['message_ar']?.toString(),
      typeNameEn:
          (json['type_name_en'] ?? json['delivery_type_name_en'])?.toString(),
      typeNameAr:
          (json['type_name_ar'] ?? json['delivery_type_name_ar'])?.toString(),
      descriptionEn: json['description_en']?.toString(),
      descriptionAr: json['description_ar']?.toString(),
      driverName: json['dname'] != null
          ? json['dname']?.toString()
          : json['driver_name'],
      driverPhone: json['dphone'] != null
          ? json['dphone']?.toString()
          : json['driver_phone'],
      driverImg:
          json['img'] != null ? json['img'].toString() : json['driver_img'],
      driverLatitude: json['driver_latitude'] != null
          ? double.tryParse(json['driver_latitude'].toString()) ?? 0
          : 0,
      driverLongitude: json['driver_longitude'] != null
          ? double.tryParse(json['driver_longitude'].toString()) ?? 0
          : 0,
      storeLatitude: json['store_latitude'] != null
          ? double.tryParse(json['store_latitude'].toString()) ?? 0
          : 0,
      storeLongitude: json['store_longitude'] != null
          ? double.tryParse(json['store_longitude'].toString()) ?? 0
          : 0,
      isDriverRated: parsedIsDriverRated,
      canRateDriver: parsedCanRateDriver,
      driverRating: parsedDriverRating,
    );
    //driverLatitude: json['driver_latitude'],
    //driverLongitude: json['driver_longitude'] ?? 0,
    //storeLatitude: json['store_latitude'] ?? 0,
    //storeLongitude: json['store_longitude'] ?? 0);
  }

  String get formattedShipmentDate {
    try {
      final parsedDate = JordanTime.parse(shipmentDate);
      if (parsedDate == null) return shipmentDate;
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (_) {
      return shipmentDate; // fallback in case of error
    }
  }

  static double _parseMoney(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
  }

  Shipment copyWith({
    int? id,
    String? shipmentDate,
    String? policyNum,
    String? barcode,
    String? recipientName,
    String? recipientPhone,
    int? storeId,
    int? governorateId,
    String? deliveryAddress,
    int? driverId,
    String? deliveryTypeNameEn,
    String? shipmentCost,
    String? deliveryCost,
    int? percentDriver,
    String? shipmentNote,
    int? employeeId,
    int? deliveryTypeId,
    int? productTypeId,
    int? shipmentStatus,
    int? accountingShipment,
    int? returnedShipment,
    String? createdAt,
    String? updatedAt,
    int? shipmentStatusId,
    String? statusNameEn,
    String? statusNameAr,
    String? typeColor,
    String? messageEn,
    String? messageAr,
    String? typeNameEn,
    String? typeNameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? driverName,
    String? driverPhone,
    String? driverImg,
    double? driverLatitude,
    double? driverLongitude,
    double? storeLatitude,
    double? storeLongitude,
    bool? isDriverRated,
    bool? canRateDriver,
    int? driverRating,
  }) {
    return Shipment(
      id: id ?? this.id,
      shipmentDate: shipmentDate ?? this.shipmentDate,
      policyNum: policyNum ?? this.policyNum,
      barcode: barcode ?? this.barcode,
      deliveryTypeNameEn: deliveryTypeNameEn ?? this.deliveryTypeNameEn,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      storeId: storeId ?? this.storeId,
      governorateId: governorateId ?? this.governorateId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      driverId: driverId ?? this.driverId,
      shipmentCost: shipmentCost ?? this.shipmentCost,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      percentDriver: percentDriver ?? this.percentDriver,
      shipmentNote: shipmentNote ?? this.shipmentNote,
      employeeId: employeeId ?? this.employeeId,
      deliveryTypeId: deliveryTypeId ?? this.deliveryTypeId,
      productTypeId: productTypeId ?? this.productTypeId,
      shipmentStatus: shipmentStatus ?? this.shipmentStatus,
      accountingShipment: accountingShipment ?? this.accountingShipment,
      returnedShipment: returnedShipment ?? this.returnedShipment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shipmentStatusId: shipmentStatusId ?? this.shipmentStatusId,
      statusNameEn: statusNameEn ?? this.statusNameEn,
      statusNameAr: statusNameAr ?? this.statusNameAr,
      typeColor: typeColor ?? this.typeColor,
      messageEn: messageEn ?? this.messageEn,
      messageAr: messageAr ?? this.messageAr,
      typeNameEn: typeNameEn ?? this.typeNameEn,
      typeNameAr: typeNameAr ?? this.typeNameAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverImg: driverImg ?? this.driverImg,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      storeLatitude: storeLatitude ?? this.storeLatitude,
      storeLongitude: storeLongitude ?? this.storeLongitude,
      isDriverRated: isDriverRated ?? this.isDriverRated,
      canRateDriver: canRateDriver ?? this.canRateDriver,
      driverRating: driverRating ?? this.driverRating,
    );
  }
}

bool _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  return int.tryParse(value.toString());
}
