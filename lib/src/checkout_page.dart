import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'constants.dart';
import 'models/checkout_config.dart';
import 'models/payment_error.dart';
import 'models/payment_response.dart';
import 'models/payment_status.dart';
import 'utils/token_validator.dart';

/// A full-screen checkout page that displays the CinetPay payment flow
/// inside a WebView.
///
/// The [paymentToken] must be obtained from your backend by calling the
/// CinetPay API (`POST /v1/payment`). This widget loads
/// `https://secure.cinetpay.net/checkout/{paymentToken}` and listens for
/// payment results via JavaScript postMessage and URL navigation interception.
///
/// ## Usage
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => CinetPayCheckoutPage(
///       paymentToken: 'abc123def456...',
///       onPaymentSuccess: (data) {
///         print('Payment succeeded: ${data.transactionId}');
///       },
///       onPaymentFailed: (data) {
///         print('Payment failed: ${data.status}');
///       },
///       onClose: () => Navigator.pop(context),
///     ),
///   ),
/// );
/// ```
class CinetPayCheckoutPage extends StatefulWidget {
  /// Creates a [CinetPayCheckoutPage].
  const CinetPayCheckoutPage({
    super.key,
    required this.paymentToken,
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentPending,
    this.onClose,
    this.onError,
    this.appBarTitle = 'Paiement CinetPay',
    this.showAppBar = true,
    this.backgroundColor = Colors.white,
  });

  /// Creates a [CinetPayCheckoutPage] from a [CheckoutConfig].
  factory CinetPayCheckoutPage.fromConfig({
    Key? key,
    required CheckoutConfig config,
    String appBarTitle = 'Paiement CinetPay',
    bool showAppBar = true,
    Color backgroundColor = Colors.white,
  }) {
    return CinetPayCheckoutPage(
      key: key,
      paymentToken: config.paymentToken,
      onPaymentSuccess: config.onPaymentSuccess,
      onPaymentFailed: config.onPaymentFailed,
      onPaymentPending: config.onPaymentPending,
      onClose: config.onClose,
      onError: config.onError,
      appBarTitle: appBarTitle,
      showAppBar: showAppBar,
      backgroundColor: backgroundColor,
    );
  }

  /// The payment token obtained from your backend.
  final String paymentToken;

  /// Called when the payment is accepted.
  final PaymentCallback? onPaymentSuccess;

  /// Called when the payment is refused.
  final PaymentCallback? onPaymentFailed;

  /// Called when the payment is pending.
  final PaymentCallback? onPaymentPending;

  /// Called when the checkout page is closed.
  final CloseCallback? onClose;

  /// Called when a technical error occurs.
  final ErrorCallback? onError;

  /// Title displayed in the app bar.
  final String appBarTitle;

  /// Whether to show the app bar. Defaults to `true`.
  final bool showAppBar;

  /// Background color of the page. Defaults to white.
  final Color backgroundColor;

  @override
  State<CinetPayCheckoutPage> createState() => _CinetPayCheckoutPageState();
}

class _CinetPayCheckoutPageState extends State<CinetPayCheckoutPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _paymentHandled = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Validate token first
    final tokenError = TokenValidator.validate(widget.paymentToken);
    if (tokenError != null) {
      _hasError = true;
      widget.onError?.call(tokenError);
      return;
    }

    final checkoutUrl =
        CinetPayConstants.checkoutUrl(widget.paymentToken);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _injectMessageListener();
          },
          onNavigationRequest: (request) =>
              _handleNavigation(request),
          onWebResourceError: (error) {
            if (kDebugMode) {
              print('[CinetPay] WebView error: ${error.description}');
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
            widget.onError?.call(
              PaymentError(
                code: 'WEBVIEW_ERROR',
                message: error.description,
              ),
            );
          },
        ),
      )
      ..addJavaScriptChannel(
        'CinetPayFlutter',
        onMessageReceived: _handleJavaScriptMessage,
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  /// Injects a script that forwards postMessage events to the Flutter channel.
  void _injectMessageListener() {
    _controller.runJavaScript('''
      (function() {
        if (window._cinetPayListenerInjected) return;
        window._cinetPayListenerInjected = true;
        window.addEventListener('message', function(event) {
          try {
            var data = typeof event.data === 'string'
              ? JSON.parse(event.data)
              : event.data;
            if (data && typeof data === 'object' && (data.status || data.error || data.action)) {
              if (window.CinetPayFlutter) {
                CinetPayFlutter.postMessage(JSON.stringify(data));
              }
            }
          } catch(e) {}
        });
      })();
    ''');
  }

  /// Handles JavaScript messages forwarded from the checkout page.
  void _handleJavaScriptMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message);
      if (data is! Map<String, dynamic>) return;

      // Handle payment status
      if (data.containsKey('status')) {
        final response = PaymentResponse.fromJson(data);
        _dispatchResponse(response);
      }

      // Handle errors
      if (data.containsKey('error') || data['code'] == 'ERROR') {
        final error = PaymentError.fromJson(data);
        widget.onError?.call(error);
      }

      // Handle close action
      if (data['action'] == 'CLOSE' || data['type'] == 'close') {
        _handleClose();
      }
    } catch (_) {
      // Ignore non-JSON messages
    }
  }

  /// Intercepts navigation to detect success/failure redirects.
  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url.toLowerCase();

    // Check for success indicators
    for (final indicator in CinetPayConstants.successIndicators) {
      if (url.contains(indicator.toLowerCase())) {
        _dispatchResponse(
          PaymentResponse(
            amount: 0,
            currency: '',
            status: PaymentStatus.accepted,
            paymentMethod: '',
            description: '',
            transactionId: _extractParam(request.url, 'transaction_id'),
          ),
        );
        return NavigationDecision.prevent;
      }
    }

    // Check for failure indicators
    for (final indicator in CinetPayConstants.failureIndicators) {
      if (url.contains(indicator.toLowerCase())) {
        _dispatchResponse(
          PaymentResponse(
            amount: 0,
            currency: '',
            status: PaymentStatus.refused,
            paymentMethod: '',
            description: '',
            transactionId: _extractParam(request.url, 'transaction_id'),
          ),
        );
        return NavigationDecision.prevent;
      }
    }

    // Allow navigation within CinetPay domains
    final uri = Uri.tryParse(request.url);
    if (uri != null) {
      final host = uri.host;
      if (host.endsWith('cinetpay.net') ||
          host.endsWith('cinetpay.com') ||
          host.endsWith('cinetpay.co')) {
        return NavigationDecision.navigate;
      }
    }

    // For external URLs, open in the system browser
    _launchExternalUrl(request.url);
    return NavigationDecision.prevent;
  }

  /// Dispatches the payment response to the appropriate callback.
  void _dispatchResponse(PaymentResponse response) {
    if (_paymentHandled) return;
    _paymentHandled = true;

    switch (response.status) {
      case PaymentStatus.accepted:
        widget.onPaymentSuccess?.call(response);
        break;
      case PaymentStatus.refused:
        widget.onPaymentFailed?.call(response);
        break;
      case PaymentStatus.pending:
      case PaymentStatus.initiated:
      case PaymentStatus.expired:
      case PaymentStatus.unknown:
        widget.onPaymentPending?.call(response);
        break;
    }
  }

  /// Extracts a query parameter from a URL string.
  String _extractParam(String url, String param) {
    final uri = Uri.tryParse(url);
    return uri?.queryParameters[param] ?? '';
  }

  /// Opens an external URL in the system browser.
  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                'Unable to load payment page',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection and try again.',
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
                  _controller.loadRequest(
                    Uri.parse(
                      CinetPayConstants.checkoutUrl(
                        widget.paymentToken,
                      ),
                    ),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
