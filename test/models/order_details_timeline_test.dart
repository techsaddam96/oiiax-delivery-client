import 'package:blockatie/models/order_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> responseData({
    int currentStatusId = 6,
    bool? canRateDriver,
    bool timelineAvailable = true,
    List<Map<String, dynamic>>? timeline,
  }) {
    return {
      'orderId': 41,
      'currentStatus': 'Delivered',
      'currentStatusId': currentStatusId,
      'currentStatusNameAr': 'تم التسليم',
      'currentStatusMessageEn': 'Delivered',
      'currentStatusMessageAr': 'تم التسليم',
      'currentStatusTypeColor': 'success',
      'timelineAvailable': timelineAvailable,
      'statusTimeline': timeline ?? const [],
      'details': <String, dynamic>{},
      'store': <String, dynamic>{},
      'driver': {'id': 9},
      if (canRateDriver != null) 'can_rate_driver': canRateDriver,
    };
  }

  test('parses actual status-history timeline and the explicit current status',
      () {
    final data = OrderDetailsData.fromJson(
      responseData(timeline: [
        {
          'statusId': 1,
          'nameEn': 'Pending',
          'nameAr': 'قيد الانتظار',
          'messageEn': 'Created',
          'messageAr': 'تم الإنشاء',
          'typeColor': 'warning',
          'timestamp': '2026-08-04 09:00:00',
        },
        {
          'statusId': 6,
          'nameEn': 'Delivered',
          'nameAr': 'تم التسليم',
          'messageEn': 'Delivered',
          'messageAr': 'تم التسليم',
          'typeColor': 'success',
          'timestamp': '2026-08-04 10:00:00',
        },
      ]),
    );

    expect(data.currentStatusId, 6);
    expect(data.statusTimeline, hasLength(2));
    expect(data.statusTimeline.last.statusId, 6);
    expect(data.timelineAvailable, isTrue);
  });

  test('does not invent a timeline when history is unavailable', () {
    final data = OrderDetailsData.fromJson(
      responseData(timelineAvailable: false),
    );

    expect(data.statusTimeline, isEmpty);
    expect(data.timelineAvailable, isFalse);
  });

  test('only enables rating by fallback for final delivered statuses', () {
    final delivered =
        OrderDetailsData.fromJson(responseData(currentStatusId: 6));
    final completed =
        OrderDetailsData.fromJson(responseData(currentStatusId: 11));
    final returned =
        OrderDetailsData.fromJson(responseData(currentStatusId: 8));

    expect(delivered.canRateDriver, isTrue);
    expect(completed.canRateDriver, isTrue);
    expect(returned.canRateDriver, isFalse);
  });
}
