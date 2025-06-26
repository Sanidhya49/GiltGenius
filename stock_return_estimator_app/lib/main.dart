import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/result_page.dart';
import 'pages/settings_page.dart';
import 'pages/top_gainers_page.dart';
import 'pages/backtest_page.dart';
import 'pages/portfolio_page.dart';
import 'pages/sentiment_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Return Estimator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/result': (context) => const ResultPage(),
        '/settings': (context) => const SettingsPage(),
        '/top_gainers': (context) => const TopGainersPage(),
        '/backtest': (context) => const BacktestPage(),
        '/portfolio': (context) => const PortfolioPage(),
        '/sentiment': (context) => const SentimentPage(),
      },
    );
  }
}
