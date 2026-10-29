import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/productsType_model.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:dio/dio.dart';

class ShipmentServiceException implements Exception {
  const ShipmentServiceException({
    required this.code,
    required this.messageEn,
    required this.messageAr,
    this.statusCode,
  });

  final String code;
  final String messageEn;
  final String messageAr;
  final int? statusCode;

  String localizedMessage(bool isArabic) => isArabic ? messageAr : messageEn;

  @override
  String toString() => messageEn;
}

class DeliveryQuote {
  const DeliveryQuote({
    required this.regionId,
    required this.cityId,
    required this.deliveryTypeId,
    required this.deliveryCost,
    required this.currency,
  });

  final int regionId;
  final int cityId;
  final int deliveryTypeId;
  final double deliveryCost;
  final String currency;

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) {
    final rawCost = json['delivery_cost'];
    final deliveryCost = rawCost is num
        ? rawCost.toDouble()
        : double.tryParse(rawCost?.toString() ?? '');
    if (deliveryCost == null || !deliveryCost.isFinite || deliveryCost < 0) {
      throw const ShipmentServiceException(
        code: 'INVALID_DELIVERY_QUOTE',
        messageEn: 'The delivery price returned by the server is invalid.',
        messageAr: 'سعر التوصيل المُعاد من الخادم غير صالح.',
      );
    }

    return DeliveryQuote(
      regionId: int.tryParse(json['region_id']?.toString() ?? '') ?? 0,
      cityId: int.tryParse(json['city_id']?.toString() ?? '') ?? 0,
      deliveryTypeId:
          int.tryParse(json['delivery_type_id']?.toString() ?? '') ?? 0,
      deliveryCost: deliveryCost,
      currency: (json['currency']?.toString().trim().isNotEmpty ?? false)
          ? json['currency'].toString().trim()
          : 'JOD',
    );
  }
}

typedef DeliveryQuoteLoader = Future<DeliveryQuote> Function({
  required int regionId,
  required int deliveryTypeId,
});

