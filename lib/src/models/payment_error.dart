/// Represents an error that occurred during the CinetPay checkout flow.
///
/// This may be a technical error (WebView failure, network issue) or a
/// business error returned by the CinetPay checkout page.
class PaymentError {
  /// Creates a [PaymentError].
  const PaymentError({
    required this.code,
    required this.message,
  });

  /// Creates a [PaymentError] from a JSON map.
  factory PaymentError.fromJson(Map<String, dynamic> json) {
    return PaymentError(
      code: (json['code'] ?? 'UNKNOWN').toString(),
      message: (json['message'] ?? json['error'] ?? 'An error occurred')
          .toString(),
    );
  }

  /// The error code (e.g. INVALID_TOKEN, WEBVIEW_ERROR, NETWORK_ERROR).
  final String code;

  /// A human-readable error message.
  final String message;

  /// Converts this error to a JSON map.
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };

  @override
  String toString() => 'PaymentError(code: $code, message: $message)';
}
