import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

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
        title: const Text("GiltGenius"),
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
          child: FractionallySizedBox(
            widthFactor: 0.95,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return LinearGradient(
                            colors: isDark
                                ? [Color(0xFF00C6FB), Color(0xFF005BEA)]
                                : [Color(0xFF232526), Color(0xFF414345)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'GiltGenius',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 12,
                                color: Colors.black54,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Luxury Returns. Smart Decisions.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 700),
                  child: AnimatedSlide(
                    offset: Offset(0, 0),
                    duration: const Duration(milliseconds: 700),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Card(
                          color: Theme.of(context).cardColor.withOpacity(0.82),
                          elevation: 12,
                          margin: const EdgeInsets.all(18),
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
                            padding: const EdgeInsets.all(26),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 2,
                                      bottom: 4,
                                    ),
                                    // child: Text(
                                    //   'Enter Stock Ticker (e.g. AAPL, TSLA)',
                                    //   style: TextStyle(
                                    //     fontWeight: FontWeight.w600,
                                    //     fontSize: 16,
                                    //     color: Theme.of(context)
                                    //         .colorScheme
                                    //         .onSurface
                                    //         .withOpacity(0.85),
                                    //   ),
                                    // ),
                                  ),
                                ),
                                TextField(
                                  controller: tickerController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white10
                                        : Colors.grey[100],
                                    labelText:
                                        'Enter Stock Ticker (e.g. AAPL, TSLA)',
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      letterSpacing: 0.5,
                                    ),
                                    errorText: isTickerValid
                                        ? null
                                        : 'Enter a valid ticker',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        tileColor:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white10
                                            : Colors.grey[100],
                                        title: const Text(
                                          "Start Date",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(startDate),
                                        ),
                                        leading: Icon(
                                          Icons.calendar_today,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
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
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        tileColor:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white10
                                            : Colors.grey[100],
                                        title: const Text(
                                          "End Date",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(endDate),
                                        ),
                                        leading: Icon(
                                          Icons.calendar_today,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
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
                                const SizedBox(height: 18),
                                ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  tileColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white10
                                      : Colors.grey[100],
                                  title: const Text(
                                    'Features',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  leading: Icon(
                                    Icons.settings,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                  trailing: SizedBox(
                                    width: 120,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      onPressed: showFeatureSelector,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
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
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          boxShadow: isFormValid
                                              ? [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.4),
                                                    blurRadius: 16,
                                                    spreadRadius: 1,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ]
                                              : [],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isFormValid
                                                ? null
                                                : Colors.grey[800],
                                            gradient: isFormValid
                                                ? LinearGradient(
                                                    colors: [
                                                      Color(0xFF4F8CFF),
                                                      Color(0xFF3A3AFF),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: isFormValid
                                                  ? _onPredictPressed
                                                  : null,
                                              child: Opacity(
                                                opacity: isFormValid
                                                    ? 1.0
                                                    : 0.6,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      Icon(
                                                        Icons.analytics,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Predict',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: isFormValid
                                          ? saveCurrentAsFavorite
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber[700],
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 18,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.star, size: 20),
                                          SizedBox(width: 6),
                                          Text(
                                            'Fav',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 4,
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
                                                  'ticker': tickerController
                                                      .text
                                                      .trim()
                                                      .toUpperCase(),
                                                  'start': startDate
                                                      .toIso8601String(),
                                                  'end': endDate
                                                      .toIso8601String(),
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
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Container(
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.0),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.4),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Card(
                    key: ValueKey(favorites.length),
                    color: Theme.of(context).cardColor.withOpacity(0.85),
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final fav = favorites[index];
                              return Dismissible(
                                key: ValueKey(fav['ticker'] + fav['start']),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (_) => deleteFavorite(index),
                                child: ListTile(
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
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => deleteFavorite(index),
                                    tooltip: 'Delete',
                                  ),
                                  onTap: () => loadFavorite(fav),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
