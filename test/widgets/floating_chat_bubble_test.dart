// The floating chat launcher.
//
// What these start from: the launcher was positioned with a hardcoded `left`,
// so it sat on the leading edge in English and disagreed with the Driver app's
// trailing-edge launcher; and it drifted up and down on a repeating animation,
// which rebuilt it every frame for the life of the app.

import 'dart:async';

import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/chat_launcher_navigation_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/widgets/floating_chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../services/auth_service_secure_storage_test.dart'
    show MemorySecureStore;

class _Repository extends Fake implements ChatRepository {}

/// Reports whatever unread count a test asks for, without a transport.
class _Conversations extends ChatConversationsProvider {
  _Conversations() : super(repository: _Repository());

  int fakeUnread = 0;

  @override
  int get unreadCount => fakeUnread;

  void setUnread(int value) {
    fakeUnread = value;
    notifyListeners();
  }

  @override
  Future<void> refreshUnreadCount() async {}
}

final _bubble = find.byIcon(Icons.chat_bubble_rounded);

Widget _app({
  required ChatLauncherProvider launcher,
  required _Conversations conversations,
  Locale locale = const Locale('en'),
  Widget? body,
  List<NavigatorObserver> navigatorObservers = const [],
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ChatLauncherProvider>.value(value: launcher),
      ChangeNotifierProvider<ChatConversationsProvider>.value(
        value: conversations,
      ),
    ],
    child: MaterialApp(
      navigatorKey: Nav.key,
      navigatorObservers: navigatorObservers,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const FloatingChatBubble(),
        ],
      ),
      home: body ??
          Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: Container(
              key: const Key('bottom-nav-stub'),
              height: 96,
              color: Colors.white,
            ),
          ),
    ),
  );
}

/// A launcher provider in the signed-in, shell-visible state.
ChatLauncherProvider _signedIn() {
  final launcher = ChatLauncherProvider();
  launcher.setAuthenticatedShellVisible(true);
  return launcher;
}

