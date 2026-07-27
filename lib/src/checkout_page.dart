import 'dart:async';

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
/// The [paymentToken] must be obtained from your backend, and [environment]
/// must match the environment it was created on.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => CinetPayCheckoutPage(
///       paymentToken: 'abc123...',
///       environment: CinetPayEnvironment.production,
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
    this.environment = CinetPayEnvironment.sandbox,
    this.checkoutBaseUrl,
    this.statusChecker,
    this.statusPollInterval = const Duration(seconds: 3),
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
      environment: config.environment,
      checkoutBaseUrl: config.checkoutBaseUrl,
      statusChecker: config.statusChecker,
      statusPollInterval: config.statusPollInterval,
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

  /// The CinetPay environment the [paymentToken] was created on.
  final CinetPayEnvironment environment;

  /// Overrides the checkout host entirely, ignoring [environment].
  final String? checkoutBaseUrl;

  /// Optional authoritative payment status poller. See [PaymentStatusChecker].
  final PaymentStatusChecker? statusChecker;

  /// How often [statusChecker] is invoked. Clamped to a minimum of 1 second.
  final Duration statusPollInterval;

  /// Called when payment is accepted.
  final PaymentCallback? onPaymentSuccess;

  /// Called when payment is refused.
  final PaymentCallback? onPaymentFailed;

  /// Called when payment is pending.
  final PaymentCallback? onPaymentPending;

  /// Called when the checkout is closed by the user.
  ///
  /// Not called once a payment result has been dispatched.
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
  /// Minimum poll interval, to avoid hammering the merchant backend.
  static const Duration _minPollInterval = Duration(seconds: 1);

  bool _isLoading = true;
  bool _hasError = false;
  bool _paymentHandled = false;
  bool _closeNotified = false;
  bool _statusCheckInFlight = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _init() {
    final tokenError = TokenValidator.validate(widget.paymentToken);
    if (tokenError != null) {
      setState(() => _hasError = true);
      widget.onError?.call(tokenError);
      return;
    }

    _startStatusPolling();

    if (kIsWeb) {
      _openInBrowser();
    }
  }

  void _startStatusPolling() {
    if (widget.statusChecker == null || _statusTimer != null) return;
    final interval = widget.statusPollInterval < _minPollInterval
        ? _minPollInterval
        : widget.statusPollInterval;
    _statusTimer = Timer.periodic(interval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_paymentHandled || _statusCheckInFlight) return;
    final checker = widget.statusChecker;
    if (checker == null) return;

    _statusCheckInFlight = true;
    try {
      final payload = await checker();
      if (payload == null || !mounted) return;
      final response = PaymentResponse.fromJson(payload);
      if (response.status.isTerminal) {
        _handlePaymentResponse(response);
      }
    } catch (error) {
      widget.onError?.call(
        PaymentError(
          code: 'STATUS_CHECK_FAILED',
          message: 'Payment status check failed: $error',
        ),
      );
    } finally {
      _statusCheckInFlight = false;
    }
  }

  Future<void> _openInBrowser() async {
    final url = CinetPayConstants.checkoutUrl(
      widget.paymentToken,
      environment: widget.environment,
      baseUrl: widget.checkoutBaseUrl,
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _isLoading = false);
    } else {
      if (!mounted) return;
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
    _statusTimer?.cancel();

    switch (response.status) {
      case PaymentStatus.accepted:
        widget.onPaymentSuccess?.call(response);
      case PaymentStatus.refused:
        widget.onPaymentFailed?.call(response);
      default:
        widget.onPaymentPending?.call(response);
    }
  }

  /// Handles a status inferred from the checkout URL.
  ///
  /// The URL carries no payment data, so when a [PaymentStatusChecker] is
  /// configured we let it produce the authoritative response instead. Without
  /// one, we surface the status alone — amount and transaction id are unknown.
  void _handleUrlStatus(PaymentStatus status) {
    if (_paymentHandled) return;

    if (widget.statusChecker != null) {
      unawaited(_checkStatus());
      return;
    }

    _handlePaymentResponse(
      PaymentResponse(
        amount: 0,
        currency: '',
        status: status,
        paymentMethod: '',
        description: '',
        transactionId: '',
        dataAvailable: false,
      ),
    );
  }

  void _handleError(PaymentError error) {
    widget.onError?.call(error);
  }

  /// Notifies the host that the checkout was dismissed, exactly once.
  ///
  /// Never navigates: dismissal is owned by whoever pushed this page.
  void _notifyClosed() {
    if (_closeNotified || _paymentHandled) return;
    _closeNotified = true;
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _notifyClosed();
      },
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(widget.appBarTitle),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  // Pop only. `onClose` fires from PopScope above, so it is
                  // reported exactly once whether the user taps X or uses the
                  // system back gesture.
                  onPressed: () => Navigator.of(context).maybePop(),
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
                  onPressed: () => Navigator.of(context).maybePop(),
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
          environment: widget.environment,
          checkoutBaseUrl: widget.checkoutBaseUrl,
          backgroundColor: widget.backgroundColor,
          onPaymentResponse: _handlePaymentResponse,
          onUrlStatus: _handleUrlStatus,
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
