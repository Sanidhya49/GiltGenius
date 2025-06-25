import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:intl/intl.dart';

class TopGainersPage extends StatefulWidget {
  const TopGainersPage({super.key});
  @override
  State<TopGainersPage> createState() => _TopGainersPageState();
}

class _TopGainersPageState extends State<TopGainersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> gainers = [];
  List<dynamic> losers = [];
  bool isLoading = true;
  bool isError = false;
  String? errorMsg;
  String searchQuery = '';
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      isError = false;
      errorMsg = null;
    });
    try {
      final g = await ApiService.fetchTopGainers();
      final l = await ApiService.fetchTopLosers();
      setState(() {
        gainers = g;
        losers = l;
        lastUpdated = DateTime.now();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isError = true;
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filter(List<dynamic> stocks) {
    if (searchQuery.isEmpty) return stocks;
    return stocks.where((s) {
      final name = (s['symbol'] ?? s['companyName'] ?? '').toString().toLowerCase();
      final company = (s['companyName'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase()) || company.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Gainers & Losers (NIFTY 100)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Top Gainers'),
            Tab(text: 'Top Losers'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by symbol or name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: isLoading ? null : _fetchData,
                ),
              ],
            ),
          ),
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last updated: ' + DateFormat('yyyy-MM-dd HH:mm').format(lastUpdated!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMsg ?? 'Failed to load data', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              onPressed: _fetchData,
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStockList(_filter(gainers), true),
                          _buildStockList(_filter(losers), false),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(List<dynamic> stocks, bool isGainer) {
    if (stocks.isEmpty) {
      return const Center(child: Text('No data available.'));
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: stocks.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final stock = stocks[index];
          final symbol = stock['symbol'] ?? stock['companyName'] ?? '';
          final company = stock['companyName'] ?? symbol;
          final price = stock['ltp'] ?? stock['price'] ?? '-';
          final change = stock['netPrice'] ?? stock['change'] ?? 0;
          final percent = stock['netPricePercentage'] ?? stock['percent'] ?? 0;
          final volume = stock['tradedQuantity'] ?? stock['volume'] ?? '-';
          final high52 = stock['high52'] ?? '-';
          final low52 = stock['low52'] ?? '-';
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isGainer ? Colors.green[50] : Colors.red[50],
                child: Text(
                  symbol.toString()[0],
                  style: TextStyle(color: isGainer ? Colors.green : Colors.red),
                ),
              ),
              title: Text(
                '$company ($symbol)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (volume != '-') Text('Volume: $volume'),
                  if (high52 != '-' && low52 != '-')
                    Text('52W Low: $low52   52W High: $high52'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u20b9$price',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${change > 0 ? '+' : ''}$change (${percent}%)',
                    style: TextStyle(
                      color: change > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () => _showStockDetails(context, stock, isGainer),
            ),
          );
        },
      ),
    );
  }

  void _showStockDetails(BuildContext context, dynamic stock, bool isGainer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final symbol = stock['symbol'] ?? stock['companyName'] ?? '';
        final company = stock['companyName'] ?? symbol;
        final price = stock['ltp'] ?? stock['price'] ?? '-';
        final change = stock['netPrice'] ?? stock['change'] ?? 0;
        final percent = stock['netPricePercentage'] ?? stock['percent'] ?? 0;
        final volume = stock['tradedQuantity'] ?? stock['volume'] ?? '-';
        final high52 = stock['high52'] ?? '-';
        final low52 = stock['low52'] ?? '-';
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isGainer ? Colors.green[50] : Colors.red[50],
                    child: Text(
                      symbol.toString()[0],
                      style: TextStyle(color: isGainer ? Colors.green : Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$company ($symbol)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Price: \u20b9$price'),
              Text('Change: ${change > 0 ? '+' : ''}$change (${percent}%)'),
              if (volume != '-') Text('Volume: $volume'),
              if (high52 != '-' && low52 != '-')
                Text('52W Low: $low52   52W High: $high52'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(isGainer ? Icons.trending_up : Icons.trending_down, color: isGainer ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text(isGainer ? 'Gainer' : 'Loser', style: TextStyle(color: isGainer ? Colors.green : Colors.red)),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star),
                  label: const Text('Favorite'),
                  onPressed: () {
                    // TODO: Implement favorite logic if desired
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
 