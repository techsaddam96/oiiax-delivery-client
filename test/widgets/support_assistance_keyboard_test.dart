import 'package:blockatie/provider/system_settings_provider.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _QuietSystemSettingsProvider extends SystemSettingsProvider {
  @override
  Future<bool> loadSystemSettings() async => false;
}

void main() {
  testWidgets(
      'does not add a second keyboard-height gap below the support form',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<SystemSettingsProvider>(
        create: (_) => _QuietSystemSettingsProvider(),
        child: const MaterialApp(home: SupportAssistancePage()),
      ),
    );
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pump();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect((scroll.padding! as EdgeInsets).bottom, 24);
    expect(tester.takeException(), isNull);
  });
}
