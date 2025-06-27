import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../local_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final ValueNotifier<ThemeMode>? themeModeNotifier;
  const SettingsPage({super.key, this.themeModeNotifier});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<String> defaultFeatures;
  late DateTime defaultStartDate;
  late DateTime defaultEndDate;
  bool isLoading = true;
  // Model management
  List<String> models = [];
  List<String> filteredModels = [];
  bool isLoadingModels = false;
  final modelNameController = TextEditingController();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadModels();
    searchController.addListener(_filterModels);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterModels() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      filteredModels = models
          .where((m) => m.toLowerCase().contains(query))
          .toList();
    });
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

  Future<void> _loadModels() async {
    setState(() => isLoadingModels = true);
    try {
      final response = await http.get(
        Uri.parse('${backendUrl.replaceAll('/predict', '')}/list_models'),
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));
        models = List<String>.from(data['models'] ?? []);
        filteredModels = List<String>.from(models);
      }
    } catch (_) {}
    setState(() => isLoadingModels = false);
  }

  Future<void> _saveModel() async {
    final name = modelNameController.text.trim();
    if (name.isEmpty) return;
    final modelName = name.endsWith('.pkl') ? name : '$name.pkl';
    final response = await http.post(
      Uri.parse('${backendUrl.replaceAll('/predict', '')}/save_model'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model_name': modelName}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Model saved as $modelName')));
      modelNameController.clear();
      _loadModels();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save model')));
    }
  }

  Future<void> _loadModel(String modelName) async {
    final response = await http.post(
      Uri.parse('${backendUrl.replaceAll('/predict', '')}/load_model'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model_name': modelName}),
    );
    if (response.statusCode == 200) {
      // Store the loaded model name in shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_model_name', modelName);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Model $modelName loaded')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load model')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = widget.themeModeNotifier;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Theme',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (themeNotifier != null)
                          Row(
                            children: [
                              const Icon(Icons.light_mode, size: 20),
                              Switch(
                                value: themeNotifier.value == ThemeMode.dark,
                                onChanged: (val) async {
                                  themeNotifier.value = val
                                      ? ThemeMode.dark
                                      : ThemeMode.light;
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                    'theme_mode',
                                    val ? 'dark' : 'light',
                                  );
                                },
                              ),
                              const Icon(Icons.dark_mode, size: 20),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                      subtitle: null,
                      leading: const Icon(Icons.settings),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: showFeatureSelector,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                        onPressed: _saveSettings,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const Text(
                      'Model Management',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Models',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    isLoadingModels
                        ? const Center(child: CircularProgressIndicator())
                        : filteredModels.isEmpty
                        ? const Text('No saved models yet.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saved Models:'),
                              const SizedBox(height: 8),
                              ...filteredModels.map(
                                (m) => ListTile(
                                  title: Text(m),
                                  trailing: ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text('Load'),
                                    onPressed: () => _loadModel(m),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
