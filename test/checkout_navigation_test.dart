import 'package:cinetpay_flutter_sdk/cinetpay_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Navigation regression tests.
///
/// These use a deliberately invalid payment token so that the checkout page
/// renders its error state instead of a WebView (which has no implementation
/// in the test environment).
void main() {
  group('bottom sheet close', () {
    testWidgets('closing the sheet keeps the merchant page on screen',
        (tester) async {
      late BuildContext pageContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: Text('MERCHANT_PAGE'));
            },
          ),
        ),
      );

      expect(find.text('MERCHANT_PAGE'), findsOneWidget);

      showCinetPayBottomSheet(
        context: pageContext,
        paymentToken: 'invalid',
      );
      await tester.pumpAndSettle();

      // The checkout page rendered its error state inside the sheet.
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // The sheet must be gone...
      expect(find.byIcon(Icons.close), findsNothing);
      // ...and the merchant page must still be there.
      expect(find.text('MERCHANT_PAGE'), findsOneWidget);
    });

    testWidgets('onClose is invoked exactly once when closing via the X button',
        (tester) async {
      late BuildContext pageContext;
      var closeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: Text('MERCHANT_PAGE'));
            },
          ),
        ),
      );

      showCinetPayBottomSheet(
        context: pageContext,
        paymentToken: 'invalid',
        onClose: () => closeCount++,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closeCount, 1);
    });
  });
}
