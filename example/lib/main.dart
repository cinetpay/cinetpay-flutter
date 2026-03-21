import 'package:flutter/material.dart';
import 'package:cinetpay_flutter/cinetpay_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinetPay Demo',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE8530E),
        useMaterial3: true,
      ),
      home: const CheckoutPage(),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _tokenController = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _openCheckout() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _status = 'Collez un paymentToken');
      return;
    }

    CinetPay.show(
      context: context,
      paymentToken: token,
      onPaymentSuccess: (data) {
        setState(
          () => _status =
              'Paiement réussi ! ${data.amount} ${data.currency}',
        );
      },
      onPaymentFailed: (data) {
        setState(() => _status = 'Paiement refusé');
      },
      onPaymentPending: (data) {
        setState(
          () => _status = 'En attente... (${data.status.value})',
        );
      },
      onClose: () {
        setState(() {
          if (_status.isEmpty) _status = 'Checkout fermé';
        });
      },
      onError: (error) {
        setState(() => _status = 'Erreur: ${error.message}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CinetPay Flutter Demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Collez un paymentToken obtenu depuis votre backend',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Payment Token',
                border: OutlineInputBorder(),
                hintText: 'Obtenu via POST /v1/payment',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8530E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Payer maintenant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('réussi')
                      ? Colors.green.shade50
                      : _status.contains('refusé') ||
                              _status.contains('Erreur')
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
