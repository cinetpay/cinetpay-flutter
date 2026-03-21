/// CinetPay Flutter SDK — frontend-only checkout for mobile apps.
///
/// This SDK opens the CinetPay checkout page in a WebView and reports
/// the payment result back to your app. The payment must be initialized
/// on your backend first using one of the server-side SDKs (cinetpay-js,
/// cinetpay-python, cinetpay-go, etc.), which returns a `paymentToken`.
///
/// ## Quick start
///
/// ```dart
/// import 'package:cinetpay_flutter_sdk/cinetpay_flutter_sdk.dart';
///
/// CinetPay.show(
///   context: context,
///   paymentToken: tokenFromBackend,
///   onPaymentSuccess: (data) => print('Paid!'),
///   onPaymentFailed: (data) => print('Failed'),
/// );
/// ```
///
/// See also:
/// - [CinetPay] — static entry point with `show()` and `openInBrowser()`.
/// - [CinetPayCheckoutPage] — full-screen WebView checkout widget.
/// - [CinetPayButton] — pre-styled button that triggers the checkout.
library;

// Main entry point
export 'src/cinetpay.dart';

// Widgets
export 'src/checkout_page.dart';
export 'src/checkout_bottom_sheet.dart';
export 'src/cinetpay_button.dart';

// Models
export 'src/models/checkout_config.dart';
export 'src/models/payment_error.dart';
export 'src/models/payment_response.dart';
export 'src/models/payment_status.dart';

// Utilities
export 'src/constants.dart';
export 'src/utils/token_validator.dart';
