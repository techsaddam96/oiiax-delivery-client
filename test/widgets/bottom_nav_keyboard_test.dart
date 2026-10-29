import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/requests_provider.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/views/pages/hub/hub.dart';
import 'package:blockatie/views/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _QuietChatRepository extends Fake implements ChatRepository {}

Widget _shell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BottomNavProvider()..setIndex(4)),
      ChangeNotifierProvider(create: (_) => ChatLauncherProvider()),
      ChangeNotifierProvider(create: (_) => HomeProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => RequestsProvider()),
      ChangeNotifierProvider(create: (_) => ShipmentProvider()),
      ChangeNotifierProvider(
        create: (_) => ChatConversationsProvider(
          repository: _QuietChatRepository(),
        ),
      ),
    ],
    child: const MaterialApp(
      home: CustomBottomNavBar(initialIndex: 4),
    ),
  );
}

Scaffold _shellScaffold(WidgetTester tester) =>
    tester.widget<Scaffold>(find.byType(Scaffold).first);

void main() {
  testWidgets('removes the shell navigation padding while the IME is open',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_shell());
    await tester.pump();

    expect(_shellScaffold(tester).extendBody, isTrue);
    expect(_shellScaffold(tester).bottomNavigationBar, isNotNull);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    // Android removes the navigation-bar padding while the keyboard owns it.
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pump();

    expect(_shellScaffold(tester).extendBody, isFalse);
    expect(_shellScaffold(tester).bottomNavigationBar, isNull);
    expect(
      MediaQuery.paddingOf(tester.element(find.byType(HubPage))).bottom,
      0,
      reason: 'the child must not retain the floating navigation bar height',
    );

    tester.view.viewInsets = FakeViewPadding.zero;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    await tester.pump();

    expect(_shellScaffold(tester).extendBody, isTrue);
    expect(_shellScaffold(tester).bottomNavigationBar, isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
