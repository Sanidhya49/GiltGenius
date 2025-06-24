import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  List<String> selectedFeatures = [
    'Return_Lag_1',
    'Return_Lag_5',
    'MA_10',
    'RSI_14',
    'BBL_20',
    'BBM_20',
    'BBU_20',
  ];
  String? errorMsg;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📈 Stock Return Estimator")),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tickerController,
                    decoration: InputDecoration(
                      labelText: "Enter Stock Ticker (e.g. AAPL, TSLA)",
                      errorText: isTickerValid ? null : 'Enter a valid ticker',
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.analytics),
                      label: const Text("🔮 Predict"),
                      onPressed: isFormValid
                          ? () {
                              Navigator.pushNamed(
                                context,
                                '/result',
                                arguments: {
                                  'ticker': tickerController.text
                                      .trim()
                                      .toUpperCase(),
                                  'start': startDate.toIso8601String(),
                                  'end': endDate.toIso8601String(),
                                  'features': selectedFeatures,
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
