import 'package:flutter/material.dart';

import 'checkout_page.dart';
import 'models/checkout_config.dart';

/// Displays the CinetPay checkout inside a modal bottom sheet.
///
/// This provides a native-feeling payment experience where the checkout
/// slides up from the bottom of the screen, covering most of the app.
///
/// The bottom sheet is not dismissible by tapping outside or swiping down
/// to prevent accidental closure during payment.
///
/// ## Usage
///
/// ```dart
/// showCinetPayBottomSheet(
///   context: context,
///   paymentToken: 'abc123...',
///   onPaymentSuccess: (data) {
///     Navigator.pop(context);
///     showDialog(...);
///   },
/// );
/// ```
void showCinetPayBottomSheet({
  required BuildContext context,
  required String paymentToken,
  PaymentCallback? onPaymentSuccess,
  PaymentCallback? onPaymentFailed,
  PaymentCallback? onPaymentPending,
  CloseCallback? onClose,
  ErrorCallback? onError,
  double heightFactor = 0.92,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: heightFactor,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          child: CinetPayCheckoutPage(
            paymentToken: paymentToken,
            showAppBar: true,
            appBarTitle: 'Paiement CinetPay',
            onPaymentSuccess: (data) {
              onPaymentSuccess?.call(data);
            },
            onPaymentFailed: (data) {
              onPaymentFailed?.call(data);
            },
            onPaymentPending: (data) {
              onPaymentPending?.call(data);
            },
            onClose: () {
              Navigator.of(sheetContext).pop();
              onClose?.call();
            },
            onError: (error) {
              onError?.call(error);
            },
          ),
        ),
      );
    },
  );
}
