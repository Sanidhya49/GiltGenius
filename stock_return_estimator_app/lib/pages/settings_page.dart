import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../local_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<String> defaultFeatures;
  late DateTime defaultStartDate;
  late DateTime defaultEndDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await LocalStorage.loadSettings();
    setState(() {
      defaultFeatures = List<String>.from(
        prefs['defaultFeatures'] ?? allFeatures,
      );
      defaultStartDate =
          DateTime.tryParse(prefs['defaultStartDate'] ?? '') ??
          DateTime(2022, 1, 1);
      defaultEndDate =
          DateTime.tryParse(prefs['defaultEndDate'] ?? '') ??
          DateTime(2024, 1, 1);
      isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await LocalStorage.saveSettings({
      'defaultFeatures': defaultFeatures,
      'defaultStartDate': defaultStartDate.toIso8601String(),
      'defaultEndDate': defaultEndDate.toIso8601String(),
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved!')));
  }

  void showFeatureSelector() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(defaultFeatures);
        return AlertDialog(
          title: const Text('Select Default Features'),
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
              onPressed: () => Navigator.pop(context, defaultFeatures),
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
      setState(() => defaultFeatures = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Date Range',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start Date'),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd').format(defaultStartDate),
                          ),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: defaultStartDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null)
                              setState(() => defaultStartDate = picked);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End Date'),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd').format(defaultEndDate),
                          ),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: defaultEndDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null)
                              setState(() => defaultEndDate = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    title: const Text('Default Features'),
                    subtitle: Text(
                      defaultFeatures
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
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      onPressed: _saveSettings,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
