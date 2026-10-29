import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/shipment_action_reason.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';

class ShipmentActionReasonService {
  ShipmentActionReasonService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<ShipmentActionReason>> fetchReasons({
    required String actionType,
    String actorScope = 'client',
  }) async {
    final clientId = await AuthService.getUserId();
    final apiKey = await AuthService.getApiKey();

    if (clientId == null || clientId.trim().isEmpty || apiKey == null || apiKey.trim().isEmpty) {
      throw const ShipmentActionReasonException('UNAUTHORIZED');
    }

    final response = await _dio.post(
      AppUrls.shipmentActionReasons,
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-API-KEY': apiKey,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
      data: <String, dynamic>{
        'action_type': actionType,
        'actor_scope': actorScope,
        'client_id': clientId,
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ShipmentActionReasonException('UNAUTHORIZED');
    }
    if (response.data is! Map) {
      throw const ShipmentActionReasonException('INVALID_RESPONSE');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    if ((data['status']?.toString().toLowerCase() ?? '') != 'success') {
      throw ShipmentActionReasonException(
        data['code']?.toString() ?? 'REASONS_LOAD_FAILED',
      );
    }

    final raw = data['data'];
    if (raw is! List) {
      return const <ShipmentActionReason>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => ShipmentActionReason.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((reason) => reason.id > 0)
        .toList(growable: false);
  }
}

class ShipmentActionReasonException implements Exception {
  const ShipmentActionReasonException(this.code);

  final String code;
}
