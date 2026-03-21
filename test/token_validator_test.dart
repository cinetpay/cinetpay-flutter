import 'package:flutter_test/flutter_test.dart';
import 'package:cinetpay_flutter_sdk/cinetpay_flutter_sdk.dart';
import 'package:cinetpay_flutter_sdk/src/utils/token_validator.dart';

void main() {
  group('TokenValidator', () {
    group('validate()', () {
      test('returns null for valid token', () {
        expect(
          TokenValidator.validate('1ef969cf5da467dc98c70242f6c351d52eb3ff889b0f4f9e94078a1a0da6a2a3'),
          isNull,
        );
      });

      test('returns null for 10-char token', () {
        expect(TokenValidator.validate('abcdef1234'), isNull);
      });

      test('returns null for token with hyphens and underscores', () {
        expect(TokenValidator.validate('valid-token_with-mixed_chars'), isNull);
      });

      test('returns error for null token', () {
        final error = TokenValidator.validate(null);
        expect(error, isNotNull);
        expect(error!.code, 'INVALID_TOKEN');
      });

      test('returns error for empty token', () {
        final error = TokenValidator.validate('');
        expect(error, isNotNull);
        expect(error!.code, 'INVALID_TOKEN');
      });

      test('returns error for too short token', () {
        final error = TokenValidator.validate('abc');
        expect(error, isNotNull);
        expect(error!.code, 'INVALID_TOKEN');
      });

      test('returns error for token with special chars', () {
        final error = TokenValidator.validate('<script>alert(1)</script>');
        expect(error, isNotNull);
        expect(error!.code, 'INVALID_TOKEN');
      });

      test('returns error for path traversal', () {
        final error = TokenValidator.validate('../../../etc/passwd');
        expect(error, isNotNull);
      });

      test('returns error for token with spaces', () {
        final error = TokenValidator.validate('token with spaces here');
        expect(error, isNotNull);
      });

      test('returns error for too long token (129 chars)', () {
        final error = TokenValidator.validate('a' * 129);
        expect(error, isNotNull);
      });

      test('returns null for 128-char token', () {
        expect(TokenValidator.validate('a' * 128), isNull);
      });
    });

    group('isValid()', () {
      test('returns true for valid token', () {
        expect(TokenValidator.isValid('valid-token-abc123'), isTrue);
      });

      test('returns false for invalid token', () {
        expect(TokenValidator.isValid(''), isFalse);
        expect(TokenValidator.isValid(null), isFalse);
        expect(TokenValidator.isValid('ab'), isFalse);
      });
    });
  });
}
