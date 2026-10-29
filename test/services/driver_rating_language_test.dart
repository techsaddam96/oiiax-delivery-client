import 'dart:convert';
import 'dart:ui';

import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service_secure_storage_test.dart' show MemorySecureStore;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.changeLanguage(AppLocalizations.arabic);
    AuthService.configureForTesting(secureStore: MemorySecureStore());
    await AuthService.saveApiKey('rating-language-test-key', '1');
    RequestIdService.clearUserState();
  });
  tearDown(() {
    binding.platformDispatcher.clearLocaleTestValue();
    AuthService.resetForTesting();
  });

  Future<DriverRatingSubmissionResult> respond(Map<String, dynamic> payload,
      {void Function(http.Request)? inspect}) {
    return http.runWithClient(
      () => DriverRatingService.submitDriverRating(
          shipmentId: 41, rating: 5, comment: 'ممتاز'),
      () => MockClient((request) async {
        inspect?.call(request);
        return http.Response(jsonEncode(payload), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
  }

  for (final language in ['ar', 'en']) {
    test('app $language overrides device and generic response language',
        () async {
      await AppLocalizations.changeLanguage(Locale(language));
      binding.platformDispatcher.localeTestValue =
          Locale(language == 'ar' ? 'en' : 'ar');
      final result = await respond({
        'success': true,
        'message': language == 'ar' ? 'English generic' : 'رسالة عامة عربية',
        'message_ar': 'تم إرسال تقييم السائق بنجاح.',
        'message_en': 'Driver rating submitted successfully.',
      }, inspect: (request) {
        expect(request.headers['Accept-Language'], language);
      });
      expect(result.message, AppTranslations.getText('driver_rating_success'));
    });

    test('$language success fallback never uses opposite generic language',
        () async {
      await AppLocalizations.changeLanguage(Locale(language));
      final result = await respond({
        'success': true,
        'message': language == 'ar' ? 'English generic' : 'رسالة عامة عربية',
      });
      expect(result.message, AppTranslations.getText('driver_rating_success'));
    });

    test('$language network failure is localized', () async {
      await AppLocalizations.changeLanguage(Locale(language));
      final result = await http.runWithClient(
        () => DriverRatingService.submitDriverRating(shipmentId: 41, rating: 5),
        () => MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(result.success, isFalse);
      expect(result.message, AppTranslations.getText('driver_rating_failed'));
    });

    test('$language missing session is localized without an HTTP request',
        () async {
      await AppLocalizations.changeLanguage(Locale(language));
      AuthService.configureForTesting(secureStore: MemorySecureStore());
      SharedPreferences.setMockInitialValues({});
      final result = await http.runWithClient(
        () => DriverRatingService.submitDriverRating(shipmentId: 41, rating: 5),
        () => MockClient((_) async => throw StateError('Must not send')),
      );
      expect(result.code, 'API_KEY_MISSING');
      expect(result.message,
          AppTranslations.getText('driver_rating_session_expired'));
    });
  }

  test('Arabic error field takes priority over English generic error',
      () async {
    final result = await respond({
      'success': false,
      'message': 'You already rated this driver before.',
      'message_en': 'You already rated this driver before.',
      'message_ar': 'لقد قمت بتقييم هذا السائق مسبقاً',
      'code': 'DRIVER_ALREADY_RATED',
    });
    expect(result.message, 'لقد قمت بتقييم هذا السائق مسبقاً');
    expect(result.success, isFalse);
  });

  test('language change during request uses the current app language',
      () async {
    final result = await http.runWithClient(
      () => DriverRatingService.submitDriverRating(shipmentId: 41, rating: 5),
      () => MockClient((request) async {
        expect(request.headers['Accept-Language'], 'ar');
        await AppLocalizations.changeLanguage(AppLocalizations.english);
        return http.Response(
            jsonEncode({
              'success': true,
              'message': 'تم إرسال تقييم السائق بنجاح.',
              'message_ar': 'تم إرسال تقييم السائق بنجاح.',
              'message_en': 'Driver rating submitted successfully.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    expect(result.message, 'Driver rating submitted successfully.');
  });
}
