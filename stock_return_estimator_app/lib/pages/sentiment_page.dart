import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import 'dart:async';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

class SentimentPage extends StatefulWidget {
  const SentimentPage({super.key});

  @override
  State<SentimentPage> createState() => _SentimentPageState();
}

class _SentimentPageState extends State<SentimentPage> {
  final tickerController = TextEditingController();
  bool isLoading = false;
  String? errorMsg;
  Map<String, dynamic>? sentimentData;

  Future<void> analyzeSentiment() async {
    final ticker = tickerController.text.trim().toUpperCase();
    if (ticker.isEmpty) return;
    if (!RegExp(r'^[A-Z0-9.]+$').hasMatch(ticker)) {
      setState(
        () => errorMsg = 'Enter a valid ticker (letters, numbers, dot only)',
      );
      return;
    }
    setState(() {
      isLoading = true;
      errorMsg = null;
      sentimentData = null;
    });

    try {
      final result = await ApiService.getSentimentAnalysis(ticker);
      setState(() {
        sentimentData = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
      case 'positive':
        return Colors.green;
      case 'bearish':
      case 'negative':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Icon _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
      case 'positive':
        return const Icon(Icons.trending_up, color: Colors.green);
      case 'bearish':
      case 'negative':
        return const Icon(Icons.trending_down, color: Colors.red);
      default:
        return const Icon(Icons.trending_flat, color: Colors.orange);
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
            'Sentiment Analysis',
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
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                elevation: 0,
                                color: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.all(0),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: tickerController,
                                        decoration: const InputDecoration(
                                          labelText: 'Enter Stock Ticker',
                                          hintText: 'e.g., AAPL, TSLA, GOOGL',
                                          prefixIcon: Icon(Icons.search),
                                          border: OutlineInputBorder(),
                                        ),
                                        onSubmitted: (_) => analyzeSentiment(),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton.icon(
                                          icon: isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.psychology,
                                                  size: 24,
                                                ),
                                          label: Text(
                                            isLoading
                                                ? 'Analyzing...'
                                                : 'Analyze Sentiment',
                                            style: const TextStyle(
                                              fontSize: 17,
                                            ),
                                          ),
                                          onPressed: isLoading
                                              ? null
                                              : analyzeSentiment,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo[700],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (errorMsg != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Card(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error,
                                            color: Colors.red[700],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              errorMsg!,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (sentimentData != null) ...[
                                const SizedBox(height: 16),
                                _buildOverallSentiment(),
                                const SizedBox(height: 16),
                                _buildSentimentFactors(),
                                const SizedBox(height: 16),
                                _buildNewsSentiment(),
                              ],
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
      ),
    );
  }

  Widget _buildOverallSentiment() {
    final overallSentiment = sentimentData!['overall_sentiment'] ?? 'neutral';
    final sentimentScore = sentimentData!['sentiment_score'] ?? 0.0;
    final stockInfo = sentimentData!['stock_info'] ?? {};

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getSentimentIcon(overallSentiment),
                const SizedBox(width: 8),
                Text(
                  'Overall Sentiment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stockInfo['name'] ?? sentimentData!['ticker'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stockInfo['sector'] != null)
                        Text(
                          '${stockInfo['sector']} • ${stockInfo['industry'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getSentimentColor(
                      overallSentiment,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getSentimentColor(overallSentiment),
                    ),
                  ),
                  child: Text(
                    overallSentiment.toUpperCase(),
                    style: TextStyle(
                      color: _getSentimentColor(overallSentiment),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSentimentGauge(sentimentScore)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sentiment Score',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      sentimentScore.toStringAsFixed(3),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Range: -1.0 to +1.0',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentGauge(double score) {
    final normalizedScore = (score + 1) / 2; // Convert from [-1,1] to [0,1]
    final color = score > 0.2
        ? Colors.green
        : score < -0.2
        ? Colors.red
        : Colors.orange;

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: normalizedScore,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(normalizedScore * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentFactors() {
    final factors = sentimentData!['sentiment_factors'] ?? [];

    if (factors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sentiment Factors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...factors.map((factor) => _buildFactorItem(factor)),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorItem(Map<String, dynamic> factor) {
    final factorName = factor['factor'] ?? '';
    final value = factor['value'] ?? 0.0;
    final weight = factor['weight'] ?? 0.0;
    final description = factor['description'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              factorName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (value + 1) / 2, // Normalize to [0,1]
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    value > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(weight * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSentiment() {
    final newsData = sentimentData!['news_data'] ?? {};
    final articles = newsData['articles'] ?? [];
    final sentimentSummary = newsData['sentiment_summary'] ?? {};

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article),
                const SizedBox(width: 8),
                const Text(
                  'News Sentiment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (sentimentSummary['sentiment'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getSentimentColor(
                        sentimentSummary['sentiment'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sentimentSummary['sentiment'].toString().toUpperCase(),
                      style: TextStyle(
                        color: _getSentimentColor(
                          sentimentSummary['sentiment'],
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (sentimentSummary['polarity'] != null)
              Row(
                children: [
                  Text(
                    'Polarity: ${sentimentSummary['polarity']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Articles: ${sentimentSummary['article_count'] ?? 0}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (articles.isNotEmpty) ...[
              const Text(
                'Recent News Articles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    final sentiment = article['sentiment'] ?? {};

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () async {
                          final url = article['url'];
                          if (url != null) {
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open the link.'),
                                ),
                              );
                            }
                          }
                        },
                        title: Text(
                          article['title'] ?? '',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article['source'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _getSentimentIcon(
                                    sentiment['sentiment'] ?? 'neutral',
                                  ).icon,
                                  size: 16,
                                  color: _getSentimentColor(
                                    sentiment['sentiment'] ?? 'neutral',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Polarity: ${sentiment['polarity']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new, size: 16),
                          onPressed: () async {
                            final url = article['url'];
                            if (url != null) {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open the link.'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text(
                'No recent news articles found',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
