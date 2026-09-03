import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('StatusIndicator renders its label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatusIndicator(label: 'Connected', tone: StatusTone.positive),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('LoadingView shows a spinner and optional message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LoadingView(message: 'Checking connection…')),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Checking connection…'), findsOneWidget);
  });

  testWidgets('ErrorView shows the message and an optional retry button', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(
        ErrorView(message: 'No connection.', onRetry: () => retried = true),
      ),
    );

    expect(find.text('No connection.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('ErrorView without onRetry omits the retry button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ErrorView(message: 'No connection.')));

    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('EmptyView shows its message', (tester) async {
    await tester.pumpWidget(
      _wrap(const EmptyView(message: 'Nothing to show yet.')),
    );

    expect(find.text('Nothing to show yet.'), findsOneWidget);
  });
}
