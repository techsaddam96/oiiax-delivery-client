import 'dart:convert';

import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service_secure_storage_test.dart' show MemorySecureStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.changeLanguage(AppLocalizations.arabic);
    AuthService.configureForTesting(secureStore: MemorySecureStore());
    await AuthService.saveApiKey('bug05-synthetic-key', '1');
    RequestIdService.clearUserState();
  });
  tearDown(AuthService.resetForTesting);

  for (final comment in [
    'التوصيل ممتاز والسائق ملتزم',
    'ممتاز Excellent 123!\nشكراً 👏🏽',
    '',
  ]) {
    test('UTF-8 form request preserves comment: $comment', () async {
      final result = await http.runWithClient(
        () => DriverRatingService.submitDriverRating(
            shipmentId: 41, rating: 5, comment: comment),
        () => MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['X-API-KEY'], 'bug05-synthetic-key');
          final fields = Uri.splitQueryString(utf8.decode(request.bodyBytes));
          expect(fields, {
            'shipment_id': '41',
            'rating': '5',
            'comment': comment,
          });
          return http.Response(
              jsonEncode({
                'success': true,
                'message': 'تم إرسال تقييم السائق بنجاح.',
                'code': 'DRIVER_REVIEW_CREATED',
                'comment': comment,
                'rating': 5,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }),
      );
      expect(result.success, isTrue);
      expect(result.message, 'تم إرسال تقييم السائق بنجاح.');
    });
  }

  for (final code in ['SHIPMENT_FORBIDDEN', 'DRIVER_ALREADY_RATED']) {
    test('$code stays a failure with Arabic response', () async {
      final result = await http.runWithClient(
        () => DriverRatingService.submitDriverRating(
            shipmentId: 41, rating: 5, comment: 'ممتاز'),
        () => MockClient((_) async => http.Response(
              jsonEncode({
                'success': false,
                'code': code,
                'message': 'غير مسموح بإرسال هذا التقييم',
              }),
              code == 'SHIPMENT_FORBIDDEN' ? 403 : 409,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      expect(result.success, isFalse);
      expect(result.code, code);
      expect(result.message, 'غير مسموح بإرسال هذا التقييم');
    });
  }
}
