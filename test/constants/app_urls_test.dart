import 'package:blockatie/constants/app_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUrls QA configuration', () {
    test('production default remains pinned to the hosted HTTPS API', () {
      expect(
        AppUrls.resolveBaseUrlForTesting(
          isReleaseBuild: false,
          qaBaseUrl: '',
        ),
        AppUrls.productionBaseUrl,
      );
    });

    test('debug accepts the explicit local emulator services URL', () {
      expect(
        AppUrls.resolveBaseUrlForTesting(
          isReleaseBuild: false,
          qaBaseUrl: 'http://10.0.2.2:8080/services/',
        ),
        'http://10.0.2.2:8080/services',
      );
    });

    test('debug rejects cleartext URLs outside the local QA boundary', () {
      expect(
        () => AppUrls.resolveBaseUrlForTesting(
          isReleaseBuild: false,
          qaBaseUrl: 'http://example.test/services',
        ),
        throwsArgumentError,
      );
    });

    test('release rejects any QA API override instead of silently using it',
        () {
      expect(
        () => AppUrls.resolveBaseUrlForTesting(
          isReleaseBuild: true,
          qaBaseUrl: 'http://10.0.2.2:8080/services',
        ),
        throwsStateError,
      );
    });

    test('Warehouse E2E identity requires both the local URL and explicit name',
        () {
      expect(
        AppUrls.isExplicitLocalWarehouseE2eForTesting(
          baseUrl: 'http://10.0.2.2:8080/services',
          environment: AppUrls.localWarehouseE2eEnvironment,
        ),
        isTrue,
      );
      expect(
        AppUrls.isExplicitLocalWarehouseE2eForTesting(
          baseUrl: AppUrls.productionBaseUrl,
          environment: AppUrls.localWarehouseE2eEnvironment,
        ),
        isFalse,
      );
      expect(
        AppUrls.isExplicitLocalWarehouseE2eForTesting(
          baseUrl: 'http://10.0.2.2:8080/services',
          environment: 'debug',
        ),
        isFalse,
      );
    });
  });
}
