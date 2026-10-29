import 'package:blockatie/models/balance_history.dart';
import 'package:blockatie/provider/balance_history.dart';
import 'package:blockatie/services/shipment_services.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renders UTC instants in the fixed Jordan business timezone', () {
    final standard = JordanTime.parse('2026-10-28T09:00:00Z');
    final boundary = JordanTime.parse('2026-10-28T23:45:00Z');

    expect(standard?.toString(), '2026-10-28 12:00:00.000+0300');
    expect(boundary?.toString(), '2026-10-29 02:45:00.000+0300');
  });

  test('keeps legacy offset-less DATETIME values as Amman wall-clock time', () {
    final value = JordanTime.parse('2026-10-28 12:00:00');

    expect(value?.year, 2026);
    expect(value?.month, 10);
    expect(value?.day, 28);
    expect(value?.hour, 12);
    expect(value?.timeZoneOffset, const Duration(hours: 3));
  });

  test('serializes selected shipment schedules as Amman wall-clock fields', () {
    expect(
      ShipmentService.formatJordanWallClockForApi(
        DateTime.parse('2026-10-28T09:00:00Z'),
      ),
      '2026-10-28 12:00:00',
    );
    expect(
      ShipmentService.formatJordanWallClockForApi(
        DateTime.parse('2026-10-31T22:30:00Z'),
      ),
      '2026-11-01 01:30:00',
    );
  });

  test('uses the Jordan calendar for explicit UTC and legacy balance rows', () {
    final provider = BalanceHistoryProvider()
      ..balanceHistoryResponse = BalanceHistoryResponse(
        status: 'success',
        message: '',
        totalCount: 2,
        transactions: [
          _transaction(1, '2026-10-31T22:30:00Z'),
          _transaction(2, '2026-10-31 23:45:00'),
        ],
      );

    expect(
      provider.getTransactionsByMonth(2026, 11).map((item) => item.id),
      [1],
    );
    expect(
      provider.getTransactionsByMonth(2026, 10).map((item) => item.id),
      [2],
    );
  });
}

BalanceTransaction _transaction(int id, String createdAt) => BalanceTransaction(
      id: id,
      type: 'credit',
      amount: '1.00',
      description: '',
      method: 'cash',
      status: 'completed',
      createdAt: createdAt,
    );
