import 'package:flutter_test/flutter_test.dart';
import 'package:cinetpay_flutter_sdk/src/constants.dart';

void main() {
  group('CinetPayConstants', () {
    test('secureBaseUrl is HTTPS', () {
      expect(CinetPayConstants.secureBaseUrl, startsWith('https://'));
    });

    test('checkoutUrl builds correct URL', () {
      final url = CinetPayConstants.checkoutUrl('abc123def456');
      expect(url, 'https://secure.cinetpay.net/checkout/abc123def456');
    });

    test('checkoutUrl targets sandbox by default', () {
      expect(
        CinetPayConstants.checkoutUrl(
          'abc123def456',
          environment: CinetPayEnvironment.sandbox,
        ),
        'https://secure.cinetpay.net/checkout/abc123def456',
      );
    });

    test('checkoutUrl targets the production host in production', () {
      expect(
        CinetPayConstants.checkoutUrl(
          'abc123def456',
          environment: CinetPayEnvironment.production,
        ),
        'https://secure.cinetpay.co/checkout/abc123def456',
      );
    });

    test('production and sandbox hosts differ', () {
      expect(
        CinetPayConstants.secureBaseUrls[CinetPayEnvironment.production],
        isNot(CinetPayConstants.secureBaseUrls[CinetPayEnvironment.sandbox]),
      );
    });

    test('checkoutUrl honours an explicit baseUrl over the environment', () {
      expect(
        CinetPayConstants.checkoutUrl(
          'abc123def456',
          environment: CinetPayEnvironment.production,
          baseUrl: 'https://pay.example.com',
        ),
        'https://pay.example.com/checkout/abc123def456',
      );
    });

    test('checkoutUrl strips trailing slashes from baseUrl', () {
      expect(
        CinetPayConstants.checkoutUrl(
          'abc123def456',
          baseUrl: 'https://pay.example.com//',
        ),
        'https://pay.example.com/checkout/abc123def456',
      );
    });

    test('every secure base URL has a matching allowed origin', () {
      for (final base in CinetPayConstants.secureBaseUrls.values) {
        expect(CinetPayConstants.allowedOrigins, contains(base));
      }
    });

    test('URL indicators are lowercase so they match lowercased URLs', () {
      final indicators = [
        ...CinetPayConstants.successIndicators,
        ...CinetPayConstants.failureIndicators,
        ...CinetPayConstants.pendingIndicators,
      ];
      for (final indicator in indicators) {
        expect(indicator, indicator.toLowerCase());
      }
    });

    test('allowedOrigins contains secure.cinetpay.net', () {
      expect(
        CinetPayConstants.allowedOrigins,
        contains('https://secure.cinetpay.net'),
      );
    });

    test('allowedOrigins contains api.cinetpay.net', () {
      expect(
        CinetPayConstants.allowedOrigins,
        contains('https://api.cinetpay.net'),
      );
    });

    test('allowedOrigins contains api.cinetpay.co', () {
      expect(
        CinetPayConstants.allowedOrigins,
        contains('https://api.cinetpay.co'),
      );
    });

    test('tokenRegex matches valid tokens', () {
      expect(CinetPayConstants.tokenPattern.hasMatch('abcdef1234'), isTrue);
      expect(
        CinetPayConstants.tokenPattern.hasMatch('valid-token_with-chars'),
        isTrue,
      );
    });

    test('tokenRegex rejects invalid tokens', () {
      expect(CinetPayConstants.tokenPattern.hasMatch('abc'), isFalse);
      expect(CinetPayConstants.tokenPattern.hasMatch(''), isFalse);
      expect(
        CinetPayConstants.tokenPattern.hasMatch('<script>alert(1)</script>'),
        isFalse,
      );
    });

    test('successIndicators is not empty', () {
      expect(CinetPayConstants.successIndicators, isNotEmpty);
    });

    test('failureIndicators is not empty', () {
      expect(CinetPayConstants.failureIndicators, isNotEmpty);
    });
  });
}
