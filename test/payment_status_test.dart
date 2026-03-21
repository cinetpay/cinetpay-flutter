import 'package:flutter_test/flutter_test.dart';
import 'package:cinetpay_flutter_sdk/cinetpay_flutter_sdk.dart';

void main() {
  group('PaymentStatus', () {
    test('fromString parses ACCEPTED', () {
      expect(PaymentStatus.fromString('ACCEPTED'), PaymentStatus.accepted);
    });

    test('fromString parses REFUSED', () {
      expect(PaymentStatus.fromString('REFUSED'), PaymentStatus.refused);
    });

    test('fromString parses PENDING', () {
      expect(PaymentStatus.fromString('PENDING'), PaymentStatus.pending);
    });

    test('fromString parses INITIATED', () {
      expect(PaymentStatus.fromString('INITIATED'), PaymentStatus.initiated);
    });

    test('fromString parses EXPIRED', () {
      expect(PaymentStatus.fromString('EXPIRED'), PaymentStatus.expired);
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(PaymentStatus.fromString('SOME_NEW_STATUS'), PaymentStatus.unknown);
    });

    test('fromString returns unknown for empty string', () {
      expect(PaymentStatus.fromString(''), PaymentStatus.unknown);
    });

    test('fromString is case insensitive', () {
      expect(PaymentStatus.fromString('accepted'), PaymentStatus.accepted);
      expect(PaymentStatus.fromString('Refused'), PaymentStatus.refused);
    });

    test('isSuccess returns true for accepted', () {
      expect(PaymentStatus.accepted.isSuccess, isTrue);
    });

    test('isSuccess returns false for others', () {
      expect(PaymentStatus.refused.isSuccess, isFalse);
      expect(PaymentStatus.pending.isSuccess, isFalse);
      expect(PaymentStatus.unknown.isSuccess, isFalse);
    });

    test('isFailed returns true for refused', () {
      expect(PaymentStatus.refused.isFailed, isTrue);
    });

    test('isFailed returns false for others', () {
      expect(PaymentStatus.accepted.isFailed, isFalse);
      expect(PaymentStatus.pending.isFailed, isFalse);
    });

    test('isPending returns true for pending statuses', () {
      expect(PaymentStatus.pending.isPending, isTrue);
      expect(PaymentStatus.initiated.isPending, isTrue);
      expect(PaymentStatus.expired.isPending, isTrue);
    });

    test('isPending returns false for unknown', () {
      expect(PaymentStatus.unknown.isPending, isFalse);
    });

    test('isPending returns false for final statuses', () {
      expect(PaymentStatus.accepted.isPending, isFalse);
      expect(PaymentStatus.refused.isPending, isFalse);
    });

    test('value returns correct string', () {
      expect(PaymentStatus.accepted.value, 'ACCEPTED');
      expect(PaymentStatus.refused.value, 'REFUSED');
      expect(PaymentStatus.pending.value, 'PENDING');
      expect(PaymentStatus.initiated.value, 'INITIATED');
      expect(PaymentStatus.expired.value, 'EXPIRED');
      expect(PaymentStatus.unknown.value, 'UNKNOWN');
    });
  });
}
