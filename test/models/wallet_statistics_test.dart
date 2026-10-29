import 'package:blockatie/models/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wallet uses explicit net available balance, not expected shipments',
      () {
    final stats = ClientStatisticsData.fromJson({
      'wallet_version': 1,
      'balance_total': '91.00 JOD',
      'final_total_value_order': '9.00 JOD',
      'total_required': '7.01 JOD',
      'withdrawable_balance': '1.99',
      'reserved_withdrawals': '0.00',
    });
    expect(stats.availableForWithdrawal, 1.99);
    expect(stats.totalRequired, '7.01 JOD');
    expect(ClientStatisticsData.fromJson(stats.toJson()).availableForWithdrawal,
        1.99);
  });

  test('legacy API response cannot authorize withdrawal using a fallback', () {
    final stats = ClientStatisticsData.fromJson({
      'balance_total': '98.00 JOD',
      'final_total_value_order': '10.00 JOD',
    });
    expect(stats.availableForWithdrawal, isNull);
  });

  test('review, malformed, infinite, and negative balances fail closed', () {
    for (final value in ['NaN', 'Infinity', '-1.00', 'JOD 9.00', '']) {
      expect(
          ClientStatisticsData.fromJson({
            'wallet_version': 1,
            'withdrawable_balance': value,
          }).availableForWithdrawal,
          isNull);
    }
    expect(
        ClientStatisticsData.fromJson({
          'wallet_version': 1,
          'withdrawable_balance': '1.99',
          'wallet_review_required': true,
        }).availableForWithdrawal,
        isNull);
  });

  test('zero is a valid available balance', () {
    expect(
        ClientStatisticsData.fromJson({
          'wallet_version': 1,
          'withdrawable_balance': '0.00',
        }).availableForWithdrawal,
        0);
  });
}
