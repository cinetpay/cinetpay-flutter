import 'package:flutter/material.dart';
import 'package:cinetpay_flutter/cinetpay_flutter.dart';

void main() {
  runApp(const CinetPayExampleApp());
}

/// Example app demonstrating the three ways to use the CinetPay Flutter SDK.
class CinetPayExampleApp extends StatelessWidget {
  const CinetPayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinetPay Flutter Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00A651),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Replace this with the payment token obtained from your backend.
  ///
  /// Your backend should call the CinetPay API (POST /v1/payment) using
  /// one of the server-side SDKs (cinetpay-js, cinetpay-python, cinetpay-go)
  /// and return the token to the mobile app.
  final String _paymentToken = 'YOUR_PAYMENT_TOKEN_HERE';

  String _lastResult = 'No payment yet';

  void _onPaymentSuccess(PaymentResponse data) {
    setState(() {
      _lastResult = 'Payment ACCEPTED\n'
          'Amount: ${data.amount} ${data.currency}\n'
          'Transaction: ${data.transactionId}\n'
          'Method: ${data.paymentMethod}';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment succeeded: ${data.transactionId}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onPaymentFailed(PaymentResponse data) {
    setState(() {
      _lastResult = 'Payment REFUSED\n'
          'Status: ${data.status.value}\n'
          'Transaction: ${data.transactionId}';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${data.status.value}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPaymentPending(PaymentResponse data) {
    setState(() {
      _lastResult = 'Payment PENDING\n'
          'Status: ${data.status.value}\n'
          'Transaction: ${data.transactionId}';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment pending: ${data.status.value}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onClose() {
    debugPrint('Checkout closed');
  }

  void _onError(PaymentError error) {
    setState(() {
      _lastResult = 'Error: ${error.code}\n${error.message}';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CinetPay Flutter SDK'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Last result card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Result',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastResult,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Method 1: Bottom sheet (recommended)
            const Text(
              'Method 1: Bottom Sheet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                CinetPay.show(
                  context: context,
                  paymentToken: _paymentToken,
                  onPaymentSuccess: _onPaymentSuccess,
                  onPaymentFailed: _onPaymentFailed,
                  onPaymentPending: _onPaymentPending,
                  onClose: _onClose,
                  onError: _onError,
                );
              },
              child: const Text('Pay with Bottom Sheet'),
            ),
            const SizedBox(height: 24),

            // Method 2: Full-screen page
            const Text(
              'Method 2: Full-Screen Page',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CinetPayCheckoutPage(
                      paymentToken: _paymentToken,
                      onPaymentSuccess: (data) {
                        _onPaymentSuccess(data);
                        Navigator.pop(context);
                      },
                      onPaymentFailed: (data) {
                        _onPaymentFailed(data);
                        Navigator.pop(context);
                      },
                      onPaymentPending: (data) {
                        _onPaymentPending(data);
                        Navigator.pop(context);
                      },
                      onClose: () => Navigator.pop(context),
                      onError: _onError,
                    ),
                  ),
                );
              },
              child: const Text('Pay with Full-Screen Page'),
            ),
            const SizedBox(height: 24),

            // Method 3: CinetPayButton widget
            const Text(
              'Method 3: CinetPayButton Widget',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            CinetPayButton(
              paymentToken: _paymentToken,
              text: 'Payer 5000 XOF',
              onPaymentSuccess: _onPaymentSuccess,
              onPaymentFailed: _onPaymentFailed,
              onPaymentPending: _onPaymentPending,
              onClose: _onClose,
              onError: _onError,
            ),
            const SizedBox(height: 8),
            CinetPayButton(
              paymentToken: _paymentToken,
              text: 'Pay with Icon',
              icon: const Icon(Icons.payment),
              onPaymentSuccess: _onPaymentSuccess,
              onPaymentFailed: _onPaymentFailed,
              onError: _onError,
            ),
            const SizedBox(height: 24),

            // Fallback: External browser
            const Text(
              'Fallback: External Browser',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                CinetPay.openInBrowser(
                  paymentToken: _paymentToken,
                  onError: _onError,
                );
              },
              child: const Text('Open in Browser'),
            ),
          ],
        ),
      ),
    );
  }
}
