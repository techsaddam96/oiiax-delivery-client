import 'package:blockatie/provider/login.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/auth/login/login.dart';
import 'package:blockatie/views/pages/welcome/client_welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _host({required Locale locale, required VoidCallback onLogin}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: ClientWelcomePage(onLogin: onLogin),
  );
}

Widget _navigationHost() {
  return ChangeNotifierProvider(
    create: (_) => LoginProvider(),
    child: MaterialApp(
      navigatorKey: Nav.key,
      home: const ClientWelcomePage(),
    ),
  );
}

void main() {
  testWidgets('Arabic welcome stays visible until the user chooses Login', (
    tester,
  ) async {
    var loginRequests = 0;

    await tester.pumpWidget(
      _host(locale: const Locale('ar'), onLogin: () => loginRequests++),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ClientWelcomePage), findsOneWidget);
    expect(find.text('مرحباً بك في بلوكاتي'), findsOneWidget);
    expect(find.text('الدخول'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(ClientWelcomePage))),
      TextDirection.rtl,
    );
    expect(loginRequests, isZero);

    final background = tester.widget<Image>(
      find.byKey(const Key('client-welcome-background')),
    );
    expect(background.fit, BoxFit.cover);
    expect(background.alignment, Alignment.bottomCenter);
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/client_welcome_storefront.png',
    );
    final loginButton = tester.getRect(
      find.byKey(const Key('client-welcome-login')),
    );
    final screen = tester.getSize(find.byType(Scaffold));
    expect(loginButton.bottom, greaterThan(screen.height - 100));

    await tester.tap(find.text('الدخول'));
    expect(loginRequests, 1);
  });

  testWidgets('English welcome uses LTR copy and remains responsive', (
    tester,
  ) async {
    var loginRequests = 0;
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(locale: const Locale('en'), onLogin: () => loginRequests++),
    );

    expect(find.text('Welcome to Blockatie'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(ClientWelcomePage))),
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login opens the approved existing LoginPage', (tester) async {
    await tester.pumpWidget(_navigationHost());

    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
