import 'package:flutter/material.dart';

import 'constants.dart';
import 'models/payment_error.dart';
import 'models/payment_response.dart';
import 'models/payment_status.dart';

/// Stub for the web platform — WebView is not available on web.
/// This file is only imported when dart.library.io is NOT available.
Widget buildWebView({
  required String paymentToken,
  required CinetPayEnvironment environment,
  required String? checkoutBaseUrl,
  required Color backgroundColor,
  required void Function(PaymentResponse) onPaymentResponse,
  required void Function(PaymentStatus) onUrlStatus,
  required void Function(PaymentError) onError,
  required VoidCallback onPageStarted,
  required VoidCallback onPageFinished,
  required VoidCallback onWebResourceError,
}) {
  // Should never be called on web — checkout_page.dart handles the web case
  // separately by opening the checkout in the browser.
  return const Center(
    child: Text('WebView is not supported on this platform.'),
  );
}
