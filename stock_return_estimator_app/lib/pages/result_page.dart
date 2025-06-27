import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../constants.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late String ticker, start, end;
  late List<String> features;
  bool isLoading = true;
  String? errorMsg;
  double? predictedReturn;
  List<double>? marketReturns;
  List<double>? strategyReturns;
  double? strategySummary, marketSummary, sharpe;
  List<String>? featuresUsed;
  Map<String, double>? shapValues;
  final modelNameController = TextEditingController();
  bool isSavingModel = false;
  String? loadedModelName;

  final Map<String, String> featureLabels = {
    'Return_Lag_1': '1-Day Return Lag',
    'Return_Lag_5': '5-Day Return Lag',
    'MA_10': '10-Day Moving Avg',
    'RSI_14': 'RSI (14)',
    'BBL_20': 'BB Lower (20)',
    'BBM_20': 'BB Middle (20)',
    'BBU_20': 'BB Upper (20)',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    ticker = args['ticker'];
    start = args['start'];
    end = args['end'];
    features = List<String>.from(args['features'] ?? []);
    loadedModelName = args['model_name'];
    fetchPrediction();
  }

  Future<void> fetchPrediction() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
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
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final d = data['data'];
          setState(() {
            predictedReturn = d['predicted_return']?.toDouble();
            marketReturns = List<double>.from(
              d['market_returns'].map((x) => x.toDouble()),
            );
            strategyReturns = List<double>.from(
              d['strategy_returns'].map((x) => x.toDouble()),
            );
            strategySummary = d['summary']['strategy']?.toDouble();
            marketSummary = d['summary']['market']?.toDouble();
            sharpe = d['summary']['sharpe']?.toDouble();
            featuresUsed = List<String>.from(d['features_used'] ?? []);
            if (d['shap_values'] != null) {
              shapValues = Map<String, double>.from(d['shap_values']);
            } else {
              shapValues = null;
            }
            isLoading = false;
          });
        } else {
          setState(() {
            errorMsg = data['message'] ?? 'Unknown error';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = 'Server error: \\${response.statusCode}';
          isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        errorMsg = 'Request timed out. The backend took too long to respond.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Failed to connect to backend.\\n$e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            "Prediction for $ticker",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white, // This will be replaced by the shader
              letterSpacing: 1.1,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: isLoading || errorMsg != null ? null : _shareResults,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: isLoading ? null : fetchPrediction,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? LinearGradient(
                  colors: [Color(0xFF181A20), Color(0xFF23242B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [Color(0xFFF8F9FF), Color(0xFFE3E6F3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMsg != null
              ? Center(
                  child: Text(
                    errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (loadedModelName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Currently loaded model: $loadedModelName',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Card(
                            color: Theme.of(
                              context,
                            ).cardColor.withOpacity(0.82),
                            elevation: 12,
                            margin: const EdgeInsets.only(bottom: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.18),
                                width: 1.2,
                              ),
                            ),
                            shadowColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.18),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ticker: $ticker',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Date Range: ${start.substring(0, 10)} to ${end.substring(0, 10)}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (featuresUsed != null &&
                                      featuresUsed!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Features: ' +
                                            featuresUsed!
                                                .map(
                                                  (f) => featureLabels[f] ?? f,
                                                )
                                                .join(', '),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 18),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    height: 4,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.0),
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.5),
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.0),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    "Predicted Next-Day Return: " +
                                        ((predictedReturn ?? 0) * 100)
                                            .toStringAsFixed(2) +
                                        "%",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _StatCard(
                                        icon: Icons.trending_up,
                                        label: "Strategy Return",
                                        value:
                                            (strategySummary?.toStringAsFixed(
                                                  2,
                                                ) ??
                                                '-') +
                                            "%",
                                        color: Colors.green[700],
                                      ),
                                      _StatCard(
                                        icon: Icons.show_chart,
                                        label: "Market Return",
                                        value:
                                            (marketSummary?.toStringAsFixed(
                                                  2,
                                                ) ??
                                                '-') +
                                            "%",
                                        color: Colors.blue[700],
                                      ),
                                      _StatCard(
                                        icon: Icons.balance,
                                        label: "Sharpe",
                                        value:
                                            (sharpe?.toStringAsFixed(2) ?? '-'),
                                        color: Colors.deepPurple[700],
                                      ),
                                    ],
                                  ),
                                  if (shapValues != null &&
                                      shapValues!.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        const Text(
                                          'Feature Impact (Explainable AI)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message:
                                              'Shows how much each feature contributed to the prediction. Positive = pushes return up, Negative = down.',
                                          child: Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: Colors.indigo[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _ShapBarChart(
                                      shapValues: shapValues!,
                                      featureLabels: featureLabels,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        "Cumulative Returns",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              if (marketReturns != null)
                                LineChartBarData(
                                  spots: List.generate(
                                    marketReturns!.length,
                                    (i) =>
                                        FlSpot(i.toDouble(), marketReturns![i]),
                                  ),
                                  isCurved: true,
                                  barWidth: 2,
                                  color: Colors.blue,
                                  dotData: FlDotData(show: false),
                                ),
                              if (strategyReturns != null)
                                LineChartBarData(
                                  spots: List.generate(
                                    strategyReturns!.length,
                                    (i) => FlSpot(
                                      i.toDouble(),
                                      strategyReturns![i],
                                    ),
                                  ),
                                  isCurved: true,
                                  barWidth: 2,
                                  color: Colors.green,
                                  dotData: FlDotData(show: false),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: Colors.green),
                          const SizedBox(width: 4),
                          const Text('Strategy'),
                          const SizedBox(width: 16),
                          _LegendDot(color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text('Market'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSaveModelSection(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Back"),
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSaveModelSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save Model',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: modelNameController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      hintText: 'e.g. my_ibm_model',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                isSavingModel
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Model'),
                        onPressed: _saveModel,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveModel() async {
    final name = modelNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => isSavingModel = true);
    final modelName = name.endsWith('.pkl') ? name : '$name.pkl';
    try {
      final response = await http.post(
        Uri.parse(backendUrl.replaceAll('/predict', '/save_model')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model_name': modelName}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Model saved as $modelName')));
        modelNameController.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save model')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving model')));
    }
    setState(() => isSavingModel = false);
  }

  void _shareResults() {
    final featuresStr = (featuresUsed ?? features)
        .map((f) => featureLabels[f] ?? f)
        .join(', ');
    final summary =
        'Stock: $ticker\nDate Range: ${start.substring(0, 10)} to ${end.substring(0, 10)}\nFeatures: $featuresStr\n' +
        'Predicted Next-Day Return: '
            '${((predictedReturn ?? 0) * 100).toStringAsFixed(2)}%\n' +
        'Strategy Return: ${strategySummary?.toStringAsFixed(2) ?? '-'}%\n' +
        'Market Return: ${marketSummary?.toStringAsFixed(2) ?? '-'}%\n' +
        'Sharpe: ${sharpe?.toStringAsFixed(2) ?? '-'}';
    Share.share(summary, subject: 'Stock Return Prediction for $ticker');
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color?.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, style: TextStyle(fontSize: 13, color: color)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ShapBarChart extends StatelessWidget {
  final Map<String, double> shapValues;
  final Map<String, String> featureLabels;
  const _ShapBarChart({required this.shapValues, required this.featureLabels});

  @override
  Widget build(BuildContext context) {
    final sorted = shapValues.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final maxVal = sorted.isNotEmpty
        ? sorted.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b)
        : 1.0;
    final barColor = (double v) =>
        v >= 0 ? Colors.green[400]! : Colors.red[400]!;
    return Column(
      children: [
        ...sorted.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    featureLabels[e.key] ?? e.key,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: e.value >= 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        widthFactor:
                            (e.value.abs() / (maxVal == 0 ? 1 : maxVal)).clamp(
                              0,
                              1,
                            ),
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: barColor(e.value),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  e.value.toStringAsFixed(3),
                  style: TextStyle(
                    color: barColor(e.value),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
