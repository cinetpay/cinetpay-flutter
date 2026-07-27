# Changelog

## 1.1.0

### Fixed

- **Production checkout returned `404`.** The checkout host was hardcoded to
  `https://secure.cinetpay.net` (sandbox), with no way to override it. A token
  created on production (`api.cinetpay.co`) was opened against the sandbox host,
  where it does not exist. Added `environment:` (`sandbox` | `production`) and
  `checkoutBaseUrl:`, mirroring the JavaScript SDK. **Merchants in production
  must now pass `environment: CinetPayEnvironment.production`.**
- **Closing the bottom sheet crashed and never reported.** Tapping the close
  button re-entered `Navigator.pop` during its own history flush: the sheet did
  not close, `onClose` was never called, and in release builds the merchant's
  own page was dismissed. `onClose` is now a pure notification and fires exactly
  once. Covered by `test/checkout_navigation_test.dart`.
- `status=ACCEPTED` / `status=REFUSED` URL indicators were uppercase while the
  URL was lowercased before comparison, so they never matched.
- External host matching used `host.contains('cinetpay')`, which accepted
  `cinetpay.evil.com`. Now matches the registrable domain.
- `secure.cinetpay.co` and `checkout.cinetpay.co` were missing from
  `allowedOrigins`.

### Security

- **postMessage origin is now validated.** The injected bridge relayed messages
  from *any* origin to the app, so third-party content embedded in the checkout
  (operator redirects) could forge an `ACCEPTED` result. The origin is now
  checked in the injected script and re-checked on the Dart side against
  `allowedOrigins` — which existed but was unused.

### Added

- `statusChecker` / `statusPollInterval`: poll your backend for the
  authoritative payment status, mirroring the JavaScript SDK. Without it the SDK
  can only report a status inferred from the URL, with no amount or transaction
  id — such responses are now flagged via `PaymentResponse.dataAvailable`.
- `pendingIndicators`, so the gateway's `/pending` redirect triggers
  `onPaymentPending`.
- `PaymentStatus.isTerminal`.

### Changed

- Success and failure URLs are no longer blocked, so the checkout can render its
  own result page instead of freezing on a prevented navigation.

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
