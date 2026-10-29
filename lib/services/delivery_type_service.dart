import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DeliveryTypeService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ),
  );

  static List<Map<String, dynamic>>? _deliveryTypes;
  static bool _isLoading = false;

  static List<Map<String, dynamic>>? get deliveryTypes => _deliveryTypes;
  static bool get isLoading => _isLoading;

  static Future<void> loadDeliveryTypes({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }
    if (!forceRefresh && _deliveryTypes != null && _deliveryTypes!.isNotEmpty) {
      return;
    }

    _isLoading = true;

    try {
      final apiKey = await AuthService.getApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        _deliveryTypes = _defaultDeliveryTypes();
        return;
      }

      final response = await _dio.get(
        AppUrls.getDeliveryTypes,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-API-KEY': apiKey,
          },
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          data['status'] == 'success' &&
          data['delivery_types'] is List) {
        _deliveryTypes = List<Map<String, dynamic>>.from(
          data['delivery_types'] as List,
        );
      } else {
        _deliveryTypes = _defaultDeliveryTypes();
      }
    } catch (_) {
      _deliveryTypes = _defaultDeliveryTypes();
    } finally {
      _isLoading = false;
    }
  }

  static Map<String, dynamic>? getDeliveryTypeById(int id) {
    final types = _deliveryTypes;
    if (types == null || types.isEmpty) {
      return null;
    }

    try {
      return types.firstWhere(
        (type) => type['id'].toString() == id.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static String getDeliveryTypeName(int id) {
    final type = getDeliveryTypeById(id);
    return (type?['type_name_en']?.toString().trim().isNotEmpty ?? false)
        ? type!['type_name_en'].toString().trim()
        : 'Unknown';
  }

  static String getDeliveryTypeNameAr(int id) {
    final type = getDeliveryTypeById(id);
    return (type?['type_name_ar']?.toString().trim().isNotEmpty ?? false)
        ? type!['type_name_ar'].toString().trim()
        : 'غير متوفر';
  }

  static String getDeliveryTypeDescription(int id) {
    final type = getDeliveryTypeById(id);
    return type?['description_en']?.toString().trim() ?? '';
  }

  static String getDeliveryTypeDescriptionAr(int id) {
    final type = getDeliveryTypeById(id);
    return type?['description_ar']?.toString().trim() ?? '';
  }

  static List<Map<String, dynamic>> getAllDeliveryTypes() {
    return _deliveryTypes ?? const <Map<String, dynamic>>[];
  }

  static String getDeliveryTypeColor(int id) {
    switch (id) {
      case 1:
        return 'primary';
      case 2:
        return 'blue';
      case 3:
        return 'green';
      case 4:
        return 'orange';
      case 5:
        return 'grey';
      case 6:
        return 'red';
      case 7:
        return 'purple';
      default:
        return 'primary';
    }
  }

  static String getDeliveryTypeIcon(int id) {
    switch (id) {
      case 1:
        return 'assets/images/instant.png';
      case 2:
        return 'assets/images/clock.png';
      case 3:
        return 'assets/images/same_day.png';
      case 4:
        return 'assets/images/next_day.png';
      case 5:
        return 'assets/images/economy.png';
      case 6:
        return 'assets/images/express.png';
      case 7:
        return 'assets/images/contactless.png';
      default:
        return 'assets/images/instant.png';
    }
  }

  static void clearCache() {
    _deliveryTypes = null;
  }

  static Future<void> reloadDeliveryTypes() async {
    await loadDeliveryTypes(forceRefresh: true);
  }

  static void debugDeliveryTypes() {
    if (!kDebugMode) {
      return;
    }

    debugPrint('Delivery types count: ${_deliveryTypes?.length ?? 0}');
  }

  static List<Map<String, dynamic>> _defaultDeliveryTypes() {
    return const [
      {
        'id': '1',
        'type_name_en': 'Instant',
        'type_name_ar': 'فوري',
        'description_en': 'Deliver immediately after creating the shipment.',
        'description_ar': 'يتم التسليم مباشرة بعد إنشاء الشحنة.',
      },
      {
        'id': '2',
        'type_name_en': 'Scheduled',
        'type_name_ar': 'مجدول',
        'description_en': 'Set a date and time for delivery.',
        'description_ar': 'حدد تاريخاً ووقتاً مناسباً للتسليم.',
      },
      {
        'id': '3',
        'type_name_en': 'Same-Day',
        'type_name_ar': 'نفس اليوم',
        'description_en': 'Delivery will be completed today.',
        'description_ar': 'سيتم تنفيذ التوصيل خلال نفس اليوم.',
      },
      {
        'id': '4',
        'type_name_en': 'Next-Day',
        'type_name_ar': 'اليوم التالي',
        'description_en': 'Delivery is scheduled for tomorrow.',
        'description_ar': 'سيتم تنفيذ التوصيل في اليوم التالي.',
      },
      {
        'id': '5',
        'type_name_en': 'Economy',
        'type_name_ar': 'اقتصادي',
        'description_en': 'A lower-cost option with flexible timing.',
        'description_ar': 'خيار أقل تكلفة بموعد تسليم مرن.',
      },
      {
        'id': '6',
        'type_name_en': 'Express',
        'type_name_ar': 'سريع',
        'description_en': 'Fast priority delivery for urgent shipments.',
        'description_ar': 'توصيل سريع بأولوية للشحنات المستعجلة.',
      },
      {
        'id': '7',
        'type_name_en': 'Contactless',
        'type_name_ar': 'بدون تلامس',
        'description_en': 'Contactless handoff for safer delivery.',
        'description_ar': 'تسليم بدون تلامس لراحة وأمان أكبر.',
      },
    ];
  }
}
