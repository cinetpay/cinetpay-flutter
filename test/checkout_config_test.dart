import 'package:flutter_test/flutter_test.dart';
import 'package:cinetpay_flutter_sdk/cinetpay_flutter_sdk.dart';
import 'package:cinetpay_flutter_sdk/src/models/checkout_config.dart';

void main() {
  group('CheckoutConfig', () {
    test('requires paymentToken', () {
      final config = CheckoutConfig(
        paymentToken: 'valid-test-token-abc123',
      );
      expect(config.paymentToken, 'valid-test-token-abc123');
    });

    test('all callbacks are optional', () {
      final config = CheckoutConfig(
        paymentToken: 'valid-test-token-abc123',
      );
      expect(config.onPaymentSuccess, isNull);
      expect(config.onPaymentFailed, isNull);
      expect(config.onPaymentPending, isNull);
      expect(config.onClose, isNull);
      expect(config.onError, isNull);
    });

    test('accepts all callbacks', () {
      var successCalled = false;
      var failedCalled = false;
      var pendingCalled = false;
      var closeCalled = false;
      var errorCalled = false;

      final config = CheckoutConfig(
        paymentToken: 'valid-test-token-abc123',
        onPaymentSuccess: (_) => successCalled = true,
        onPaymentFailed: (_) => failedCalled = true,
        onPaymentPending: (_) => pendingCalled = true,
        onClose: () => closeCalled = true,
        onError: (_) => errorCalled = true,
      );

      config.onPaymentSuccess!(PaymentResponse(
        amount: 0,
        currency: '',
        status: PaymentStatus.accepted,
        paymentMethod: '',
        description: '',
        transactionId: '',
      ));
      config.onPaymentFailed!(PaymentResponse(
        amount: 0,
        currency: '',
        status: PaymentStatus.refused,
        paymentMethod: '',
        description: '',
        transactionId: '',
      ));
      config.onPaymentPending!(PaymentResponse(
        amount: 0,
        currency: '',
        status: PaymentStatus.pending,
        paymentMethod: '',
        description: '',
        transactionId: '',
      ));
      config.onClose!();
      config.onError!(const PaymentError(code: 'ERR', message: 'test'));

      expect(successCalled, isTrue);
      expect(failedCalled, isTrue);
      expect(pendingCalled, isTrue);
      expect(closeCalled, isTrue);
      expect(errorCalled, isTrue);
    });
  });
}