Future<void> _setSize(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double bottomPad = 0,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = FakeViewPadding(bottom: bottomPad * 3);
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatLauncherProvider launcher;
  late _Conversations conversations;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AuthService.configureForTesting(secureStore: MemorySecureStore());
    await AuthService.saveApiKey('bubble-test-token', '1');
    launcher = _signedIn();
    conversations = _Conversations();
  });

  tearDown(() {
    launcher.dispose();
    conversations.dispose();
    AuthService.resetForTesting();
  });

  /// Marks the session valid, which is what flips `isAuthenticated`.
  Future<void> signIn(WidgetTester tester) async {
    await launcher.syncSession();
    await tester.pump();
  }

  // ---------------------------------------------------------------------------
  group('visibility', () {
    testWidgets('1. shows once the shell is up and a session exists', (
      tester,
    ) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);

      expect(_bubble, findsOneWidget);
    });

    testWidgets('2. stays hidden without a session', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await tester.pump();

      expect(_bubble, findsNothing);
    });

    testWidgets('11. a session reset removes it', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      expect(_bubble, findsOneWidget);

      // The session boundary itself, with no network call: clearSession()
      // also revokes the device token, which never returns in a test.
      UserSessionState.reset(SessionResetReason.logout);
      await tester.pump();

      expect(_bubble, findsNothing);
    });

    testWidgets('9. a chat route on top hides it', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      expect(_bubble, findsOneWidget);

      launcher.setChatRouteOpen(true);
      await tester.pump();

      expect(_bubble, findsNothing);
    });

    testWidgets('10. an open keyboard hides it', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      expect(_bubble, findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await tester.pump();

      expect(_bubble, findsNothing);
    });

    testWidgets('hides for dialogs and modal sheets, then returns',
        (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(
          launcher: launcher,
          conversations: conversations,
          navigatorObservers: [ChatLauncherNavigationObserver(launcher)],
        ),
      );
      await signIn(tester);
      expect(_bubble, findsOneWidget);

      unawaited(
        showDialog<void>(
          context: Nav.key.currentContext!,
          builder: (_) => const AlertDialog(title: Text('Active dialog')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active dialog'), findsOneWidget);
      expect(_bubble, findsNothing);

      Navigator.of(Nav.key.currentContext!).pop();
      await tester.pumpAndSettle();

      expect(_bubble, findsOneWidget);

      unawaited(
        showModalBottomSheet<void>(
          context: Nav.key.currentContext!,
          builder: (_) => const SizedBox(height: 160, child: Text('Sheet')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sheet'), findsOneWidget);
      expect(_bubble, findsNothing);

      Navigator.of(Nav.key.currentContext!).pop();
      await tester.pumpAndSettle();

      expect(_bubble, findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  group('badge', () {
    Future<void> pumpWithUnread(WidgetTester tester, int count) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      conversations.setUnread(count);
      await tester.pumpAndSettle();
    }

    testWidgets('3. zero shows no badge', (tester) async {
      await pumpWithUnread(tester, 0);
      expect(_bubble, findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('4. one shows an exact count', (tester) async {
      await pumpWithUnread(tester, 1);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('5. ninety-nine shows an exact count', (tester) async {
      await pumpWithUnread(tester, 99);
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('6. one hundred collapses to 99+', (tester) async {
      await pumpWithUnread(tester, 100);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('100'), findsNothing);
    });

    testWidgets('7. the badge sits on the trailing corner in both directions', (
      tester,
    ) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      conversations.setUnread(3);
      await tester.pumpAndSettle();

      final ltrBadge = tester.getCenter(find.text('3')).dx;
      final ltrBubble = tester.getCenter(_bubble).dx;
      expect(ltrBadge, greaterThan(ltrBubble));

      await tester.pumpWidget(
        _app(
          launcher: launcher,
          conversations: conversations,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      final rtlBadge = tester.getCenter(find.text('3')).dx;
      final rtlBubble = tester.getCenter(_bubble).dx;
      expect(rtlBadge, lessThan(rtlBubble));
    });

    testWidgets('the digits stay left-to-right in Arabic', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(
          launcher: launcher,
          conversations: conversations,
          locale: const Locale('ar'),
        ),
      );
      await signIn(tester);
      conversations.setUnread(100);
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('99+'));
      expect(text.textDirection, TextDirection.ltr);
    });

    testWidgets('the badge settles at its natural size after a rise', (
      tester,
    ) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      conversations.setUnread(1);
      await tester.pumpAndSettle();
      final resting = tester.getSize(find.text('1'));

      conversations.setUnread(2);
      await tester.pumpAndSettle();

      // The pop is one-shot: it must not leave the badge scaled.
      expect(tester.getSize(find.text('2')).height, closeTo(resting.height, 1));
    });
  });

  // ---------------------------------------------------------------------------
  group('behaviour', () {
    testWidgets('12. the label names the action and the unread count', (
      tester,
    ) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Open messages'), findsOneWidget);

      conversations.setUnread(3);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Open messages, 3 unread messages'),
        findsOneWidget,
      );
    });

    testWidgets('the Arabic label reads in Arabic', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(
          launcher: launcher,
          conversations: conversations,
          locale: const Locale('ar'),
        ),
      );
      await signIn(tester);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('فتح الرسائل'), findsOneWidget);
    });

    testWidgets('13. a press does not swallow the tap', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      await tester.pumpAndSettle();

      // The press animation is decoration; the gesture still has to arrive.
      final gesture = await tester.startGesture(tester.getCenter(_bubble));
      await tester.pump(const Duration(milliseconds: 60));
      await gesture.up();
      await tester.pump();

      expect(launcher.shouldShow, isFalse, reason: 'a chat route was opened');
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing animates on a loop', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      conversations.setUnread(2);

      // A repeating animation never lets the tree settle; this used to time out.
      await tester.pumpAndSettle();
      expect(_bubble, findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  group('geometry', () {
    testWidgets('15. clears the bottom navigation', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      await tester.pumpAndSettle();

      final bubbleRect = tester.getRect(_bubble);
      final navRect = tester.getRect(find.byKey(const Key('bottom-nav-stub')));
      expect(bubbleRect.bottom, lessThanOrEqualTo(navRect.top));
    });

    testWidgets('respects the bottom safe area', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      await tester.pumpAndSettle();
      final withoutInset = tester.getRect(_bubble).bottom;

      await _setSize(tester, bottomPad: 34);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await tester.pumpAndSettle();

      expect(withoutInset - tester.getRect(_bubble).bottom, closeTo(34, 1));
    });

    testWidgets('sits on the trailing edge in both directions', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(MaterialApp)).width;
      expect(tester.getCenter(_bubble).dx, greaterThan(width / 2));

      await tester.pumpWidget(
        _app(
          launcher: launcher,
          conversations: conversations,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getCenter(_bubble).dx, lessThan(width / 2));
    });

    testWidgets('the tap target is at least 48px', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);
      await tester.pumpAndSettle();

      final size = tester.getSize(
        find.ancestor(of: _bubble, matching: find.byType(InkWell)).first,
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('renders one rounded-square surface without a halo', (
      tester,
    ) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _app(launcher: launcher, conversations: conversations),
      );
      await signIn(tester);

      final surface = find.byKey(
        const ValueKey<String>('client-chat-launcher-surface'),
      );
      expect(surface, findsOneWidget);
      expect(_bubble, findsOneWidget);

      final decoration =
          tester.widget<Ink>(surface).decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.rectangle);
      expect(decoration.borderRadius, isA<BorderRadius>());
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.color, const Color(0x260F172A));
    });

    for (final size in const [
      Size(320, 568),
      Size(360, 800),
      Size(390, 844),
      Size(430, 932),
      Size(768, 1024),
      Size(1024, 768),
    ]) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        testWidgets(
          '14. fits ${size.width.toInt()}x${size.height.toInt()} in '
          '${locale.languageCode}',
          (tester) async {
            await _setSize(tester, size: size);
            await tester.pumpWidget(
              _app(
                launcher: launcher,
                conversations: conversations,
                locale: locale,
              ),
            );
            await signIn(tester);
            conversations.setUnread(100);
            await tester.pumpAndSettle();

            expect(_bubble, findsOneWidget);
            expect(tester.takeException(), isNull);

            final rect = tester.getRect(_bubble);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
          },
        );
      }
    }
  });
}
