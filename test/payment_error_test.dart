import 'package:flutter_test/flutter_test.dart';
import 'package:cinetpay_flutter/cinetpay_flutter.dart';

void main() {
  group('PaymentError', () {
    test('constructor sets fields', () {
      const error = PaymentError(code: 'ERR_001', message: 'Something failed');
      expect(error.code, 'ERR_001');
      expect(error.message, 'Something failed');
    });

    test('fromJson parses code and message', () {
      final error = PaymentError.fromJson({
        'code': 'TIMEOUT',
        'message': 'Request timed out',
      });
      expect(error.code, 'TIMEOUT');
      expect(error.message, 'Request timed out');
    });

    test('fromJson uses error field as fallback for message', () {
      final error = PaymentError.fromJson({
        'code': 'NETWORK',
        'error': 'Connection refused',
      });
      expect(error.message, 'Connection refused');
    });

    test('fromJson handles missing fields', () {
      final error = PaymentError.fromJson({});
      expect(error.code, 'UNKNOWN');
      expect(error.message, 'An error occurred');
    });

    test('fromJson converts code to string', () {
      final error = PaymentError.fromJson({
        'code': 1005,
        'message': 'Invalid credentials',
      });
      expect(error.code, '1005');
    });

    test('toString returns readable format', () {
      const error = PaymentError(code: 'ERR', message: 'Test');
      expect(error.toString(), contains('ERR'));
      expect(error.toString(), contains('Test'));
    });
  });
}
