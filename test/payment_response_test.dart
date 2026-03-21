import 'package:flutter_test/flutter_test.dart';
import 'package:cinetpay_flutter/cinetpay_flutter.dart';

void main() {
  group('PaymentResponse', () {
    test('fromJson parses new-format fields', () {
      final response = PaymentResponse.fromJson({
        'amount': 1000,
        'currency': 'XOF',
        'status': 'ACCEPTED',
        'payment_method': 'OM_CI',
        'description': 'Test payment',
        'transaction_id': 'TX-123',
        'metadata': 'order-456',
        'operator_id': 'op-789',
        'payment_date': '2026-03-21',
      });

      expect(response.amount, 1000);
      expect(response.currency, 'XOF');
      expect(response.status, PaymentStatus.accepted);
      expect(response.paymentMethod, 'OM_CI');
      expect(response.description, 'Test payment');
      expect(response.transactionId, 'TX-123');
      expect(response.metadata, 'order-456');
      expect(response.operatorId, 'op-789');
      expect(response.paymentDate, '2026-03-21');
    });

    test('fromJson parses legacy cpm_ fields', () {
      final response = PaymentResponse.fromJson({
        'cpm_amount': 2000,
        'cpm_currency': 'XAF',
        'status': 'REFUSED',
        'cpm_payment_method': 'MTN_CM',
        'cpm_designation': 'Legacy payment',
        'cpm_trans_id': 'TX-OLD',
        'cpm_custom': 'meta-old',
      });

      expect(response.amount, 2000);
      expect(response.currency, 'XAF');
      expect(response.status, PaymentStatus.refused);
      expect(response.paymentMethod, 'MTN_CM');
      expect(response.description, 'Legacy payment');
      expect(response.transactionId, 'TX-OLD');
      expect(response.metadata, 'meta-old');
    });

    test('fromJson handles missing optional fields', () {
      final response = PaymentResponse.fromJson({
        'amount': 500,
        'currency': 'XOF',
        'status': 'PENDING',
        'transaction_id': 'TX-MIN',
      });

      expect(response.amount, 500);
      expect(response.status, PaymentStatus.pending);
      expect(response.paymentMethod, '');
      expect(response.description, '');
      expect(response.metadata, isNull);
      expect(response.operatorId, isNull);
      expect(response.paymentDate, isNull);
    });

    test('fromJson handles empty map', () {
      final response = PaymentResponse.fromJson({});

      expect(response.amount, 0);
      expect(response.currency, '');
      expect(response.status, PaymentStatus.unknown);
      expect(response.transactionId, '');
    });

    test('fromJson prefers new fields over legacy', () {
      final response = PaymentResponse.fromJson({
        'amount': 1000,
        'cpm_amount': 2000,
        'currency': 'XOF',
        'cpm_currency': 'XAF',
        'status': 'ACCEPTED',
        'transaction_id': 'TX-NEW',
        'cpm_trans_id': 'TX-OLD',
      });

      expect(response.amount, 1000);
      expect(response.currency, 'XOF');
      expect(response.transactionId, 'TX-NEW');
    });

    test('toJson serializes correctly', () {
      final response = PaymentResponse(
        amount: 5000,
        currency: 'GNF',
        status: PaymentStatus.accepted,
        paymentMethod: 'OM_GN',
        description: 'Test',
        transactionId: 'TX-SERIAL',
        metadata: 'meta',
      );

      final json = response.toJson();
      expect(json['amount'], 5000);
      expect(json['currency'], 'GNF');
      expect(json['status'], 'ACCEPTED');
      expect(json['paymentMethod'], 'OM_GN');
      expect(json['transactionId'], 'TX-SERIAL');
      expect(json['metadata'], 'meta');
    });
  });
}
