import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Weather? weather;
  bool loading = true;
  String? error;

  List<String> saved = [];

  @override
  void initState() {
    super.initState();
    loadSaved();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await fetchWeather();
      if (!mounted) return;
      setState(() {
        weather = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load the weather. Check your internet connection.';
      });
    }
  }

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      saved = prefs.getStringList('saved_readings') ?? [];
    });
  }

  Future<void> saveReading() async {
    final w = weather;
    if (w == null) return;
    final t = DateTime.now();
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final reading = '${w.temperature}°C · ${describe(w.code)} · $time';

    final updated = [reading, ...saved];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_readings', updated);
    if (!mounted) return;
    setState(() {
      saved = updated;
    });
  }

  Future<void> clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_readings');
    if (!mounted) return;
    setState(() {
      saved = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kigali Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: clearSaved,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: _buildError());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: _buildWeather(weather!)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: saveReading,
          icon: const Icon(Icons.bookmark_add),
          label: const Text('Save reading'),
        ),
        const SizedBox(height: 16),
        Text('Saved readings', style: Theme.of(context).textTheme.titleMedium),
        for (final r in saved)
          ListTile(leading: const Icon(Icons.history), title: Text(r)),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildWeather(Weather w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(w.code), size: 96),
        const SizedBox(height: 8),
        Text(
          '${w.temperature}°C',
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
        ),
        Text(describe(w.code), style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stat(Icons.water_drop_outlined, '${w.humidity}%', 'Humidity'),
            const SizedBox(width: 32),
            _stat(Icons.air, '${w.wind} km/h', 'Wind'),
          ],
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}

IconData iconFor(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code <= 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 95) return Icons.thunderstorm;
  if (code >= 51) return Icons.water_drop;
  return Icons.help_outline;
}