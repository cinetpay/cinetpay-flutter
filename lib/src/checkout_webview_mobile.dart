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
  required Color backgroundColor,
  required void Function(PaymentResponse) onPaymentResponse,
  required void Function(PaymentError) onError,
  required VoidCallback onPageStarted,
  required VoidCallback onPageFinished,
  required VoidCallback onWebResourceError,
}) {
  return _MobileWebView(
    paymentToken: paymentToken,
    backgroundColor: backgroundColor,
    onPaymentResponse: onPaymentResponse,
    onError: onError,
    onPageStarted: onPageStarted,
    onPageFinished: onPageFinished,
    onWebResourceError: onWebResourceError,
  );
}

class _MobileWebView extends StatefulWidget {
  const _MobileWebView({
    required this.paymentToken,
    required this.backgroundColor,
    required this.onPaymentResponse,
    required this.onError,
    required this.onPageStarted,
    required this.onPageFinished,
    required this.onWebResourceError,
  });

  final String paymentToken;
  final Color backgroundColor;
  final void Function(PaymentResponse) onPaymentResponse;
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
    final checkoutUrl =
        CinetPayConstants.checkoutUrl(widget.paymentToken);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onPageStarted(),
          onPageFinished: (_) {
            widget.onPageFinished();
            // Inject JS listener for postMessage from CinetPay
            _controller.runJavaScript('''
              window.addEventListener('message', function(event) {
                if (window.CinetPayFlutter) {
                  window.CinetPayFlutter.postMessage(
                    JSON.stringify(event.data)
                  );
                }
              });
            ''');
          },
          onWebResourceError: (_) => widget.onWebResourceError(),
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            // Check for success/failure URL patterns
            for (final indicator in CinetPayConstants.successIndicators) {
              if (url.contains(indicator)) {
                widget.onPaymentResponse(
                  const PaymentResponse(
                    amount: 0,
                    currency: '',
                    status: PaymentStatus.accepted,
                    paymentMethod: '',
                    description: '',
                    transactionId: '',
                  ),
                );
                return NavigationDecision.prevent;
              }
            }
            for (final indicator in CinetPayConstants.failureIndicators) {
              if (url.contains(indicator)) {
                widget.onPaymentResponse(
                  const PaymentResponse(
                    amount: 0,
                    currency: '',
                    status: PaymentStatus.refused,
                    paymentMethod: '',
                    description: '',
                    transactionId: '',
                  ),
                );
                return NavigationDecision.prevent;
              }
            }

            // Allow CinetPay domains
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              final host = uri.host;
              if (host.contains('cinetpay') ||
                  host == 'localhost' ||
                  host == '127.0.0.1') {
                return NavigationDecision.navigate;
              }
              // Open external URLs in system browser
              launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'CinetPayFlutter',
        onMessageReceived: (message) {
          _handleJsMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  void _handleJsMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;

      if (data.containsKey('status')) {
        final response = PaymentResponse.fromJson(data);
        widget.onPaymentResponse(response);
      }

      if (data.containsKey('error') || data['code'] == 'ERROR') {
        widget.onError(PaymentError.fromJson(data));
      }
    } catch (_) {
      // Ignore non-JSON messages
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
