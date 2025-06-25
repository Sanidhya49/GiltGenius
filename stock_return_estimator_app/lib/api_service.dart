import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> fetchPrediction({
    required String ticker,
    required String start,
    required String end,
    required List<String> features,
  }) async {
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ticker': ticker,
        'start': start,
        'end': end,
        'features': features,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch prediction: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> fetchTopGainers() async {
    final url = backendUrl.replaceAll('/predict', '/api/top_gainers');
    final response = await http.get(Uri.parse(url));
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
    final response = await http.get(Uri.parse(url));
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
}
