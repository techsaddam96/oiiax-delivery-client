import 'package:blockatie/provider/login.dart';
import 'package:blockatie/provider/register.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Client authentication normalization', () {
    test('login normalizes supported Jordan phone formats', () {
      final provider = LoginProvider();

      expect(provider.normalizeIdentifier('079 123 4567'), '0791234567');
      expect(provider.normalizeIdentifier('+962 79 123 4567'), '0791234567');
      expect(provider.normalizeIdentifier('00962-79-123-4567'), '0791234567');

      provider.dispose();
    });

    test('login normalizes email case and spaces', () {
      final provider = LoginProvider();

      expect(
        provider.normalizeIdentifier('  Owner@Example.COM  '),
        'owner@example.com',
      );

      provider.dispose();
    });

    test('registration uses the same Jordan phone normalization', () {
      final provider = RegisterProvider();

      expect(provider.normalizePhoneInput('+962 78 555 1234'), '0785551234');
      expect(provider.normalizePhoneInput('00962785551234'), '0785551234');

      provider.dispose();
    });

    test('remember restore is skipped when remember me is disabled', () {
      const validSession = ClientSession(
        clientId: '12',
        apiKey: 'test-api-key',
      );

      expect(
        AuthService.shouldAttemptRememberRestore(
          localSession: validSession,
          rememberEnabled: false,
        ),
        isFalse,
      );
    });
  });
}
