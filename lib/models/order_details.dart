import 'package:intl/intl.dart';

import 'package:blockatie/utils/time/jordan_time.dart';

import 'shipment_financial.dart';

class OrderDetailsResponse {
  final bool success;
  final OrderDetailsData data;

  OrderDetailsResponse({
    required this.success,
    required this.data,
  });

  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailsResponse(
      success: json['success'] ?? false,
      data: OrderDetailsData.fromJson(json['data'] ?? {}),
    );
  }
}

class OrderDetailsData {
  static const Set<int> _rateableDriverStatuses = {6, 11};

  final int orderId;
  final String placedAt;
  final String currentStatus;
  final int currentStatusId;
  final String currentStatusNameAr;
  final String currentStatusMessageEn;
  final String currentStatusMessageAr;
  final String currentStatusTypeColor;
  final List<StatusTimeline> statusTimeline;
  final bool timelineAvailable;
  final OrderDetails details;
  final Store store;
  final Driver driver;
  final ShipmentActionReasonLog? actionReason;
  final bool isDriverRated;
  final bool canRateDriver;
  final int? driverRating;
  final ShipmentFinancial? financial;
  final CancellationPreview? cancellation;

  OrderDetailsData({
    required this.orderId,
    required this.placedAt,
    required this.currentStatus,
    required this.currentStatusId,
    required this.currentStatusNameAr,
    required this.currentStatusMessageEn,
    required this.currentStatusMessageAr,
    required this.currentStatusTypeColor,
    required this.statusTimeline,
    required this.timelineAvailable,
    required this.details,
    required this.store,
    required this.driver,
    this.actionReason,
    required this.isDriverRated,
    required this.canRateDriver,
    required this.driverRating,
    this.financial,
    this.cancellation,
  });

  factory OrderDetailsData.fromJson(Map<String, dynamic> json) {
    final driver = Driver.fromJson(json['driver'] ?? {});
    final statusTimeline = (json['statusTimeline'] as List?)
            ?.map((e) => StatusTimeline.fromJson(e))
            .toList() ??
        [];
    final parsedDriverRating = _parseNullableInt(json['driver_rating']);
    final parsedIsDriverRated = json.containsKey('is_driver_rated')
        ? _parseBool(json['is_driver_rated'])
        : parsedDriverRating != null;
    final effectiveStatusId = _parseNullableInt(json['currentStatusId']) ??
        statusTimeline
            .lastWhere(
              (item) =>
                  item.nameEn == (json['currentStatus'] ?? '') ||
                  item.nameAr == (json['currentStatus'] ?? ''),
              orElse: () => StatusTimeline(
                statusId: 0,
                nameEn: '',
                nameAr: '',
                messageEn: '',
                messageAr: '',
                typeColor: '',
              ),
            )
            .statusId;
    final parsedCanRateDriver = json.containsKey('can_rate_driver')
        ? _parseBool(json['can_rate_driver'])
        : (driver.id > 0 &&
            _rateableDriverStatuses.contains(effectiveStatusId) &&
            !parsedIsDriverRated);

    return OrderDetailsData(
      orderId: json['orderId'] ?? 0,
      placedAt: json['placedAt'] ?? '',
      currentStatus: json['currentStatusNameEn'] ?? json['currentStatus'] ?? '',
      currentStatusId: effectiveStatusId,
      currentStatusNameAr: json['currentStatusNameAr'] ?? '',
      currentStatusMessageEn: json['currentStatusMessageEn'] ?? '',
      currentStatusMessageAr: json['currentStatusMessageAr'] ?? '',
      currentStatusTypeColor: json['currentStatusTypeColor'] ?? 'info',
      statusTimeline: statusTimeline,
      timelineAvailable: json.containsKey('timelineAvailable')
          ? _parseBool(json['timelineAvailable'])
          : true,
      details: OrderDetails.fromJson(json['details'] ?? {}),
      store: Store.fromJson(json['store'] ?? {}),
      driver: driver,
      actionReason: json['actionReason'] is Map
          ? ShipmentActionReasonLog.fromJson(
              Map<String, dynamic>.from(json['actionReason'] as Map),
            )
          : null,
      isDriverRated: parsedIsDriverRated,
      canRateDriver: parsedCanRateDriver,
      driverRating: parsedDriverRating,
      financial: ShipmentFinancial.tryParse(json['financial']),
      cancellation: CancellationPreview.tryParse(json['cancellation']),
    );
  }

