import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';
import 'models/checkout_config.dart';
import 'models/payment_error.dart';
import 'models/payment_response.dart';
import 'models/payment_status.dart';
import 'utils/token_validator.dart';

// Conditional import for WebView (not available on web)
import 'checkout_webview_stub.dart'
    if (dart.library.io) 'checkout_webview_mobile.dart' as platform;

/// A full-screen checkout page that displays the CinetPay payment flow
/// in a WebView (mobile) or opens in browser (web).
///
/// On **Android/iOS**: displays the checkout in an embedded WebView.
/// On **Web**: opens the checkout in a new browser tab and shows a waiting screen.
///
/// The [paymentToken] must be obtained from your backend.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => CinetPayCheckoutPage(
///       paymentToken: 'abc123...',
///       onPaymentSuccess: (data) {
///         print('Paid ${data.amount} ${data.currency}');
///       },
///     ),
///   ),
/// );
/// ```
class CinetPayCheckoutPage extends StatefulWidget {
  /// Creates a CinetPay checkout page.
  const CinetPayCheckoutPage({
    required this.paymentToken,
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentPending,
    this.onClose,
    this.onError,
    this.appBarTitle = 'Paiement CinetPay',
    this.showAppBar = true,
    this.backgroundColor = Colors.white,
    super.key,
  });

  /// Creates a checkout page from a [CheckoutConfig].
  factory CinetPayCheckoutPage.fromConfig(
    CheckoutConfig config, {
    String appBarTitle = 'Paiement CinetPay',
    bool showAppBar = true,
  }) {
    return CinetPayCheckoutPage(
      paymentToken: config.paymentToken,
      onPaymentSuccess: config.onPaymentSuccess,
      onPaymentFailed: config.onPaymentFailed,
      onPaymentPending: config.onPaymentPending,
      onClose: config.onClose,
      onError: config.onError,
      appBarTitle: appBarTitle,
      showAppBar: showAppBar,
    );
  }

  /// The payment token obtained from the backend.
  final String paymentToken;

  /// Called when payment is accepted.
  final PaymentCallback? onPaymentSuccess;

  /// Called when payment is refused.
  final PaymentCallback? onPaymentFailed;

  /// Called when payment is pending.
  final PaymentCallback? onPaymentPending;

  /// Called when the checkout is closed.
  final CloseCallback? onClose;

  /// Called when an error occurs.
  final ErrorCallback? onError;

  /// Title shown in the app bar.
  final String appBarTitle;

  /// Whether to show the app bar. Defaults to `true`.
  final bool showAppBar;

  /// Background color of the page. Defaults to white.
  final Color backgroundColor;

  @override
  State<CinetPayCheckoutPage> createState() => _CinetPayCheckoutPageState();
}

class _CinetPayCheckoutPageState extends State<CinetPayCheckoutPage> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _paymentHandled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final tokenError = TokenValidator.validate(widget.paymentToken);
    if (tokenError != null) {
      setState(() => _hasError = true);
      widget.onError?.call(tokenError);
      return;
    }

    if (kIsWeb) {
      _openInBrowser();
    }
  }

  Future<void> _openInBrowser() async {
    final url = CinetPayConstants.checkoutUrl(widget.paymentToken);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _isLoading = false);
    } else {
      setState(() => _hasError = true);
      widget.onError?.call(
        const PaymentError(
          code: 'LAUNCH_FAILED',
          message: 'Impossible d\'ouvrir le navigateur.',
        ),
      );
    }
  }

  void _handlePaymentResponse(PaymentResponse response) {
    if (_paymentHandled) return;
    _paymentHandled = true;

    switch (response.status) {
      case PaymentStatus.accepted:
        widget.onPaymentSuccess?.call(response);
      case PaymentStatus.refused:
        widget.onPaymentFailed?.call(response);
      default:
        widget.onPaymentPending?.call(response);
    }
  }

  void _handleError(PaymentError error) {
    widget.onError?.call(error);
  }

  void _handleClose() {
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_paymentHandled) {
          widget.onClose?.call();
        }
      },
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(widget.appBarTitle),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.onClose?.call();
                    Navigator.of(context).pop();
                  },
                ),
              )
            : null,
        backgroundColor: widget.backgroundColor,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger la page de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Vérifiez votre connexion internet et réessayez.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                  });
                  _init();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // On web: show waiting screen (checkout opened in browser)
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) const CircularProgressIndicator(),
              if (!_isLoading) ...[
                const Icon(
                  Icons.open_in_new,
                  size: 64,
                  color: Color(0xFFE8530E),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paiement en cours...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Finalisez votre paiement dans la fenêtre\nqui vient de s\'ouvrir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    _handleClose();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // On mobile: show WebView
    return Stack(
      children: [
        platform.buildWebView(
          paymentToken: widget.paymentToken,
          backgroundColor: widget.backgroundColor,
          onPaymentResponse: _handlePaymentResponse,
          onError: _handleError,
          onPageStarted: () => setState(() => _isLoading = true),
          onPageFinished: () => setState(() => _isLoading = false),
          onWebResourceError: () {
            setState(() => _hasError = true);
            _handleError(
              const PaymentError(
                code: 'WEBVIEW_ERROR',
                message: 'Failed to load the payment page.',
              ),
            );
          },
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
