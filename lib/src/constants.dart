/// The CinetPay environment used to build the checkout URL.
///
/// The payment token is minted by the CinetPay API on a specific environment
/// and is only valid on the matching checkout host. Using the wrong
/// environment produces a `404` on the checkout page.
enum CinetPayEnvironment {
  /// Sandbox environment — tokens created via `api.cinetpay.net`.
  sandbox,

  /// Production environment — tokens created via `api.cinetpay.co`.
  production,
}

/// CinetPay SDK constants.
///
/// These values are used internally by the SDK to construct checkout URLs
/// and validate payment tokens.
class CinetPayConstants {
  CinetPayConstants._();

  /// Base URL of the CinetPay secure checkout, per environment.
  ///
  /// These mirror the hosts used by the JavaScript SDK (`cinetpay-seamless`).
  static const Map<CinetPayEnvironment, String> secureBaseUrls = {
    CinetPayEnvironment.sandbox: 'https://secure.cinetpay.net',
    CinetPayEnvironment.production: 'https://secure.cinetpay.co',
  };

  /// Base URL of the sandbox checkout.
  ///
  /// Kept for backwards compatibility. Prefer [secureBaseUrls].
  static const String secureBaseUrl = 'https://secure.cinetpay.net';

  /// Builds the full checkout URL for [paymentToken].
  ///
  /// By default the sandbox host is used, matching the JavaScript SDK. Pass
  /// [environment] to target production, or [baseUrl] to override the host
  /// entirely (useful when CinetPay provisions a dedicated host).
  static String checkoutUrl(
    String paymentToken, {
    CinetPayEnvironment environment = CinetPayEnvironment.sandbox,
    String? baseUrl,
  }) {
    final host = (baseUrl ?? secureBaseUrls[environment]!)
        .replaceAll(RegExp(r'/+$'), '');
    return '$host/checkout/$paymentToken';
  }

  /// Allowed origins for JavaScript postMessage communication.
  ///
  /// Messages coming from any other origin are discarded. A page loaded in the
  /// checkout WebView may embed third-party content (operator redirects), so
  /// this list is the only thing preventing a forged payment result.
  static const List<String> allowedOrigins = [
    'https://secure.cinetpay.net',
    'https://secure.cinetpay.co',
    'https://secure.cinetpay.com',
    'https://checkout.cinetpay.net',
    'https://checkout.cinetpay.co',
    'https://checkout.cinetpay.com',
    'https://api.cinetpay.net',
    'https://api.cinetpay.co',
  ];

  /// URL path segments that indicate a successful payment redirect.
  static const List<String> successIndicators = [
    '/success',
    '/payment/success',
    'status=accepted',
  ];

  /// URL path segments that indicate a failed payment redirect.
  static const List<String> failureIndicators = [
    '/failed',
    '/failure',
    '/payment/failed',
    'status=refused',
  ];

  /// URL path segments that indicate a pending payment redirect.
  static const List<String> pendingIndicators = [
    '/pending',
    'status=pending',
  ];

  /// Minimum length of a valid payment token.
  static const int tokenMinLength = 10;

  /// Maximum length of a valid payment token.
  static const int tokenMaxLength = 128;

  /// Regular expression pattern for validating payment tokens.
  ///
  /// Tokens must be alphanumeric (plus hyphens and underscores), between
  /// 10 and 128 characters.
  static final RegExp tokenPattern =
      RegExp(r'^[a-zA-Z0-9_-]{10,128}$');

  /// Countries supported by CinetPay.
  static const List<String> supportedCountries = [
    'BF', // Burkina Faso
    'BJ', // Benin
    'CD', // DR Congo
    'CI', // Ivory Coast
    'CM', // Cameroon
    'GN', // Guinea
    'GW', // Guinea-Bissau
    'ML', // Mali
    'NE', // Niger
    'SN', // Senegal
    'TG', // Togo
  ];
}
