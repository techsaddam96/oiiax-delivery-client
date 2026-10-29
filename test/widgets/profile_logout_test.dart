import 'dart:async';

import 'package:blockatie/models/client_profile.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/login.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/services/auth_api_service.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/welcome/client_welcome_page.dart';
import 'package:blockatie/views/pages/hub/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service_secure_storage_test.dart'
    show MemorySecureStore;

class DelayedLogoutStore extends MemorySecureStore {
  final deleting = Completer<void>();
  final allowDelete = Completer<void>();

  @override
  Future<void> delete(String key) async {
    if (key == 'client_api_key') {
      deleting.complete();
      await allowDelete.future;
    }
    await super.delete(key);
  }
}

class LoadedProfile extends ProfileProvider {
  @override
  Future<ClientInfo?> fetchClientProfile({bool silent = false}) async =>
      profileInfo;

  @override
  Future<void> fetchClientStatistics() async {}
}

void main() {
  for (final overlay in [false, true]) {
    testWidgets(
        'profile logout clears state and finishes navigation '
        '${overlay ? 'after overlay disposal' : 'from a route'}',
        (tester) async {
      SharedPreferences.setMockInitialValues({'language': 'en'});
      late DelayedLogoutStore secure;
      late Completer<void> revocation;
      var revoked = 0;
      await tester.runAsync(() async {
        secure = DelayedLogoutStore();
        revocation = Completer<void>();
        AuthService.configureForTesting(
          secureStore: secure,
          sessionLogout: ({
            required clientId,
            required apiKey,
            required rememberToken,
            required deviceId,
          }) async {
            revoked++;
            revocation.complete();
            return const AuthApiResult(
                success: true, code: 'OK', message: 'OK');
          },
        );
        await AppLocalizations.changeLanguage(AppLocalizations.english);
        await AuthService.saveApiKey('test-only-key', '1');
      });
      final profile = LoadedProfile()
        ..profileInfo = ClientInfo.fromJson({
          'id': 1,
          'nclient': 'Test owner',
          'nstore': 'Account A only',
          'phclient': 'test-only',
          'lclient': 'Test address',
        });
      final nav = BottomNavProvider()..showOverlay(const ProfilePage());
      final login = LoginProvider();
      addTearDown(() {
        profile.dispose();
        nav.dispose();
        login.dispose();
        AuthService.resetForTesting();
      });
      await tester.binding.setSurfaceSize(const Size(420, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: profile),
          ChangeNotifierProvider<BottomNavProvider>.value(value: nav),
          ChangeNotifierProvider<LoginProvider>.value(value: login),
        ],
        child: MaterialApp(
          navigatorKey: Nav.key,
          home: overlay
              ? Consumer<BottomNavProvider>(
                  builder: (_, value, __) =>
                      value.overlayPage ??
                      const Scaffold(body: Text('Clean root')))
              : const ProfilePage(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Account A only'), findsOneWidget);
      await tester.ensureVisible(find.text('Logout'));
      await tester.runAsync(() => tester.tap(find.text('Logout')));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => tester.tap(find.widgetWithText(FilledButton, 'Logout')));
      await tester.pump();
      // No Firebase app is initialized: logout must not depend on messaging.
      await tester.runAsync(
          () => secure.deleting.future.timeout(const Duration(seconds: 3)));
      expect(AuthService.currentSession?.isValid, isFalse);
      expect(profile.profileInfo, isNull);
      expect(nav.overlayPage, isNull);
      await tester.pump();
      expect(find.text('Account A only'), findsNothing);
      if (overlay) expect(find.byType(ProfilePage), findsNothing);
      await tester.runAsync(() async {
        secure.allowDelete.complete();
        await revocation.future.timeout(const Duration(seconds: 3));
      });
      await tester.pumpAndSettle();
      expect(find.byType(ClientWelcomePage), findsOneWidget);
      expect(secure.values.containsKey('client_api_key'), isFalse);
      expect(revoked, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
