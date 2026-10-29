import 'dart:convert';

import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service_secure_storage_test.dart'
    show MemorySecureStore;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthService.configureForTesting(secureStore: MemorySecureStore());
    await AuthService.saveApiKey('rating-dialog-test-key', '1');
  });
  tearDown(AuthService.resetForTesting);

  for (final locale in [AppLocalizations.arabic, AppLocalizations.english]) {
    testWidgets('success dialog uses ${locale.languageCode} for all text',
        (tester) async {
      await AppLocalizations.changeLanguage(locale);
      final result = await http.runWithClient(
        () => DriverRatingService.submitDriverRating(shipmentId: 41, rating: 5),
        () => MockClient((_) async => http.Response(
              jsonEncode({
                'success': true,
                'message': 'Driver rating submitted successfully.',
                'message_ar': 'تم إرسال تقييم السائق بنجاح.',
                'message_en': 'Driver rating submitted successfully.',
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      await tester.pumpWidget(MaterialApp(
        navigatorKey: Nav.key,
        builder: (_, child) => Directionality(
            textDirection: AppLocalizations.textDirection, child: child!),
        home: Scaffold(
          body: TextButton(
            onPressed: () => AppUtils.showSuccessDialog(result.message),
            child: const Text('Show result'),
          ),
        ),
      ));
      await tester.tap(find.text('Show result'));
      await tester.pumpAndSettle();
      expect(find.text(AppTranslations.getText('driver_rating_success')),
          findsOneWidget);
      expect(find.text(AppTranslations.getText('success')), findsOneWidget);
      expect(find.text(AppTranslations.getText('ok')), findsOneWidget);
      expect(
          find.text(AppTranslations.getTextWithLocale('driver_rating_success',
              locale.languageCode == 'ar' ? 'en' : 'ar')),
          findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
