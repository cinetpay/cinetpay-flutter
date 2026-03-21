import 'package:flutter/material.dart';

import 'cinetpay.dart';
import 'models/checkout_config.dart';

/// A pre-styled button that opens the CinetPay checkout when pressed.
///
/// The button displays customizable text and triggers [CinetPay.show()]
/// when tapped. It uses CinetPay's brand colors by default but can be
/// fully customized.
///
/// ## Usage
///
/// ```dart
/// CinetPayButton(
///   paymentToken: 'abc123def456...',
///   text: 'Payer 5000 XOF',
///   onPaymentSuccess: (data) {
///     print('Paid: ${data.transactionId}');
///   },
/// )
/// ```
///
/// ## Custom styling
///
/// ```dart
/// CinetPayButton(
///   paymentToken: token,
///   text: 'Pay now',
///   style: ElevatedButton.styleFrom(
///     backgroundColor: Colors.green,
///     foregroundColor: Colors.white,
///     padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
///   ),
///   onPaymentSuccess: (data) { ... },
/// )
/// ```
class CinetPayButton extends StatelessWidget {
  /// Creates a [CinetPayButton].
  const CinetPayButton({
    super.key,
    required this.paymentToken,
    this.text = 'Payer avec CinetPay',
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentPending,
    this.onClose,
    this.onError,
    this.style,
    this.icon,
    this.enabled = true,
    this.heightFactor = 0.92,
  });

  /// Creates a [CinetPayButton] from a [CheckoutConfig].
  factory CinetPayButton.fromConfig({
    Key? key,
    required CheckoutConfig config,
    String text = 'Payer avec CinetPay',
    ButtonStyle? style,
    Widget? icon,
    bool enabled = true,
    double heightFactor = 0.92,
  }) {
    return CinetPayButton(
      key: key,
      paymentToken: config.paymentToken,
      text: text,
      onPaymentSuccess: config.onPaymentSuccess,
      onPaymentFailed: config.onPaymentFailed,
      onPaymentPending: config.onPaymentPending,
      onClose: config.onClose,
      onError: config.onError,
      style: style,
      icon: icon,
      enabled: enabled,
      heightFactor: heightFactor,
    );
  }

  /// The payment token obtained from your backend.
  final String paymentToken;

  /// Button label text.
  final String text;

  /// Called when the payment is accepted.
  final PaymentCallback? onPaymentSuccess;

  /// Called when the payment is refused.
  final PaymentCallback? onPaymentFailed;

  /// Called when the payment is pending.
  final PaymentCallback? onPaymentPending;

  /// Called when the checkout is closed.
  final CloseCallback? onClose;

  /// Called when an error occurs.
  final ErrorCallback? onError;

  /// Custom button style. If null, CinetPay brand style is used.
  final ButtonStyle? style;

  /// Optional icon displayed before the text.
  final Widget? icon;

  /// Whether the button is enabled. Defaults to `true`.
  final bool enabled;

  /// Height factor for the bottom sheet (0.0 to 1.0).
  final double heightFactor;

  /// CinetPay brand green color.
  static const Color _brandColor = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = ElevatedButton.styleFrom(
      backgroundColor: _brandColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    final buttonStyle = style ?? defaultStyle;

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: enabled ? () => _onPressed(context) : null,
        style: buttonStyle,
        icon: icon!,
        label: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: enabled ? () => _onPressed(context) : null,
      style: buttonStyle,
      child: Text(text),
    );
  }

  void _onPressed(BuildContext context) {
    CinetPay.show(
      context: context,
      paymentToken: paymentToken,
      onPaymentSuccess: onPaymentSuccess,
      onPaymentFailed: onPaymentFailed,
      onPaymentPending: onPaymentPending,
      onClose: onClose,
      onError: onError,
      heightFactor: heightFactor,
    );
  }
}
