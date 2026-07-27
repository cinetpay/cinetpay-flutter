import 'payment_status.dart';

/// Response data returned by the CinetPay checkout page after a payment attempt.
///
/// This model is constructed from the JavaScript postMessage or URL parameters
/// sent by the CinetPay checkout page. It is passed to the appropriate callback
/// ([onPaymentSuccess], [onPaymentFailed], or [onPaymentPending]).
class PaymentResponse {
  /// Creates a [PaymentResponse].
  const PaymentResponse({
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.description,
    required this.transactionId,
    this.metadata,
    this.operatorId,
    this.paymentDate,
    this.dataAvailable = true,
  });

  /// Creates a [PaymentResponse] from a JSON map.
  ///
  /// Supports both the new CinetPay field names and the legacy `cpm_*` prefixed names.
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      amount: _parseNum(json['amount'] ?? json['cpm_amount']),
      currency: (json['currency'] ?? json['cpm_currency'] ?? '').toString(),
      status: PaymentStatus.fromString(
        (json['status'] ?? json['cpm_status'])?.toString(),
      ),
      paymentMethod:
          (json['payment_method'] ?? json['cpm_payment_method'] ?? '')
              .toString(),
      description:
          (json['description'] ?? json['cpm_designation'] ?? '').toString(),
      transactionId:
          (json['transaction_id'] ?? json['cpm_trans_id'] ?? '').toString(),
      metadata: (json['metadata'] ?? json['cpm_custom'])?.toString(),
      operatorId: (json['operator_id'] ?? json['cpm_operator_id'])?.toString(),
      paymentDate:
          (json['payment_date'] ?? json['cpm_payment_date'])?.toString(),
    );
  }

  /// The amount paid.
  final num amount;

  /// The currency code (e.g. XOF, XAF, GNF, USD).
  final String currency;

  /// The payment status.
  final PaymentStatus status;

  /// The payment method code (e.g. OM, MOMO, WAVE, VISA).
  final String paymentMethod;

  /// The payment description.
  final String description;

  /// The CinetPay transaction ID.
  final String transactionId;

  /// Custom metadata passed during payment initialization.
  final String? metadata;

  /// The operator's transaction ID.
  final String? operatorId;

  /// The payment date as returned by CinetPay.
  final String? paymentDate;

  /// Whether this response carries actual payment data.
  ///
  /// `false` when the status was inferred from the checkout URL alone — in
  /// that case [amount], [currency] and [transactionId] are empty placeholders
  /// and must not be trusted. Configure a [PaymentStatusChecker] to always
  /// receive populated responses.
  final bool dataAvailable;

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currency': currency,
        'status': status.value,
        'paymentMethod': paymentMethod,
        'description': description,
        'transactionId': transactionId,
        if (metadata != null) 'metadata': metadata,
        if (operatorId != null) 'operatorId': operatorId,
        if (paymentDate != null) 'paymentDate': paymentDate,
      };

  static num _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() =>
      'PaymentResponse(status: ${status.value}, amount: $amount $currency, '
      'transactionId: $transactionId)';
}
