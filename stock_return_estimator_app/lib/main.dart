import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/result_page.dart';
import 'pages/settings_page.dart';
import 'pages/top_gainers_page.dart';
import 'pages/backtest_page.dart';
import 'pages/portfolio_page.dart';
import 'pages/sentiment_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  if (savedTheme == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  } else {
    themeModeNotifier.value = ThemeMode.light;
  }
  runApp(MyApp());
}

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: const Color(0xFFF8F9FF),
    cardColor: Colors.indigo[50],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.indigo,
    ).copyWith(secondary: Colors.indigoAccent),
  );
  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: const Color(0xFF181A20),
    cardColor: const Color(0xFF23242B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF23242B),
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.indigo,
      secondary: Colors.indigoAccent,
      background: Color(0xFF181A20),
      surface: Color(0xFF23242B),
    ),
    dividerColor: Colors.grey[800],
    dialogBackgroundColor: const Color(0xFF23242B),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Color(0xFF23242B),
      filled: true,
      border: OutlineInputBorder(),
    ),
  );
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Stock Return Estimator',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/result': (context) => const ResultPage(),
            '/settings': (context) =>
                SettingsPage(themeModeNotifier: themeModeNotifier),
            '/topgainers': (context) => const TopGainersPage(),
            '/backtest': (context) => const BacktestPage(),
            '/portfolio': (context) => const PortfolioPage(),
            '/sentiment': (context) => const SentimentPage(),
          },
        );
      },
    );
  }
}
