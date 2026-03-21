# Changelog

## 1.0.0

- Initial release.
- `CinetPay.show()` — display checkout as a bottom sheet.
- `CinetPayCheckoutPage` — full-screen checkout widget with WebView.
- `CinetPayButton` — styled button that triggers the checkout flow.
- WebView-based checkout with `webview_flutter`.
- `url_launcher` fallback when WebView is unavailable.
- JavaScript message interception for payment status detection.
- Navigation interception for success/failure URL detection.
- `PaymentResponse`, `PaymentError`, `PaymentStatus` models.
- Token validation (alphanumeric, 10-128 characters).
