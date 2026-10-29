import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StatusService {
  static Map<String, dynamic>? _statusConfig;
  static bool _isLoading = false;

  static Map<String, dynamic>? get statusConfig => _statusConfig;
  static bool get isLoading => _isLoading;

  static Future<void> loadStatusConfig() async {
    if (_statusConfig != null || _isLoading) return;

    _isLoading = true;

    try {
      final dio = Dio();
      final apiKey = await AuthService.getApiKey();

      if (apiKey == null || apiKey.trim().isEmpty) {
        _statusConfig = _getDefaultStatusConfig();
        return;
      }

      final response = await dio.get(
        AppUrls.getStatusConfig,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-API-KEY': apiKey,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _statusConfig = response.data;
      } else {
        throw Exception('Failed to load status configuration');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Status config load failed, using fallback');
      }
      _statusConfig = _getDefaultStatusConfig();
    } finally {
      _isLoading = false;
    }
  }

  static Map<String, dynamic>? getStatusByName(String statusName) {
    if (_statusConfig == null) return null;

    final statuses = _statusConfig!['status'] as List<Map<String, dynamic>>;
    try {
      for (final status in statuses) {
        if (status['status_name_en'].toString().toLowerCase() ==
            statusName.toLowerCase()) {
          return status;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Color getStatusColor(String statusName) {
    final status = getStatusByName(statusName);
    if (status == null) return Colors.grey;

    switch (status['type_color']) {
      case 'success':
        return Colors.green;
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  static String getStatusIcon(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return 'assets/images/delivered.png';
      case 'cancelled':
      case 'returned':
        return 'assets/images/cancelled.png';
      case 'failed delivery':
        return 'assets/images/failed_del.png';
      case 'in transit':
        return 'assets/images/inprogress.png';
      case 'out for delivery':
        return 'assets/images/delivery_partner.png';
      case 'awaiting pickup':
        return 'assets/images/pending.png';
      case 'processing':
        return 'assets/images/order_accep.png';
      case 'dispatched':
        return 'assets/images/delivery_partner.png';
      case 'pending':
      default:
        return 'assets/images/pending.png';
    }
  }

  static String getStatusMessage(String statusName) {
    final status = getStatusByName(statusName);
    return status?['message_en'] ?? 'Status updated';
  }

  static int getStatusOrder(String statusName) {
    final status = getStatusByName(statusName);
    return int.parse((status?['status_order'] ?? 0).toString());
  }

  static List<Map<String, dynamic>> getAllStatuses() {
    if (_statusConfig == null) return [];
    return List<Map<String, dynamic>>.from(_statusConfig!['status']);
  }

  static double getStatusProgress(String statusName) {
    final status = getStatusByName(statusName);
    if (status == null) return 0.0;

    final order = int.parse((status['status_order'] ?? 0).toString());
    return order / 100.0;
  }

  static Map<String, dynamic> _getDefaultStatusConfig() {
    return {
      'success': true,
      'count': 11,
      'status': [
        {
          'id': '1',
          'status_name_en': 'Pending',
          'status_name_ar': 'قيد الانتظار',
          'status_order': '5',
          'type_color': 'info',
          'message_en': 'Order has been created but not yet processed',
          'message_ar': 'تم إنشاء الشحنة ولكنها لم تعالج بعد',
        },
        {
          'id': '2',
          'status_name_en': 'Processing',
          'status_name_ar': 'قيد التجهيز',
          'status_order': '10',
          'type_color': 'info',
          'message_en': 'Order is currently being prepared',
          'message_ar': 'الشحنة قيد التجهيز حالياً',
        },
        {
          'id': '3',
          'status_name_en': 'Dispatched',
          'status_name_ar': 'تم الشحن',
          'status_order': '20',
          'type_color': 'info',
          'message_en': 'Order has been dispatched from the warehouse',
          'message_ar': 'تم شحن الشحنة من المستودع',
        },
        {
          'id': '4',
          'status_name_en': 'In Transit',
          'status_name_ar': 'في الطريق',
          'status_order': '30',
          'type_color': 'warning',
          'message_en': 'Order is on the way to the destination',
          'message_ar': 'الشحنة في الطريق إلى الوجهة',
        },
        {
          'id': '5',
          'status_name_en': 'Out for Delivery',
          'status_name_ar': 'في انتظار التسليم',
          'status_order': '40',
          'type_color': 'warning',
          'message_en': 'Order is out for final delivery to the customer',
          'message_ar': 'الشحنة في انتظار التسليم النهائي للعميل',
        },
        {
          'id': '6',
          'status_name_en': 'Delivered',
          'status_name_ar': 'تم التسليم',
          'status_order': '100',
          'type_color': 'success',
          'message_en': 'Order has been delivered to the customer',
          'message_ar': 'تم تسليم الشحنة للعميل',
        },
        {
          'id': '7',
          'status_name_en': 'Cancelled',
          'status_name_ar': 'تم الإلغاء',
          'status_order': '100',
          'type_color': 'danger',
          'message_en': 'Order has been cancelled by the customer or system',
          'message_ar': 'تم إلغاء الشحنة من قبل العميل أو النظام',
        },
        {
          'id': '8',
          'status_name_en': 'Returned',
          'status_name_ar': 'تم الإرجاع',
          'status_order': '100',
          'type_color': 'danger',
          'message_en': 'Order has been returned by the customer',
          'message_ar': 'تم إرجاع الشحنة من قبل العميل',
        },
        {
          'id': '9',
          'status_name_en': 'Failed Delivery',
          'status_name_ar': 'فشل في التسليم',
          'status_order': '5',
          'type_color': 'danger',
          'message_en': 'Delivery attempt failed and will be rescheduled',
          'message_ar': 'فشلت محاولة التسليم وسيتم إعادة جدولتها أو إلغاؤها',
        },
        {
          'id': '10',
          'status_name_en': 'Awaiting Pickup',
          'status_name_ar': 'في انتظار الاستلام',
          'status_order': '90',
          'type_color': 'warning',
          'message_en': 'Order is available for pickup by the customer',
          'message_ar': 'الشحنة متاحة للاستلام من قبل العميل',
        },
        {
          'id': '11',
          'status_name_en': 'Completed',
          'status_name_ar': 'مكتمل',
          'status_order': '100',
          'type_color': 'success',
          'message_en': 'Order is completed and closed in the system',
          'message_ar': 'الشحنة مكتملة ومغلقة في النظام',
        },
      ],
    };
  }

  static void clearCache() {
    _statusConfig = null;
  }

  static Future<void> reloadStatusConfig() async {
    _statusConfig = null;
    await loadStatusConfig();
  }
}
