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
