import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'checkout_bottom_sheet.dart';
import 'constants.dart';
import 'models/checkout_config.dart';
import 'models/payment_error.dart';
import 'utils/token_validator.dart';

/// Main entry point for the CinetPay Flutter SDK.
///
/// Provides static methods to display the CinetPay checkout flow. The payment
/// must be initialized on your backend first, which returns a [paymentToken].
/// This SDK then opens the CinetPay checkout page in a WebView.
///
/// ## Quick start
///
/// ```dart
/// CinetPay.show(
///   context: context,
///   paymentToken: 'abc123def456...',
///   // Must match where the token was created. Defaults to sandbox.
///   environment: CinetPayEnvironment.production,
///   onPaymentSuccess: (data) {
///     print('Paid ${data.amount} ${data.currency}');
///   },
///   onPaymentFailed: (data) {
///     print('Payment failed');
///   },
///   onClose: () {
///     print('Checkout closed');
///   },
/// );
/// ```
class CinetPay {
  CinetPay._();

  /// SDK version.
  static const String version = '1.1.0';

  /// Shows the CinetPay checkout as a modal bottom sheet.
  ///
  /// This is the recommended way to integrate CinetPay in your app.
  /// The checkout slides up from the bottom, covering 92% of the screen.
  ///
  /// The [paymentToken] must be obtained from your backend by calling
  /// the CinetPay API (`POST /v1/payment`), and [environment] must match the
  /// environment that token was created on — a production token opened against
  /// the sandbox host returns a `404`.
  ///
  /// Supply a [statusChecker] to receive responses containing the real amount
  /// and transaction id; without it, only the status is reported.
  ///
  /// If the token is invalid, the [onError] callback is called immediately
  /// and the bottom sheet is not shown.
  static void show({
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
    // Validate token before opening
    final tokenError = TokenValidator.validate(paymentToken);
    if (tokenError != null) {
      onError?.call(tokenError);
      return;
    }

    showCinetPayBottomSheet(
      context: context,
      paymentToken: paymentToken,
      environment: environment,
      checkoutBaseUrl: checkoutBaseUrl,
      statusChecker: statusChecker,
      statusPollInterval: statusPollInterval,
      onPaymentSuccess: onPaymentSuccess,
      onPaymentFailed: onPaymentFailed,
      onPaymentPending: onPaymentPending,
      onClose: onClose,
      onError: onError,
      heightFactor: heightFactor,
    );
  }

  /// Shows the CinetPay checkout from a [CheckoutConfig] object.
  ///
  /// This is a convenience method for when you have a pre-built config.
  static void showFromConfig({
    required BuildContext context,
    required CheckoutConfig config,
    double heightFactor = 0.92,
  }) {
    show(
      context: context,
      paymentToken: config.paymentToken,
      environment: config.environment,
      checkoutBaseUrl: config.checkoutBaseUrl,
      statusChecker: config.statusChecker,
      statusPollInterval: config.statusPollInterval,
      onPaymentSuccess: config.onPaymentSuccess,
      onPaymentFailed: config.onPaymentFailed,
      onPaymentPending: config.onPaymentPending,
      onClose: config.onClose,
      onError: config.onError,
      heightFactor: heightFactor,
    );
  }

  /// Opens the CinetPay checkout in the system browser as a fallback.
  ///
  /// Use this when the WebView is not available or as a backup option.
  /// Note that when using the external browser, payment callbacks will NOT
  /// be triggered since communication is lost. You should rely on your
  /// backend webhook (notify_url) to confirm the payment.
  static Future<bool> openInBrowser({
    required String paymentToken,
    CinetPayEnvironment environment = CinetPayEnvironment.sandbox,
    String? checkoutBaseUrl,
    ErrorCallback? onError,
  }) async {
    final tokenError = TokenValidator.validate(paymentToken);
    if (tokenError != null) {
      onError?.call(tokenError);
      return false;
    }

    final url = Uri.parse(
      CinetPayConstants.checkoutUrl(
        paymentToken,
        environment: environment,
        baseUrl: checkoutBaseUrl,
      ),
    );

    if (await canLaunchUrl(url)) {
      return launchUrl(url, mode: LaunchMode.externalApplication);
    }

    onError?.call(
      const PaymentError(
        code: 'LAUNCH_FAILED',
        message: 'Could not open the payment page in the browser.',
      ),
    );
    return false;
  }
}
