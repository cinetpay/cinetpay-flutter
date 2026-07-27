/// Possible statuses of a CinetPay payment.
///
/// These statuses match the ones returned by the CinetPay checkout page
/// via JavaScript postMessage or URL redirect parameters.
enum PaymentStatus {
  /// Payment has been accepted and confirmed.
  accepted('ACCEPTED'),

  /// Payment has been refused by the operator or the user.
  refused('REFUSED'),

  /// Payment is pending confirmation (e.g. waiting for mobile money validation).
  pending('PENDING'),

  /// Payment has been initiated but not yet confirmed.
  initiated('INITIATED'),

  /// Payment has expired before completion.
  expired('EXPIRED'),

  /// Status could not be determined.
  unknown('UNKNOWN');

  const PaymentStatus(this.value);

  /// The raw string value as returned by CinetPay.
  final String value;

  /// Parse a string into a [PaymentStatus].
  ///
  /// Returns [PaymentStatus.unknown] if the string does not match any status.
  static PaymentStatus fromString(String? value) {
    if (value == null) return PaymentStatus.unknown;
    final upper = value.toUpperCase();
    return PaymentStatus.values.firstWhere(
      (s) => s.value == upper,
      orElse: () => PaymentStatus.unknown,
    );
  }

  /// Whether this status represents a successful payment.
  bool get isSuccess => this == PaymentStatus.accepted;

  /// Whether this status represents a failed payment.
  bool get isFailed => this == PaymentStatus.refused;

  /// Whether this status represents a pending payment.
  bool get isPending =>
      this == PaymentStatus.pending ||
      this == PaymentStatus.initiated ||
      this == PaymentStatus.expired;

  /// Whether this status is final and will not change.
  ///
  /// Used to stop status polling. Note that [expired] is terminal even though
  /// [isPending] also reports `true` for it, for backwards compatibility.
  bool get isTerminal =>
      this == PaymentStatus.accepted ||
      this == PaymentStatus.refused ||
      this == PaymentStatus.expired;
}
