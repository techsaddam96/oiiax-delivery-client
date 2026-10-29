import 'package:blockatie/models/statistics.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/pages/wallet/wallet.dart';
import 'package:blockatie/views/widgets/client_welcome_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.changeLanguage(AppLocalizations.arabic);
  });
  tearDown(() => AppLocalizations.changeLanguage(AppLocalizations.english));

  testWidgets(
      'Arabic home and wallet show the same available amount, not shipment value',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stats = ClientStatisticsData.fromJson({
      'wallet_version': 1,
      'balance_total': '96.99 JOD',
      'final_total_value_order': '0.00 JOD',
      'total_required': '0.00 JOD',
      'withdrawable_balance': '0.00',
      'reserved_withdrawals': '0.00',
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClientWelcomeSummaryCard(profile: null, stats: stats),
              WalletBalanceCard(
                  statistics: stats, isLoading: false, copy: (en, ar) => ar),
            ],
          )),
    )));
    final home = find.byType(ClientWelcomeSummaryCard);
    expect(find.descendant(of: home, matching: find.text('0.00 JOD')),
        findsOneWidget);
    expect(find.descendant(of: home, matching: find.text('96.99 JOD')),
        findsNothing);
    expect(find.text('المتاح للسحب'), findsNWidgets(2));
    expect(find.text('رصيد الشحنات غير المستحق: 96.99 JOD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'home does not substitute shipment money when availability is unknown',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ClientWelcomeSummaryCard(
          profile: null,
          stats: ClientStatisticsData.fromJson({'balance_total': '96.99 JOD'})),
    )));
    expect(find.text('—'), findsOneWidget);
    expect(find.text('96.99 JOD'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
