import 'package:flutter/material.dart';
import '../models/portfolio.dart';
import '../api_service.dart';
import 'dart:ui';

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
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            'Portfolio Optimizer',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
        ),
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
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.98,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, minHeight: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Card(
                      color: Theme.of(context).cardColor.withOpacity(0.90),
                      elevation: 20,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.22),
                          width: 2.0,
                        ),
                      ),
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: tickerController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ticker',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: quantityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.indigo,
                                    size: 26,
                                  ),
                                  onPressed: addHolding,
                                  tooltip: 'Add holding',
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Expanded(
                              child: holdings.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Add tickers and quantities to build your portfolio.',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: holdings.length,
                                      itemBuilder: (context, i) {
                                        final h = holdings[i];
                                        return Card(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white10
                                              : Colors.grey[100],
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              h.ticker,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Quantity: ${h.quantity}',
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => removeHolding(i),
                                              tooltip: 'Remove',
                                            ),
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
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey[100],
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Optimal Weights:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ...optimizationResult!['optimal_weights']
                                          .entries
                                          .map<Widget>(
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
                              height: 54,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.auto_graph, size: 24),
                                label: isLoading
                                    ? const Text(
                                        'Optimizing...',
                                        style: TextStyle(fontSize: 17),
                                      )
                                    : const Text(
                                        'Optimize Portfolio',
                                        style: TextStyle(fontSize: 17),
                                      ),
                                onPressed: holdings.isEmpty || isLoading
                                    ? null
                                    : optimize,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
