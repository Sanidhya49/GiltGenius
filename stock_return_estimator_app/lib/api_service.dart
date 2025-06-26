import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'dart:async';

class ApiService {
  static Future<Map<String, dynamic>> fetchPrediction({
    required String ticker,
    required String start,
    required String end,
    required List<String> features,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ticker': ticker,
              'start': start,
              'end': end,
              'features': features,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch prediction: \\${response.statusCode}');
      }
    } on TimeoutException {
      rethrow;
    }
  }

  static Future<List<dynamic>> fetchTopGainers() async {
    final url = backendUrl.replaceAll('/predict', '/api/top_gainers');
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch top gainers: \\${data['message']}');
      }
    } else {
      throw Exception('Failed to fetch top gainers: \\${response.statusCode}');
    }
  }

  static Future<List<dynamic>> fetchTopLosers() async {
    final url = backendUrl.replaceAll('/predict', '/api/top_losers');
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch top losers: \\${data['message']}');
      }
    } else {
      throw Exception('Failed to fetch top losers: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> runBacktest({
    required String ticker,
    required String start,
    required String end,
    required List<String> features,
    String? modelName,
    double threshold = 0.0,
    int? holdingPeriod,
    bool? allowShort,
  }) async {
    try {
      final url = backendUrl.replaceAll('/predict', '/backtest');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ticker': ticker,
              'start': start,
              'end': end,
              'features': features,
              if (modelName != null) 'model_name': modelName,
              'threshold': threshold,
              if (holdingPeriod != null) 'holding_period': holdingPeriod,
              if (allowShort != null) 'allow_short': allowShort,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message':
              data['message'] ??
              'Failed to run backtest: \\${response.statusCode}',
        };
      }
    } on TimeoutException {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> optimizePortfolio({
    required List<String> tickers,
    required List<double> quantities,
    double riskFreeRate = 0.02,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(backendUrl.replaceAll('/predict', '/optimize_portfolio')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tickers': tickers,
              'quantities': quantities,
              'risk_free_rate': riskFreeRate,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Portfolio optimization failed');
        }
      } else {
        // Try to parse backend error message for user-facing errors
        try {
          final data = jsonDecode(response.body);
          throw Exception(
            data['message'] ??
                'Failed to optimize portfolio: ${response.statusCode}',
          );
        } catch (_) {
          throw Exception(
            'Failed to optimize portfolio: ${response.statusCode}',
          );
        }
      }
    } on TimeoutException {
      rethrow;
    }
  }
}
