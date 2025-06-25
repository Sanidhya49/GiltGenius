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
}
