import 'package:flutter/material.dart';
import '../models/portfolio.dart';
import '../api_service.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});
  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final List<Holding> holdings = [];
  final tickerController = TextEditingController();
  final quantityController = TextEditingController();
  bool isLoading = false;
  String? errorMsg;
  Map<String, dynamic>? optimizationResult;

  void addHolding() {
    final ticker = tickerController.text.trim().toUpperCase();
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0.0;
    if (ticker.isEmpty || quantity <= 0) return;
    setState(() {
      holdings.add(Holding(ticker: ticker, quantity: quantity));
      tickerController.clear();
      quantityController.clear();
    });
  }

  void removeHolding(int index) {
    setState(() {
      holdings.removeAt(index);
    });
  }

  Future<void> optimize() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      optimizationResult = null;
    });
    try {
      final result = await ApiService.optimizePortfolio(
        tickers: holdings.map((h) => h.ticker).toList(),
        quantities: holdings.map((h) => h.quantity).toList(),
      );
      setState(() {
        optimizationResult = result;
        isLoading = false;
      });
    } catch (e) {
      String msg = e.toString();
      // Try to extract backend error message
      if (msg.contains('Exception:')) {
        msg = msg.split('Exception:').last.trim();
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
      appBar: AppBar(title: const Text('Portfolio Optimizer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tickerController,
                    decoration: const InputDecoration(labelText: 'Ticker'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: addHolding),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: holdings.length,
                itemBuilder: (context, i) {
                  final h = holdings[i];
                  return ListTile(
                    title: Text(h.ticker),
                    subtitle: Text('Quantity: \\${h.quantity}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => removeHolding(i),
                    ),
                  );
                },
              ),
            ),
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (optimizationResult != null)
              Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Optimal Weights:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...optimizationResult!['optimal_weights'].entries.map<
                        Widget
                      >(
                        (e) => Text(
                          '${e.key}: ${(e.value * 100).toStringAsFixed(2)}%',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Expected Return: ${(optimizationResult!['expected_return'] * 100).toStringAsFixed(2)}%',
                      ),
                      Text(
                        'Expected Volatility: ${(optimizationResult!['expected_volatility'] * 100).toStringAsFixed(2)}%',
                      ),
                      Text(
                        'Sharpe Ratio: ${optimizationResult!['sharpe_ratio'].toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_graph),
                label: isLoading
                    ? const Text('Optimizing...')
                    : const Text('Optimize Portfolio'),
                onPressed: holdings.isEmpty || isLoading ? null : optimize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
