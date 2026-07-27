import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'constants.dart';
import 'models/payment_error.dart';
import 'models/payment_response.dart';
import 'models/payment_status.dart';

/// Builds the WebView widget for mobile platforms (Android/iOS).
Widget buildWebView({
  required String paymentToken,
  required CinetPayEnvironment environment,
  required String? checkoutBaseUrl,
  required Color backgroundColor,
  required void Function(PaymentResponse) onPaymentResponse,
  required void Function(PaymentStatus) onUrlStatus,
  required void Function(PaymentError) onError,
  required VoidCallback onPageStarted,
  required VoidCallback onPageFinished,
  required VoidCallback onWebResourceError,
}) {
  return _MobileWebView(
    paymentToken: paymentToken,
    environment: environment,
    checkoutBaseUrl: checkoutBaseUrl,
    backgroundColor: backgroundColor,
    onPaymentResponse: onPaymentResponse,
    onUrlStatus: onUrlStatus,
    onError: onError,
    onPageStarted: onPageStarted,
    onPageFinished: onPageFinished,
    onWebResourceError: onWebResourceError,
  );
}

class _MobileWebView extends StatefulWidget {
  const _MobileWebView({
    required this.paymentToken,
    required this.environment,
    required this.checkoutBaseUrl,
    required this.backgroundColor,
    required this.onPaymentResponse,
    required this.onUrlStatus,
    required this.onError,
    required this.onPageStarted,
    required this.onPageFinished,
    required this.onWebResourceError,
  });

  final String paymentToken;
  final CinetPayEnvironment environment;
  final String? checkoutBaseUrl;
  final Color backgroundColor;
  final void Function(PaymentResponse) onPaymentResponse;
  final void Function(PaymentStatus) onUrlStatus;
  final void Function(PaymentError) onError;
  final VoidCallback onPageStarted;
  final VoidCallback onPageFinished;
  final VoidCallback onWebResourceError;

  @override
  State<_MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<_MobileWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final checkoutUrl = CinetPayConstants.checkoutUrl(
      widget.paymentToken,
      environment: widget.environment,
      baseUrl: widget.checkoutBaseUrl,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onPageStarted(),
          onPageFinished: (_) {
            widget.onPageFinished();
            _controller.runJavaScript(_messageBridgeScript());
          },
          onWebResourceError: (_) => widget.onWebResourceError(),
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..addJavaScriptChannel(
        'CinetPayFlutter',
        onMessageReceived: (message) => _handleJsMessage(message.message),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  /// JavaScript injected into the checkout page to relay `postMessage` events.
  ///
  /// The origin check is the security boundary: the checkout page can embed
  /// third-party operator content, and without it any frame could forge an
  /// `ACCEPTED` payment result.
  String _messageBridgeScript() {
    final origins =
        CinetPayConstants.allowedOrigins.map((o) => "'$o'").join(',');
    return '''
      (function () {
        if (window.__cinetpayBridgeInstalled) return;
        window.__cinetpayBridgeInstalled = true;
        var allowed = [$origins];
        window.addEventListener('message', function (event) {
          if (allowed.indexOf(event.origin) === -1) return;
          if (!window.CinetPayFlutter) return;
          try {
            window.CinetPayFlutter.postMessage(JSON.stringify({
              origin: event.origin,
              data: event.data
            }));
          } catch (e) {}
        });
      })();
    ''';
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url.toLowerCase();

    final urlStatus = _statusFromUrl(url);
    if (urlStatus != null) {
      widget.onUrlStatus(urlStatus);
      // Let the page render the result — the merchant decides when to close.
      return NavigationDecision.navigate;
    }

    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    if (_isTrustedHost(uri)) return NavigationDecision.navigate;

    // Open external URLs (operator pages, bank 3-D Secure) in the browser.
    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  static PaymentStatus? _statusFromUrl(String lowercaseUrl) {
    for (final indicator in CinetPayConstants.successIndicators) {
      if (lowercaseUrl.contains(indicator)) return PaymentStatus.accepted;
    }
    for (final indicator in CinetPayConstants.failureIndicators) {
      if (lowercaseUrl.contains(indicator)) return PaymentStatus.refused;
    }
    for (final indicator in CinetPayConstants.pendingIndicators) {
      if (lowercaseUrl.contains(indicator)) return PaymentStatus.pending;
    }
    return null;
  }

  static bool _isTrustedHost(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1') return true;
    // Match the registrable domain, not a substring: `cinetpay.evil.com`
    // contains "cinetpay" but is not ours.
    return host == 'cinetpay.net' ||
        host == 'cinetpay.co' ||
        host == 'cinetpay.com' ||
        host.endsWith('.cinetpay.net') ||
        host.endsWith('.cinetpay.co') ||
        host.endsWith('.cinetpay.com');
  }

  void _handleJsMessage(String message) {
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(message) as Map<String, dynamic>;
    } catch (_) {
      return; // Not a bridge message.
    }

    // Re-check the origin on the Dart side: the injected script is the first
    // line of defence, this is the second.
    final origin = envelope['origin']?.toString();
    if (origin == null ||
        !CinetPayConstants.allowedOrigins.contains(origin)) {
      return;
    }

    final payload = envelope['data'];
    Map<String, dynamic>? data;
    if (payload is Map<String, dynamic>) {
      data = payload;
    } else if (payload is String) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {
        return;
      }
    }
    if (data == null) return;

    if (data.containsKey('status') || data.containsKey('cpm_status')) {
      widget.onPaymentResponse(PaymentResponse.fromJson(data));
    }

    if (data.containsKey('error') || data['code'] == 'ERROR') {
      widget.onError(PaymentError.fromJson(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
