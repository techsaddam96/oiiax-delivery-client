import 'package:blockatie/models/statistics.dart';
import 'package:blockatie/views/pages/wallet/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Arabic wallet distinguishes available, owed, and reserved on a narrow screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(277, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stats = ClientStatisticsData.fromJson({
      'wallet_version': 1,
      'balance_total': '91.00 JOD',
      'final_total_value_order': '9.00 JOD',
      'total_required': '7.01 JOD',
      'withdrawable_balance': '1.99',
      'reserved_withdrawals': '0.00',
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: WalletBalanceCard(
              statistics: stats, isLoading: false, copy: (en, ar) => ar),
        ),
      ),
    )));
    expect(find.text('المتاح للسحب'), findsOneWidget);
    expect(find.text('1.99 JOD'), findsOneWidget);
    expect(find.text('7.01 JOD'), findsOneWidget);
    expect(find.text('محجوز للسحب: 0.00 JOD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review-required wallet does not present a spendable amount',
      (tester) async {
    final stats = ClientStatisticsData.fromJson({
      'wallet_version': 1,
      'withdrawable_balance': '1.99',
      'wallet_review_required': true,
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: WalletBalanceCard(
          statistics: stats, isLoading: false, copy: (en, ar) => ar),
    )));
    expect(find.text('1.99 JOD'), findsNothing);
    expect(
        find.text('تحتاج المحفظة مراجعة محاسبية قبل السحب.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