  StatusTimeline get currentStatusSnapshot {
    StatusTimeline? matchingEvent;
    for (final event in statusTimeline.reversed) {
      if (event.statusId == currentStatusId) {
        matchingEvent = event;
        break;
      }
    }
    String preferCurrent(String current, String? fallback) =>
        current.trim().isNotEmpty ? current : (fallback ?? '');

    // Current status UI must always follow the latest order details response.
    // History can fill missing fields only for the same status ID, never a previous step.
    return StatusTimeline(
      statusId: currentStatusId,
      nameEn: preferCurrent(currentStatus, matchingEvent?.nameEn),
      nameAr: preferCurrent(currentStatusNameAr, matchingEvent?.nameAr),
      messageEn:
          preferCurrent(currentStatusMessageEn, matchingEvent?.messageEn),
      messageAr:
          preferCurrent(currentStatusMessageAr, matchingEvent?.messageAr),
      typeColor:
          preferCurrent(currentStatusTypeColor, matchingEvent?.typeColor),
      timestamp: matchingEvent?.timestamp,
    );
  }

  String get formattedPlacedAt {
    try {
      final parsedDate = JordanTime.parse(placedAt);
      if (parsedDate == null) return placedAt;
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (_) {
      return placedAt;
    }
  }

  OrderDetailsData copyWith({
    int? orderId,
    String? placedAt,
    String? currentStatus,
    int? currentStatusId,
    String? currentStatusNameAr,
    String? currentStatusMessageEn,
    String? currentStatusMessageAr,
    String? currentStatusTypeColor,
    List<StatusTimeline>? statusTimeline,
    bool? timelineAvailable,
    OrderDetails? details,
    Store? store,
    Driver? driver,
    ShipmentActionReasonLog? actionReason,
    bool? isDriverRated,
    bool? canRateDriver,
    int? driverRating,
  }) {
    return OrderDetailsData(
      orderId: orderId ?? this.orderId,
      placedAt: placedAt ?? this.placedAt,
      currentStatus: currentStatus ?? this.currentStatus,
      currentStatusId: currentStatusId ?? this.currentStatusId,
      currentStatusNameAr: currentStatusNameAr ?? this.currentStatusNameAr,
      currentStatusMessageEn:
          currentStatusMessageEn ?? this.currentStatusMessageEn,
      currentStatusMessageAr:
          currentStatusMessageAr ?? this.currentStatusMessageAr,
      currentStatusTypeColor:
          currentStatusTypeColor ?? this.currentStatusTypeColor,
      statusTimeline: statusTimeline ?? this.statusTimeline,
      timelineAvailable: timelineAvailable ?? this.timelineAvailable,
      details: details ?? this.details,
      store: store ?? this.store,
      driver: driver ?? this.driver,
      actionReason: actionReason ?? this.actionReason,
      isDriverRated: isDriverRated ?? this.isDriverRated,
      canRateDriver: canRateDriver ?? this.canRateDriver,
      driverRating: driverRating ?? this.driverRating,
      financial: financial,
      cancellation: cancellation,
    );
  }
}

class ShipmentActionReasonLog {
  const ShipmentActionReasonLog({
    required this.actionType,
    required this.reasonId,
    required this.titleAr,
    required this.titleEn,
    this.note,
    this.actorType,
    this.createdAt,
  });

  final String actionType;
  final int reasonId;
  final String titleAr;
  final String titleEn;
  final String? note;
  final String? actorType;
  final String? createdAt;

