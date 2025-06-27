// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_return_estimator_app/main.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().window.physicalSizeTestValue =
        const Size(1200, 2000);
    TestWidgetsFlutterBinding.ensureInitialized()
            .window
            .devicePixelRatioTestValue =
        1.0;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().window
        .clearPhysicalSizeTestValue();
    TestWidgetsFlutterBinding.ensureInitialized().window
        .clearDevicePixelRatioTestValue();
  });

  group('App Integration Tests', () {
    testWidgets('Home page loads and shows main actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp());
      // Use a fixed duration pump to avoid hanging on unresolved async calls.
      await tester.pump(const Duration(seconds: 1));

      // Accept multiple GiltGenius widgets if present
      expect(find.text('GiltGenius'), findsWidgets);

      final sentimentFinder = find.text('Sentiment Analysis');
      final portfolioFinder = find.text('Portfolio Optimizer');
      final gainersFinder = find.textContaining('Top Gainers');

      await tester.ensureVisible(sentimentFinder);
      expect(sentimentFinder, findsOneWidget);
      await tester.ensureVisible(portfolioFinder);
      expect(portfolioFinder, findsOneWidget);
      await tester.ensureVisible(gainersFinder);
      expect(gainersFinder, findsOneWidget);
    });

    testWidgets('Navigate to Sentiment Analysis and back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp());
      // Use a fixed duration pump to avoid hanging on unresolved async calls.
      await tester.pump(const Duration(seconds: 1));
      final sentimentFinder = find.text('Sentiment Analysis');
      await tester.ensureVisible(sentimentFinder);
      await tester.tap(sentimentFinder);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Sentiment'), findsWidgets);
      // Robust pop for navigation back
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('GiltGenius'), findsWidgets);
    });

    testWidgets('Navigate to Portfolio Optimizer and back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp());
      // Use a fixed duration pump to avoid hanging on unresolved async calls.
      await tester.pump(const Duration(seconds: 1));
      final portfolioFinder = find.text('Portfolio Optimizer');
      await tester.ensureVisible(portfolioFinder);
      await tester.tap(portfolioFinder);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Portfolio'), findsWidgets);
      // Robust pop for navigation back
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('GiltGenius'), findsWidgets);
    });

    testWidgets('Navigate to Top Gainers & Losers and back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp());
      // Use a fixed duration pump to avoid hanging on unresolved async calls.
      await tester.pump(const Duration(seconds: 1));
      final gainersFinder = find.textContaining('Top Gainers');
      await tester.ensureVisible(gainersFinder);
      await tester.tap(gainersFinder);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Top Gainers'), findsWidgets);
      // Robust pop for navigation back
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('GiltGenius'), findsWidgets);
    });

    // Add more tests for prediction, backtest, and portfolio flows as needed.
  });
}
