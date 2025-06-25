import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final tickerController = TextEditingController();
  DateTime startDate = DateTime(2022, 1, 1);
  DateTime endDate = DateTime(2024, 1, 1);
  final List<String> allFeatures = [
    'Return_Lag_1',
    'Return_Lag_5',
    'MA_10',
    'RSI_14',
    'BBL_20',
    'BBM_20',
    'BBU_20',
  ];
  final Map<String, String> featureLabels = {
    'Return_Lag_1': '1-Day Return Lag',
    'Return_Lag_5': '5-Day Return Lag',
    'MA_10': '10-Day Moving Avg',
    'RSI_14': 'RSI (14)',
    'BBL_20': 'BB Lower (20)',
    'BBM_20': 'BB Middle (20)',
    'BBU_20': 'BB Upper (20)',
  };
  late List<String> selectedFeatures;
  String? errorMsg;
  List<Map<String, dynamic>> favorites = [];
  bool isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    selectedFeatures = List.from(allFeatures);
    _loadUserDefaults();
    _loadFavorites();
  }

  Future<void> _loadUserDefaults() async {
    final settings = await LocalStorage.loadSettings();
    setState(() {
      if (settings['defaultFeatures'] != null) {
        selectedFeatures = List<String>.from(settings['defaultFeatures']);
      }
      if (settings['defaultStartDate'] != null) {
        startDate =
            DateTime.tryParse(settings['defaultStartDate']) ?? startDate;
      }
      if (settings['defaultEndDate'] != null) {
        endDate = DateTime.tryParse(settings['defaultEndDate']) ?? endDate;
      }
    });
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoadingFavorites = true);
    favorites = await LocalStorage.loadFavorites();
    setState(() => isLoadingFavorites = false);
  }

  bool get isTickerValid =>
      tickerController.text.trim().isNotEmpty &&
      RegExp(r'^[A-Za-z.]+').hasMatch(tickerController.text.trim());
  bool get isDateRangeValid => !endDate.isBefore(startDate);
  bool get isFormValid =>
      isTickerValid && isDateRangeValid && selectedFeatures.isNotEmpty;

  void showFeatureSelector() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedFeatures);
        return AlertDialog(
          title: const Text('Select Features'),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: allFeatures.map((f) {
                return CheckboxListTile(
                  value: tempSelected.contains(f),
                  title: Text(featureLabels[f] ?? f),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        tempSelected.add(f);
                      } else {
                        tempSelected.remove(f);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, selectedFeatures),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      setState(() => selectedFeatures = result);
    }
  }

  Future<void> saveCurrentAsFavorite() async {
    final fav = {
      'ticker': tickerController.text.trim().toUpperCase(),
      'start': startDate.toIso8601String(),
      'end': endDate.toIso8601String(),
      'features': List<String>.from(selectedFeatures),
    };
    await LocalStorage.saveFavorite(fav);
    await _loadFavorites();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Favorite saved!')));
  }

  void loadFavorite(Map<String, dynamic> fav) {
    setState(() {
      tickerController.text = fav['ticker'] ?? '';
      startDate = DateTime.parse(fav['start']);
      endDate = DateTime.parse(fav['end']);
      selectedFeatures = List<String>.from(fav['features'] ?? allFeatures);
    });
  }

  Future<void> deleteFavorite(int index) async {
    await LocalStorage.deleteFavorite(index);
    await _loadFavorites();
  }

  void _onPredictPressed() async {
    String? modelName;
    final prefs = await SharedPreferences.getInstance();
    modelName = prefs.getString('current_model_name');
    Navigator.pushNamed(
      context,
      '/result',
      arguments: {
        'ticker': tickerController.text.trim().toUpperCase(),
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
        'features': selectedFeatures,
        if (modelName != null) 'model_name': modelName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📈 Stock Return Estimator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.trending_up, color: Colors.white),
                    label: const Text(
                      'View Top Gainers & Losers',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/top_gainers'),
                  ),
                ),
              ),
              Card(
                elevation: 6,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: tickerController,
                        decoration: InputDecoration(
                          labelText: "Enter Stock Ticker (e.g. AAPL, TSLA)",
                          errorText: isTickerValid
                              ? null
                              : 'Enter a valid ticker',
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text("Start Date"),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(startDate),
                              ),
                              leading: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null)
                                  setState(() => startDate = picked);
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text("End Date"),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(endDate),
                              ),
                              leading: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null)
                                  setState(() => endDate = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (!isDateRangeValid)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'End date must be after start date',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 20),
                      ListTile(
                        title: const Text('Features'),
                        subtitle: Text(
                          selectedFeatures
                              .map((f) => featureLabels[f] ?? f)
                              .join(', '),
                        ),
                        leading: const Icon(Icons.settings),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          onPressed: showFeatureSelector,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.analytics),
                              label: const Text("Predict"),
                              onPressed: isFormValid ? _onPredictPressed : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(fontSize: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.star),
                            label: const Text("Save Favorite"),
                            onPressed: isFormValid
                                ? saveCurrentAsFavorite
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.analytics,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Backtest Strategy',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isFormValid
                                ? () async {
                                    String? modelName;
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    modelName = prefs.getString(
                                      'current_model_name',
                                    );
                                    Navigator.pushNamed(
                                      context,
                                      '/backtest',
                                      arguments: {
                                        'ticker': tickerController.text
                                            .trim()
                                            .toUpperCase(),
                                        'start': startDate.toIso8601String(),
                                        'end': endDate.toIso8601String(),
                                        'features': selectedFeatures,
                                        if (modelName != null)
                                          'model_name': modelName,
                                      },
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Favorites',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.indigo[900],
                    ),
                  ),
                ),
              ),
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: isLoadingFavorites
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : favorites.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No favorites yet.')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: favorites.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final fav = favorites[index];
                          return ListTile(
                            title: Text(
                              fav['ticker'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${fav['start']?.substring(0, 10) ?? ''} to ${fav['end']?.substring(0, 10) ?? ''}\n' +
                                  (fav['features'] as List<dynamic>)
                                      .map((f) => featureLabels[f] ?? f)
                                      .join(', '),
                            ),
                            isThreeLine: true,
                            leading: const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteFavorite(index),
                              tooltip: 'Delete',
                            ),
                            onTap: () => loadFavorite(fav),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
