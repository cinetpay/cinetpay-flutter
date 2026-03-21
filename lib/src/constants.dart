/// CinetPay SDK constants.
///
/// These values are used internally by the SDK to construct checkout URLs
/// and validate payment tokens.
class CinetPayConstants {
  CinetPayConstants._();

  /// Base URL of the CinetPay secure checkout.
  static const String secureBaseUrl = 'https://secure.cinetpay.net';

  /// Full checkout URL template. Replace `{token}` with the payment token.
  static String checkoutUrl(String paymentToken) =>
      '$secureBaseUrl/checkout/$paymentToken';

  /// Allowed origins for JavaScript postMessage communication.
  ///
  /// The checkout page may send messages from any of these origins.
  static const List<String> allowedOrigins = [
    'https://secure.cinetpay.net',
    'https://secure.cinetpay.com',
    'https://checkout.cinetpay.net',
    'https://checkout.cinetpay.com',
    'https://api.cinetpay.net',
    'https://api.cinetpay.co',
  ];

  /// URL path segments that indicate a successful payment redirect.
  static const List<String> successIndicators = [
    '/success',
    '/payment/success',
    'status=ACCEPTED',
  ];

  /// URL path segments that indicate a failed payment redirect.
  static const List<String> failureIndicators = [
    '/failed',
    '/failure',
    '/payment/failed',
    'status=REFUSED',
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
