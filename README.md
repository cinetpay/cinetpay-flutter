# CinetPay Flutter SDK

Flutter SDK for CinetPay payments. Opens the CinetPay checkout page in a WebView and reports the payment result back to your app.

This is a **frontend-only** SDK. The payment must be initialized on your backend first (using [cinetpay-js](https://github.com/cinetpay/cinetpay-js), [cinetpay-python](https://github.com/cinetpay/cinetpay-python), [cinetpay-go](https://github.com/cinetpay/cinetpay-go), or any backend), which returns a `paymentToken`. The Flutter SDK then opens `https://secure.cinetpay.net/checkout/{paymentToken}` in a WebView.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  cinetpay_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Configuration par plateforme

#### Android

Ajoutez la permission internet dans `android/app/src/main/AndroidManifest.xml` :

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <!-- ... -->
</manifest>
```

Vérifiez que le `minSdkVersion` est au moins **19** dans `android/app/build.gradle` :

```groovy
android {
    defaultConfig {
        minSdkVersion 19
    }
}
```

#### iOS

Ajoutez les schémas d'URL dans `ios/Runner/Info.plist` pour le fallback navigateur (`url_launcher`) :

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>https</string>
    <string>http</string>
</array>
```

Vérifiez que la version minimale est **12.0** dans `ios/Podfile` :

```ruby
platform :ios, '12.0'
```

## Usage

### 1. Initialize payment on your backend

Your backend calls the CinetPay API (`POST /v1/payment`) and returns a `paymentToken` to the mobile app. This step is **not** handled by this SDK.

```
App  -->  Your Backend  -->  CinetPay API
App  <--  paymentToken  <--  Your Backend
```

### 2. Open the checkout in your Flutter app

Import the SDK:

```dart
import 'package:cinetpay_flutter/cinetpay_flutter.dart';
```

#### Method 1: Bottom sheet (recommended)

```dart
CinetPay.show(
  context: context,
  paymentToken: 'abc123def456...',
  onPaymentSuccess: (data) {
    print('Paid ${data.amount} ${data.currency}');
    print('Transaction ID: ${data.transactionId}');
  },
  onPaymentFailed: (data) {
    print('Payment refused');
  },
  onPaymentPending: (data) {
    print('Payment pending: ${data.status.value}');
  },
  onClose: () {
    print('Checkout closed');
  },
  onError: (error) {
    print('Error: ${error.code} - ${error.message}');
  },
);
```

#### Method 2: Full-screen page

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CinetPayCheckoutPage(
      paymentToken: 'abc123def456...',
      onPaymentSuccess: (data) {
        Navigator.pop(context);
        // Handle success
      },
      onPaymentFailed: (data) {
        Navigator.pop(context);
        // Handle failure
      },
      onClose: () => Navigator.pop(context),
    ),
  ),
);
```

#### Method 3: Pre-styled button

```dart
CinetPayButton(
  paymentToken: 'abc123def456...',
  text: 'Payer 5000 XOF',
  onPaymentSuccess: (data) { ... },
  onPaymentFailed: (data) { ... },
)
```

With a custom icon:

```dart
CinetPayButton(
  paymentToken: token,
  text: 'Pay now',
  icon: Icon(Icons.payment),
  onPaymentSuccess: (data) { ... },
)
```

With custom styling:

```dart
CinetPayButton(
  paymentToken: token,
  text: 'Confirm Payment',
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  ),
  onPaymentSuccess: (data) { ... },
)
```

#### Fallback: External browser

If WebView is not suitable, you can open the checkout in the system browser. Note that callbacks will NOT work in this mode; rely on your backend webhook instead.

```dart
await CinetPay.openInBrowser(
  paymentToken: 'abc123def456...',
  onError: (error) => print(error.message),
);
```

### Using CheckoutConfig

For reuse, you can create a `CheckoutConfig` object:

```dart
final config = CheckoutConfig(
  paymentToken: token,
  onPaymentSuccess: (data) { ... },
  onPaymentFailed: (data) { ... },
  onClose: () { ... },
);

// Use with show()
CinetPay.showFromConfig(context: context, config: config);

// Or with the button
CinetPayButton.fromConfig(config: config, text: 'Pay');

// Or with the full-screen page
CinetPayCheckoutPage.fromConfig(config: config);
```

## API Reference

### CinetPay

| Method | Description |
|--------|-------------|
| `CinetPay.show()` | Opens checkout as a bottom sheet |
| `CinetPay.showFromConfig()` | Opens checkout from a CheckoutConfig |
| `CinetPay.openInBrowser()` | Opens checkout in external browser (fallback) |

### Callbacks

| Callback | Type | Description |
|----------|------|-------------|
| `onPaymentSuccess` | `PaymentResponse` | Payment accepted |
| `onPaymentFailed` | `PaymentResponse` | Payment refused |
| `onPaymentPending` | `PaymentResponse` | Payment pending (PENDING, INITIATED, EXPIRED) |
| `onClose` | `void` | Checkout closed |
| `onError` | `PaymentError` | Technical error |

### PaymentResponse

| Field | Type | Description |
|-------|------|-------------|
| `amount` | `num` | Amount paid |
| `currency` | `String` | Currency code (XOF, XAF, etc.) |
| `status` | `PaymentStatus` | Payment status enum |
| `paymentMethod` | `String` | Method code (OM, MOMO, WAVE, VISA, etc.) |
| `description` | `String` | Payment description |
| `transactionId` | `String` | CinetPay transaction ID |
| `metadata` | `String?` | Custom metadata |
| `operatorId` | `String?` | Operator transaction ID |
| `paymentDate` | `String?` | Payment date |

### PaymentStatus

| Value | Description |
|-------|-------------|
| `PaymentStatus.accepted` | Payment confirmed |
| `PaymentStatus.refused` | Payment refused |
| `PaymentStatus.pending` | Pending confirmation |
| `PaymentStatus.initiated` | Initiated, not confirmed |
| `PaymentStatus.expired` | Payment expired |
| `PaymentStatus.unknown` | Unknown status |

Helper methods: `isSuccess`, `isFailed`, `isPending`.

### PaymentError

| Field | Type | Description |
|-------|------|-------------|
| `code` | `String` | Error code (INVALID_TOKEN, WEBVIEW_ERROR, etc.) |
| `message` | `String` | Human-readable message |

### Token Validation

Tokens are validated automatically. You can also validate manually:

```dart
if (TokenValidator.isValid(token)) {
  // Token format is correct
}

final error = TokenValidator.validate(token);
if (error != null) {
  print(error.message);
}
```

## How It Works

1. Your backend initializes a payment via the CinetPay API and returns a `paymentToken`.
2. The Flutter SDK opens `https://secure.cinetpay.net/checkout/{paymentToken}` in a WebView.
3. The user completes the payment on the CinetPay checkout page.
4. The SDK detects the payment result via:
   - **JavaScript postMessage**: The checkout page sends a message with the payment status.
   - **URL interception**: The SDK intercepts navigation to success/failure URLs.
5. The appropriate callback is invoked with a `PaymentResponse`.

## Supported Countries

Burkina Faso, Benin, DR Congo, Ivory Coast, Cameroon, Guinea, Guinea-Bissau, Mali, Niger, Senegal, Togo.

## Requirements

- Flutter 3.10+
- Dart 3.0+
- Android: minSdkVersion 19+
- iOS: 12.0+

## License

MIT License. See [LICENSE](LICENSE) for details.