class ShipmentService {
  static final Dio _dio = sessionDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ),
  );

  /// Serializes the existing offset-less API field as an Asia/Amman wall clock.
  ///
  /// The backend's `shipment_date` contract is a legacy Amman-local DATETIME,
  /// not a UTC timestamp. Convert the selected instant to Amman for its civil
  /// fields only; do not append `Z` or an offset.
  static String formatJordanWallClockForApi(DateTime dateTime) {
    final jordan = JordanTime.toJordan(dateTime);
    return '${jordan.year.toString().padLeft(4, '0')}-'
        '${jordan.month.toString().padLeft(2, '0')}-'
        '${jordan.day.toString().padLeft(2, '0')} '
        '${jordan.hour.toString().padLeft(2, '0')}:'
        '${jordan.minute.toString().padLeft(2, '0')}:'
        '${jordan.second.toString().padLeft(2, '0')}';
  }

  static Options _requestOptions(
    String apiKey, {
    Map<String, String>? extraHeaders,
  }) {
    return Options(
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-API-KEY': apiKey,
        'Accept-Language': AppLocalizations.currentLocale.languageCode,
        if (extraHeaders != null) ...extraHeaders,
      },
    );
  }

  static String _languageCode() => AppLocalizations.currentLocale.languageCode;

  static String _readMessage(
    Map<String, dynamic> data, {
    required String fallbackEn,
    required String fallbackAr,
  }) {
    return _languageCode() == 'ar'
        ? _readMessageAr(data, fallback: fallbackAr)
        : _readMessageEn(data, fallback: fallbackEn);
  }

  static String _readMessageEn(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final direct = data['message_en']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final generic = data['message']?.toString().trim() ?? '';
    if (_languageCode() != 'ar' && generic.isNotEmpty) return generic;

    return fallback;
  }

  static String _readMessageAr(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final direct = data['message_ar']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final generic = data['message']?.toString().trim() ?? '';
    if (_languageCode() == 'ar' && generic.isNotEmpty) return generic;

    return fallback;
  }

  static ShipmentServiceException _exceptionFromResponse(
    dynamic data, {
    required String fallbackCode,
    required String fallbackMessageEn,
    required String fallbackMessageAr,
    int? statusCode,
  }) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return ShipmentServiceException(
        code: map['code']?.toString() ?? fallbackCode,
        messageEn: _readMessageEn(map, fallback: fallbackMessageEn),
        messageAr: _readMessageAr(map, fallback: fallbackMessageAr),
        statusCode: statusCode,
      );
    }

    return ShipmentServiceException(
      code: fallbackCode,
      messageEn: fallbackMessageEn,
      messageAr: fallbackMessageAr,
      statusCode: statusCode,
    );
  }

  static ShipmentServiceException _exceptionFromDio(
    DioException error, {
    required String fallbackCode,
    required String fallbackMessageEn,
    required String fallbackMessageAr,
  }) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return const ShipmentServiceException(
        code: 'CONNECTION_TIMEOUT',
        messageEn:
            'Unable to connect to the server. Please check your internet and try again.',
        messageAr: 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
      );
    }

    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ShipmentServiceException(
        code: 'REQUEST_TIMEOUT',
        messageEn: 'The request took too long. Please try again.',
        messageAr: 'استغرق الاتصال وقتاً أطول من المتوقع. حاول مرة أخرى.',
      );
    }

    if (error.type == DioExceptionType.badResponse) {
      return _exceptionFromResponse(
        error.response?.data,
        statusCode: error.response?.statusCode,
        fallbackCode: fallbackCode,
        fallbackMessageEn: fallbackMessageEn,
        fallbackMessageAr: fallbackMessageAr,
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return const ShipmentServiceException(
        code: 'NETWORK_ERROR',
        messageEn:
            'A network error occurred. Please check your connection and try again.',
        messageAr: 'حدث خطأ في الشبكة. تحقق من الاتصال وحاول مرة أخرى.',
      );
    }

    return ShipmentServiceException(
      code: fallbackCode,
      messageEn: fallbackMessageEn,
      messageAr: fallbackMessageAr,
      statusCode: error.response?.statusCode,
    );
  }

  static Future<ProductsTypeData> getProductTypes() async {
    try {
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        throw const ShipmentServiceException(
          code: 'AUTH_REQUIRED',
          messageEn: 'Your session is not valid. Please sign in again.',
          messageAr:
              'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
        );
      }

      final response = await _dio.get(
        AppUrls.getProductType,
        options: _requestOptions(apiKey),
      );

      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          data['status'] == 'success') {
        return ProductsTypeData.fromJson(Map<String, dynamic>.from(data));
      }
      throw _exceptionFromResponse(
        data,
        statusCode: response.statusCode,
        fallbackCode: 'PRODUCT_TYPES_UNAVAILABLE',
        fallbackMessageEn: 'Unable to load product types right now.',
        fallbackMessageAr: 'تعذر تحميل أنواع المنتجات حالياً.',
      );
    } on DioException catch (e) {
      throw _exceptionFromDio(
        e,
        fallbackCode: 'PRODUCT_TYPES_UNAVAILABLE',
        fallbackMessageEn: 'Unable to load product types right now.',
        fallbackMessageAr: 'تعذر تحميل أنواع المنتجات حالياً.',
      );
    } on ShipmentServiceException {
      rethrow;
    } catch (_) {
      throw const ShipmentServiceException(
        code: 'PRODUCT_TYPES_UNAVAILABLE',
        messageEn: 'Unable to load product types right now.',
        messageAr: 'تعذر تحميل أنواع المنتجات حالياً.',
      );
    }
  }

  /// Loads the server-authoritative delivery tariff for the authenticated
  /// merchant. The app never derives a price from a local table or another
  /// merchant's configuration.
  static Future<DeliveryQuote> getDeliveryQuote({
    required int regionId,
    required int deliveryTypeId,
  }) async {
    try {
      final apiKey = await AuthService.getApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        throw const ShipmentServiceException(
          code: 'AUTH_REQUIRED',
          messageEn: 'Your session is not valid. Please sign in again.',
          messageAr: 'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
        );
      }
      if (regionId <= 0) {
        throw const ShipmentServiceException(
          code: 'INVALID_REGION',
          messageEn: 'Choose a valid delivery area.',
          messageAr: 'يرجى اختيار منطقة توصيل صحيحة.',
        );
      }
      if (deliveryTypeId <= 0) {
        throw const ShipmentServiceException(
          code: 'INVALID_DELIVERY_TYPE',
          messageEn: 'Choose a valid delivery type.',
          messageAr: 'يرجى اختيار نوع توصيل صحيح.',
        );
      }

      final response = await _dio.post(
        AppUrls.clientShipmentQuote,
        options: _requestOptions(apiKey),
        data: {
          'governorate_id': regionId,
          'delivery_type_id': deliveryTypeId,
        },
      );
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          (data['success'] == true || data['code'] == 'DELIVERY_QUOTE_SUCCESS')) {
        return DeliveryQuote.fromJson(Map<String, dynamic>.from(data));
      }
      throw _exceptionFromResponse(
        data,
        statusCode: response.statusCode,
        fallbackCode: 'DELIVERY_QUOTE_UNAVAILABLE',
        fallbackMessageEn: 'Unable to calculate the delivery price right now.',
        fallbackMessageAr: 'تعذر احتساب سعر التوصيل حالياً.',
      );
    } on DioException catch (error) {
      throw _exceptionFromDio(
        error,
        fallbackCode: 'DELIVERY_QUOTE_UNAVAILABLE',
        fallbackMessageEn: 'Unable to calculate the delivery price right now.',
        fallbackMessageAr: 'تعذر احتساب سعر التوصيل حالياً.',
      );
    } on ShipmentServiceException {
      rethrow;
    } catch (_) {
      throw const ShipmentServiceException(
        code: 'DELIVERY_QUOTE_UNAVAILABLE',
        messageEn: 'Unable to calculate the delivery price right now.',
        messageAr: 'تعذر احتساب سعر التوصيل حالياً.',
      );
    }
  }

  /// Add a new shipment
  static Future<Map<String, dynamic>> addShipment({
    required String recipientName,
    required String recipientPhone,
    required int regionId,
    required String deliveryAddress,
    required String shipmentCost,
    required int productTypeId,
    required int deliveryTypeId,
    required DateTime shipmentDate,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? reference,
    int? piecesCount,
    String? note,
    String paymentType = 'cod',
    double? quotedDeliveryCost,
  }) async {
    try {
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        throw const ShipmentServiceException(
          code: 'AUTH_REQUIRED',
          messageEn: 'Your session is not valid. Please sign in again.',
          messageAr:
              'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
        );
      }

      if (recipientName.trim().isEmpty) {
        throw const ShipmentServiceException(
          code: 'RECIPIENT_REQUIRED',
          messageEn: 'Recipient name is required.',
          messageAr: 'اسم المستلم مطلوب.',
        );
      }
      if (recipientPhone.trim().isEmpty) {
        throw const ShipmentServiceException(
          code: 'PHONE_REQUIRED',
          messageEn: 'Recipient phone is required.',
          messageAr: 'رقم هاتف المستلم مطلوب.',
        );
      }
      if (deliveryAddress.trim().isEmpty) {
        throw const ShipmentServiceException(
          code: 'ADDRESS_REQUIRED',
          messageEn: 'Delivery address is required.',
          messageAr: 'عنوان التوصيل مطلوب.',
        );
      }
      if (shipmentCost.trim().isEmpty) {
        throw const ShipmentServiceException(
          code: 'COST_REQUIRED',
          messageEn: 'Shipment value is required.',
          messageAr: 'قيمة الشحنة مطلوبة.',
        );
      }

      if (paymentType != 'cod' && paymentType != 'prepaid') {
        throw const ShipmentServiceException(
          code: 'INVALID_PAYMENT_TYPE',
          messageEn: 'Choose a valid payment type.',
          messageAr: 'يرجى اختيار نوع دفع صحيح.',
        );
      }
      final prepaid = paymentType == 'prepaid';
      final cost = double.tryParse(shipmentCost);
      // The server enforces the same rule; prepaid has nothing to collect.
      if (cost == null || (prepaid ? cost != 0 : cost <= 0)) {
        throw ShipmentServiceException(
          code: prepaid ? 'PREPAID_COST_MUST_BE_ZERO' : 'INVALID_COST',
          messageEn: prepaid
              ? 'A prepaid shipment has no amount to collect.'
              : 'Enter a valid shipment value.',
          messageAr: prepaid
              ? 'الشحنة المدفوعة مسبقاً ليس لها مبلغ تحصيل.'
              : 'يرجى إدخال قيمة شحنة صحيحة.',
        );
      }
      if (quotedDeliveryCost != null &&
          (!quotedDeliveryCost.isFinite || quotedDeliveryCost < 0)) {
        throw const ShipmentServiceException(
          code: 'INVALID_QUOTED_DELIVERY_PRICE',
          messageEn: 'The delivery price quote is invalid. Please refresh it.',
          messageAr: 'سعر التوصيل المعروض غير صالح. يرجى تحديثه.',
        );
      }

      final requestData = <String, dynamic>{
        'client_id': clientId,
        'shipment_date': formatJordanWallClockForApi(shipmentDate),
        'recipient_name': recipientName.trim(),
        'recipient_phone': recipientPhone.trim(),
        'governorate_id': regionId,
        'delivery_address': deliveryAddress.trim(),
        'shipment_cost': prepaid ? '0' : shipmentCost.trim(),
        'payment_type': paymentType,
        'product_type_id': productTypeId,
        'delivery_type_id': deliveryTypeId,
        'nnote': note?.trim() ?? '',
        if (quotedDeliveryCost != null)
          'quoted_delivery_cost': quotedDeliveryCost.toStringAsFixed(2),
      };

      if (reference != null && reference.trim().isNotEmpty) {
        requestData['reference'] = reference.trim();
        requestData['reference_id'] = reference.trim();
      }

      if (piecesCount != null && piecesCount > 0) {
        requestData['pieces_count'] = piecesCount;
        requestData['quantity'] = piecesCount;
      }

      if (deliveryLatitude != null && deliveryLongitude != null) {
        requestData['delivery_latitude'] = deliveryLatitude;
        requestData['delivery_longitude'] = deliveryLongitude;
      }

      final lease = RequestIdService.acquire(
        operation: 'client.createShipment',
        payload: requestData,
      );
      final response = await _dio.post(
        AppUrls.createClientShipment,
        options: _requestOptions(apiKey, extraHeaders: lease.headers()),
        data: requestData,
      );
      lease.complete();

      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          ((data['success'] == true) || data['code'] == 'CREATE_SUCCESS')) {
        final map = Map<String, dynamic>.from(data);
        return {
          'success': true,
          'code': map['code']?.toString(),
          'message': _readMessage(
            map,
            fallbackEn: 'Shipment created successfully.',
            fallbackAr: 'تم إنشاء الشحنة بنجاح.',
          ),
          'message_en': _readMessageEn(
            map,
            fallback: 'Shipment created successfully.',
          ),
          'message_ar': _readMessageAr(
            map,
            fallback: 'تم إنشاء الشحنة بنجاح.',
          ),
          'shipment_id': map['shipment_id'] ?? map['id'],
          'policy_number': map['policy_number'] ?? map['policy_num'],
          'policy_num': map['policy_num'] ?? map['policy_number'],
          'delivery_cost': map['delivery_cost'],
        };
      }
      throw _exceptionFromResponse(
        data,
        statusCode: response.statusCode,
        fallbackCode: 'CREATE_FAILED',
        fallbackMessageEn: 'Unable to create the shipment right now.',
        fallbackMessageAr: 'تعذر إنشاء الشحنة حالياً.',
      );
    } on DioException catch (e) {
      throw _exceptionFromDio(
        e,
        fallbackCode: 'CREATE_FAILED',
        fallbackMessageEn: 'Unable to create the shipment right now.',
        fallbackMessageAr: 'تعذر إنشاء الشحنة حالياً.',
      );
    } on ShipmentServiceException {
      rethrow;
    } catch (_) {
      throw const ShipmentServiceException(
        code: 'CREATE_FAILED',
        messageEn: 'Unable to create the shipment right now.',
        messageAr: 'تعذر إنشاء الشحنة حالياً.',
      );
    }
  }

  /// Get all shipments for a client
  static Future<ShipmentsResponse> getAllShipments() async {
    try {
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        throw Exception('Missing user ID or API key');
      }

      final response = await _dio.post(
        AppUrls.getClientShipments,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
        ),
        data: {'clientId': clientId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return ShipmentsResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch shipments');
        }
      } else {
        throw Exception('Network error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Server error occurred');
      } else {
        throw Exception('Network error occurred');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get instant shipments for a client
  static Future<ShipmentsResponse> getInstantShipments() async {
    try {
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        throw Exception('Missing user ID or API key');
      }

      final response = await _dio.post(
        AppUrls.getClientShipmentInstant,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
        ),
        data: {'clientId': clientId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return ShipmentsResponse.fromJson(data);
        } else {
          throw Exception(
              data['message'] ?? 'Failed to fetch instant shipments');
        }
      } else {
        throw Exception('Network error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Server error occurred');
      } else {
        throw Exception('Network error occurred');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Cancel a shipment
  static Future<Map<String, dynamic>> cancelShipment({
    required int shipmentId,
  }) async {
    try {
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        throw Exception('Missing user ID or API key');
      }

      final requestData = {
        'shipment_id': shipmentId,
        'client_id': clientId,
      };
      final lease = RequestIdService.acquire(
        operation: 'client.cancelShipment',
        payload: requestData,
      );
      final response = await _dio.post(
        '${AppUrls.baseUrl}/api_cancel_shipment.php',
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
            ...lease.headers(),
          },
        ),
        data: requestData,
      );
      lease.complete();

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['message'] ?? 'Shipment cancelled successfully!',
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to cancel shipment');
        }
      } else {
        throw Exception('Network error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Server error occurred');
      } else {
        throw Exception('Network error occurred');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get shipment status
  static Future<Map<String, dynamic>> getShipmentStatus({
    required int shipmentId,
  }) async {
    try {
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        throw Exception('Missing user ID or API key');
      }

      final response = await _dio.post(
        '${AppUrls.baseUrl}/api_shipment_status.php',
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
        ),
        data: {
          'client_id': clientId,
          'shipment_id': shipmentId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return {
            'success': true,
            'status': data['shipment_status'],
            'status_name': data['status_name'],
            'driver_info': data['driver_info'],
            'location': data['location'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to get shipment status');
        }
      } else {
        throw Exception('Network error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Server error occurred');
      } else {
        throw Exception('Network error occurred');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Filter shipments
  static Future<ShipmentsResponse> filterShipments({
    int? driverId,
    String? shipmentDate,
    int? shipmentStatus,
    String? location,
  }) async {
    try {
      final clientId = await AuthService.getUserId();
      final apiKey = await AuthService.getApiKey();

      if (clientId == null || apiKey == null) {
        throw Exception('Missing user ID or API key');
      }

      final Map<String, dynamic> filterData = {'client_id': clientId};

      if (driverId != null) {
        filterData['driver_id'] = driverId;
      }
      if (shipmentDate != null) {
        filterData['shipment_date'] = shipmentDate;
      }
      if (shipmentStatus != null) {
        filterData['shipment_status'] = shipmentStatus;
      }
      if (location != null) {
        filterData['location'] = location;
      }

      final response = await _dio.post(
        '${AppUrls.baseUrl}/shipment_filter.php',
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-API-KEY': apiKey,
          },
        ),
        data: filterData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return ShipmentsResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to filter shipments');
        }
      } else {
        throw Exception('Network error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Server error occurred');
      } else {
        throw Exception('Network error occurred');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