  factory ShipmentActionReasonLog.fromJson(Map<String, dynamic> json) {
    return ShipmentActionReasonLog(
      actionType: json['action_type']?.toString() ?? '',
      reasonId: int.tryParse(json['reason_id']?.toString() ?? '') ?? 0,
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      note: json['note']?.toString(),
      actorType: json['actor_type']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  String title(bool isRtl) {
    final preferred = isRtl ? titleAr : titleEn;
    final fallback = isRtl ? titleEn : titleAr;
    return preferred.trim().isNotEmpty ? preferred : fallback;
  }
}

class StatusTimeline {
  final int statusId;
  final String nameEn;
  final String nameAr;
  final String messageEn;
  final String messageAr;
  final String typeColor;
  final String? timestamp;

  StatusTimeline({
    required this.statusId,
    required this.nameEn,
    required this.nameAr,
    required this.messageEn,
    required this.messageAr,
    required this.typeColor,
    this.timestamp,
  });

  factory StatusTimeline.fromJson(Map<String, dynamic> json) {
    return StatusTimeline(
      statusId: json['statusId'] ?? 0,
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      messageEn: json['messageEn'] ?? '',
      messageAr: json['messageAr'] ?? '',
      typeColor: json['typeColor'] ?? '',
      timestamp: json['timestamp'],
    );
  }

  String localizedName(bool isRtl) {
    final label = (isRtl ? nameAr : nameEn).trim();
    return label.isNotEmpty
        ? label
        : (isRtl ? 'تم تحديث الحالة' : 'Status updated');
  }

  String localizedMessage(bool isRtl) => (isRtl ? messageAr : messageEn).trim();

  String get formattedTimestamp {
    if (timestamp == null) return '';
    try {
      final parsedDate = JordanTime.parse(timestamp);
      if (parsedDate == null) return timestamp!;
      return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
    } catch (_) {
      return timestamp!;
    }
  }
}

class OrderDetails {
  final String shipmentDate;
  final String policyNumber;
  final String? barcode;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String notes;
  final double shipmentCost;
  final double deliveryCost;
  final int percentDriver;
  final int returnedShipment;
  final int accountingShipment;
  final ProductType productType;
  final DeliveryType deliveryType;

  OrderDetails({
    required this.shipmentDate,
    required this.policyNumber,
    required this.barcode,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.notes,
    required this.shipmentCost,
    required this.deliveryCost,
    required this.percentDriver,
    required this.returnedShipment,
    required this.accountingShipment,
    required this.productType,
    required this.deliveryType,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      shipmentDate: json['shipmentDate'] ?? '',
      policyNumber: json['policyNumber'] ?? '',
      barcode: json['barcode'],
      recipientName: json['recipientName'] ?? '',
      recipientPhone: json['recipientPhone'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      deliveryLatitude: json['deliveryLatitude'] != null
          ? double.tryParse(json['deliveryLatitude'].toString())
          : null,
      deliveryLongitude: json['deliveryLongitude'] != null
          ? double.tryParse(json['deliveryLongitude'].toString())
          : null,
      notes: json['notes'] ?? '',
      shipmentCost: (json['shipmentCost'] ?? 0).toDouble(),
      deliveryCost: (json['deliveryCost'] ?? 0).toDouble(),
      percentDriver: json['percentDriver'] ?? 0,
      returnedShipment: json['returnedShipment'] ?? 0,
      accountingShipment: json['accountingShipment'] ?? 0,
      productType: ProductType.fromJson(json['productType'] ?? {}),
      deliveryType: DeliveryType.fromJson(json['deliveryType'] ?? {}),
    );
  }

  String get formattedShipmentDate {
    try {
      final parsedDate = JordanTime.parse(shipmentDate);
      if (parsedDate == null) return shipmentDate;
      return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
    } catch (_) {
      return shipmentDate;
    }
  }

  /// The backend already returns the final client-facing amount in
  /// `shipmentCost`; adding `deliveryCost` here double-counts delivery.
  double get totalCost => shipmentCost;
}

class ProductType {
  final int id;
  final String nameEn;
  final String nameAr;

  ProductType({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
    );
  }
}

class DeliveryType {
  final int id;
  final String nameEn;
  final String nameAr;

  DeliveryType({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  factory DeliveryType.fromJson(Map<String, dynamic> json) {
    return DeliveryType(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
    );
  }
}

class Store {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String link;
  final String logo;
  final double? latitude;
  final double? longitude;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.link,
    required this.logo,
    required this.latitude,
    required this.longitude,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      link: json['link'] ?? '',
      logo: json['logo'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

class Driver {
  final int id;
  final String name;
  final String phone;
  final String avatar;
  final String latitude;
  final String longitude;
  final String locationState;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.latitude,
    required this.longitude,
    this.locationState = 'unavailable',
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      locationState: json['location_state']?.toString() ?? 'unavailable',
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
