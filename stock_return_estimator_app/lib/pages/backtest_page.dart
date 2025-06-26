import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import '../constants.dart';
import 'dart:async';

class BacktestPage extends StatefulWidget {
  const BacktestPage({super.key});

  @override
  State<BacktestPage> createState() => _BacktestPageState();
}

class _BacktestPageState extends State<BacktestPage> {
  late String ticker, start, end;
  late List<String> features;
  String? modelName;
  double threshold = 0.0;
  bool isLoading = false;
  String? errorMsg;
  Map<String, dynamic>? result;
  int holdingPeriod = 1;
  bool allowShort = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    ticker = args['ticker'];
    start = args['start'];
    end = args['end'];
    features = List<String>.from(args['features'] ?? []);
    modelName = args['model_name'];
  }

  Future<void> runBacktest() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final data = await ApiService.runBacktest(
        ticker: ticker,
        start: start,
        end: end,
        features: features,
        modelName: modelName,
        threshold: threshold,
        holdingPeriod: holdingPeriod,
        allowShort: allowShort,
      );
      if (data['status'] == 'success') {
        setState(() {
          result = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = data['message'] ?? 'Unknown error';
          isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        errorMsg = 'Request timed out. The backend took too long to respond.';
        isLoading = false;
      });
    } catch (e) {
      String msg = e.toString();
      // Try to extract backend error message if present
      final backendMsg = RegExp(
        r'No data available for this ticker and date range[^"\n]*',
      ).firstMatch(msg);
      if (backendMsg != null) {
        msg = backendMsg.group(0)!;
      } else if (msg.startsWith('Exception: ')) {
        msg = msg.replaceFirst('Exception: ', '');
      }
      setState(() {
        errorMsg = msg;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backtest: $ticker')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FF), Color(0xFFE3E6F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.indigo[50],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ticker: $ticker',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Date Range: ${start.substring(0, 10)} to ${end.substring(0, 10)}',
                        ),
                        if (features.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Features: ' +
                                  features
                                      .map((f) => featureLabels[f] ?? f)
                                      .join(', '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        if (modelName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Model: $modelName',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text(
                          'Threshold:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Tooltip(
                          message:
                              'The minimum predicted return (%) required to trigger a Buy.\n\n' +
                              '• If the model predicts a return above this value, the strategy buys.\n' +
                              '• Lower threshold = more trades, higher = fewer, more selective trades.\n' +
                              '• Example: 0.01 = 1% predicted return. Most daily returns are between -5% and +5%.',
                          child: Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.indigo[400],
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: threshold,
                            min: -0.05,
                            max: 0.05,
                            divisions: 20,
                            label: threshold.toStringAsFixed(3),
                            onChanged: (v) => setState(() => threshold = v),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            threshold.toStringAsFixed(3),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Holding Period:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'How many days to hold after a Buy signal.\n\n' +
                                  'E.g., 1 = sell next day, 3 = hold for 3 days after buying.',
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.indigo[400],
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: holdingPeriod.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                label: holdingPeriod.toString(),
                                onChanged: (v) =>
                                    setState(() => holdingPeriod = v.round()),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$holdingPeriod d',
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Allow Shorting',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'If enabled, the strategy will also sell/short when the predicted return is below -threshold.\n\n' +
                                  'Shorting means profiting from price drops. Use with caution!',
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.indigo[400],
                              ),
                            ),
                            Switch(
                              value: allowShort,
                              onChanged: (v) => setState(() => allowShort = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text('Run Backtest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading ? null : runBacktest,
                ),
                const SizedBox(height: 16),
                if (isLoading) const Center(child: CircularProgressIndicator()),
                if (errorMsg != null)
                  Center(
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (result != null) ...[
                  _BacktestSummary(result: result!),
                  const SizedBox(height: 12),
                  _BacktestChart(result: result!),
                  const SizedBox(height: 12),
                  _BacktestTable(result: result!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BacktestSummary extends StatelessWidget {
  final Map<String, dynamic> result;
  const _BacktestSummary({required this.result});
  @override
  Widget build(BuildContext context) {
    final summary = result['summary'] ?? {};
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SummaryStat(
                label: 'Strategy Return',
                value: '${summary['strategy_return']}%',
              ),
              _SummaryStat(
                label: 'Market Return',
                value: '${summary['market_return']}%',
              ),
              _SummaryStat(
                label: 'Sharpe',
                value: summary['sharpe'].toString(),
              ),
              _SummaryStat(
                label: 'Trades',
                value: summary['trades'].toString(),
              ),
              _SummaryStat(label: 'Win Rate', value: '${summary['win_rate']}%'),
              _SummaryStat(
                label: 'Max Drawdown',
                value: '${summary['max_drawdown']}%',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}

class _BacktestChart extends StatelessWidget {
  final Map<String, dynamic> result;
  const _BacktestChart({required this.result});
  @override
  Widget build(BuildContext context) {
    final market = List<double>.from(result['cumulative_market'] ?? []);
    final strategy = List<double>.from(result['cumulative_strategy'] ?? []);
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cumulative Returns',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        market.length,
                        (i) => FlSpot(i.toDouble(), market[i]),
                      ),
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        strategy.length,
                        (i) => FlSpot(i.toDouble(), strategy[i]),
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

class _BacktestTable extends StatelessWidget {
  final Map<String, dynamic> result;
  const _BacktestTable({required this.result});
  @override
  Widget build(BuildContext context) {
    final dates = List<String>.from(result['dates'] ?? []);
    final signals = List<int>.from(result['signals'] ?? []);
    final pred = List<double>.from(result['predicted_returns'] ?? []);
    final actual = List<double>.from(result['actual_returns'] ?? []);
    final strat = List<double>.from(result['strategy_returns'] ?? []);
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trade Log',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ListView.builder(
              itemCount: dates.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                    color: i % 2 == 0 ? Colors.grey[50] : Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            dates[i],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              signals[i] == 1 ? 'Buy' : '-',
                              style: TextStyle(
                                color: signals[i] == 1
                                    ? Colors.green[700]
                                    : Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            pred[i].toStringAsFixed(4),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            actual[i].toStringAsFixed(4),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            strat[i].toStringAsFixed(4),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      'Signal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Pred',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Actual',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Strat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
