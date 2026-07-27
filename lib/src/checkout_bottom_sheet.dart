import 'package:flutter/material.dart';

import 'checkout_page.dart';
import 'constants.dart';
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
///   environment: CinetPayEnvironment.production,
///   onPaymentSuccess: (data) {
///     showDialog(...);
///   },
/// );
/// ```
void showCinetPayBottomSheet({
  required BuildContext context,
  required String paymentToken,
  CinetPayEnvironment environment = CinetPayEnvironment.sandbox,
  String? checkoutBaseUrl,
  PaymentStatusChecker? statusChecker,
  Duration statusPollInterval = const Duration(seconds: 3),
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
          // `onClose` is a pure notification: the checkout page pops its own
          // route. Popping here as well re-enters Navigator during its history
          // flush, which asserts in debug and dismisses the merchant's page in
          // release.
          child: CinetPayCheckoutPage(
            paymentToken: paymentToken,
            environment: environment,
            checkoutBaseUrl: checkoutBaseUrl,
            statusChecker: statusChecker,
            statusPollInterval: statusPollInterval,
            showAppBar: true,
            appBarTitle: 'Paiement CinetPay',
            onPaymentSuccess: onPaymentSuccess,
            onPaymentFailed: onPaymentFailed,
            onPaymentPending: onPaymentPending,
            onClose: onClose,
            onError: onError,
          ),
        ),
      );
    },
  );
}
