import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../local_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class SettingsPage extends StatefulWidget {
  final ValueNotifier<ThemeMode>? themeModeNotifier;
  const SettingsPage({super.key, this.themeModeNotifier});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<String> defaultFeatures;
  late DateTime defaultStartDate = DateTime.now().subtract(
    const Duration(days: 365),
  );
  late DateTime defaultEndDate = DateTime.now();
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
          DateTime.now().subtract(const Duration(days: 365));
      defaultEndDate =
          DateTime.tryParse(prefs['defaultEndDate'] ?? '') ?? DateTime.now();
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
          content: StatefulBuilder(
            builder: (context, setState) => SizedBox(
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

  // Utility to sanitize model names
  bool isModelNameValid(String name) {
    final valid = RegExp(r'^[\w\-.]+\.pkl\$');
    return valid.hasMatch(name);
  }

  Future<void> _saveModel() async {
    final name = modelNameController.text.trim();
    if (name.isEmpty) return;
    final modelName = name.endsWith('.pkl') ? name : '$name.pkl';
    if (!isModelNameValid(modelName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid model name. Use only letters, numbers, dash, underscore, and .pkl extension.',
          ),
        ),
      );
      return;
    }
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
    if (!isModelNameValid(modelName)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid model name.')));
      return;
    }
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
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                      minHeight: 520,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Card(
                            color: Theme.of(
                              context,
                            ).cardColor.withOpacity(0.90),
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
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 32,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Theme',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (themeNotifier != null)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.light_mode,
                                              size: 20,
                                            ),
                                            Switch(
                                              value:
                                                  themeNotifier.value ==
                                                  ThemeMode.dark,
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
                                            const Icon(
                                              Icons.dark_mode,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Default Date Range',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ListTile(
                                          title: const Text('Start Date'),
                                          subtitle: Text(
                                            DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(defaultStartDate),
                                          ),
                                          leading: const Icon(
                                            Icons.calendar_today,
                                          ),
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: defaultStartDate,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime.now(),
                                            );
                                            if (picked != null)
                                              setState(
                                                () => defaultStartDate = picked,
                                              );
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: ListTile(
                                          title: const Text('End Date'),
                                          subtitle: Text(
                                            DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(defaultEndDate),
                                          ),
                                          leading: const Icon(
                                            Icons.calendar_today,
                                          ),
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: defaultEndDate,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime.now(),
                                            );
                                            if (picked != null)
                                              setState(
                                                () => defaultEndDate = picked,
                                              );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Clean, responsive layout for Default Features
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.settings,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              'Default Features',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Edit'),
                                                onPressed: showFeatureSelector,
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(
                                                    80,
                                                    36,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.refresh),
                                                label: const Text(
                                                  'Reset to Defaults',
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    defaultFeatures =
                                                        List<String>.from(
                                                          allFeatures,
                                                        );
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Features reset to defaults.',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(
                                                    80,
                                                    36,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  backgroundColor:
                                                      Colors.grey[600],
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.save, size: 24),
                                      label: const Text(
                                        'Save Settings',
                                        style: TextStyle(fontSize: 17),
                                      ),
                                      onPressed: _saveSettings,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo[700],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 3,
                                      ),
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
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : filteredModels.isEmpty
                                      ? const Text('No saved models yet.')
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Saved Models:'),
                                            const SizedBox(height: 8),
                                            ...filteredModels.map(
                                              (m) => ListTile(
                                                title: Text(m),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                        Icons.download,
                                                      ),
                                                      label: const Text('Load'),
                                                      onPressed: () =>
                                                          _loadModel(m),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.teal[600],
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        elevation: 2,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                      ),
                                                      label: const Text(
                                                        'Delete',
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red[700],
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        elevation: 2,
                                                      ),
                                                      onPressed: () async {
                                                        final confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: const Text(
                                                              'Delete Model',
                                                            ),
                                                            content: Text(
                                                              'Are you sure you want to delete model "$m"?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red[700],
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                                child:
                                                                    const Text(
                                                                      'Delete',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          final response = await http.post(
                                                            Uri.parse(
                                                              '${backendUrl.replaceAll('/predict', '')}/delete_model',
                                                            ),
                                                            headers: {
                                                              'Content-Type':
                                                                  'application/json',
                                                            },
                                                            body:
                                                                '{"model_name": "$m"}',
                                                          );
                                                          if (response
                                                                  .statusCode ==
                                                              200) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Model "$m" deleted',
                                                                ),
                                                              ),
                                                            );
                                                            _loadModels();
                                                          } else {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Failed to delete model "$m"',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
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
