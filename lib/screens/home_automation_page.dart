// lib/screens/home_automation_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_config.dart';
import '../api_service.dart';

class AutomationDevice {
  final String id;
  final String label;
  final String onEndpoint;
  final String offEndpoint;
  const AutomationDevice({required this.id, required this.label, required this.onEndpoint, required this.offEndpoint});
}

class HomeAutomationPage extends StatefulWidget {
  const HomeAutomationPage({super.key});
  @override
  State<HomeAutomationPage> createState() => _HomeAutomationPageState();
}

class _HomeAutomationPageState extends State<HomeAutomationPage> {
  Map<String, dynamic> home = {};
  Timer? _timer;
  bool _isLoading = true;
  final Set<String> _pendingDevices = {};
  final Map<String, bool> _optimisticStatus = {};

  static const List<AutomationDevice> _lights = [
    AutomationDevice(id: 'light1_hub', label: 'Light 1 Hub', onEndpoint: ApiConfig.light1On, offEndpoint: ApiConfig.light1Off),
    AutomationDevice(id: 'light2_hub', label: 'Light 2 Hub', onEndpoint: ApiConfig.light2On, offEndpoint: ApiConfig.light2Off),
    AutomationDevice(id: 'light3_hub', label: 'Light 3 Hub', onEndpoint: ApiConfig.light3On, offEndpoint: ApiConfig.light3Off),
    AutomationDevice(id: 'light4_hub', label: 'Light 4 Hub', onEndpoint: ApiConfig.light4On, offEndpoint: ApiConfig.light4Off),
  ];

  static const List<AutomationDevice> _fans = [
    AutomationDevice(id: 'fan1_hub', label: 'Fan 1 Hub', onEndpoint: ApiConfig.fan1On, offEndpoint: ApiConfig.fan1Off),
    AutomationDevice(id: 'fan2_hub', label: 'Fan 2 Hub', onEndpoint: ApiConfig.fan2On, offEndpoint: ApiConfig.fan2Off),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => loadData());
  }

  Future<void> _loadInitialData() async {
    await loadData();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final rawData = await ApiService.fetchData(ApiConfig.homeData);
      if (rawData is! Map) throw Exception('Invalid data');
      final safeData = <String, dynamic>{};
      for (final entry in rawData.entries) {
        if (entry.key is String) safeData[entry.key] = entry.value;
      }
      if (mounted) setState(() => home = safeData);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  bool isOn(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return ['on', 'true', '1', 'enabled', 'active'].contains(s);
    }
    return false;
  }

  String? _getDeviceStatus(List<dynamic>? devices, String deviceId) {
    if (devices == null) return null;
    final device = devices
        .whereType<Map<dynamic, dynamic>>()
        .map((d) => d.map((k, v) => MapEntry(k.toString(), v)))
        .firstWhere((d) => d['device_id'] == deviceId, orElse: () => {});
    return device['status'] as String?;
  }

  bool _getEffectiveStatus(String deviceId) {
    return _optimisticStatus[deviceId] ?? _fetchStatusFromApi(deviceId);
  }

  bool _fetchStatusFromApi(String deviceId) {
    final lights = (home['lights'] as List<dynamic>?) ?? [];
    final fans = (home['fans'] as List<dynamic>?) ?? [];
    final statusStr = _getDeviceStatus([...lights, ...fans], deviceId);
    return isOn(statusStr);
  }

  Future<void> _toggleDevice(AutomationDevice device) async {
    final deviceId = device.id;
    final currentValue = _getEffectiveStatus(deviceId);
    final newValue = !currentValue;

    setState(() {
      _pendingDevices.add(deviceId);
      _optimisticStatus[deviceId] = newValue;
    });

    try {
      final endpoint = newValue ? device.onEndpoint : device.offEndpoint;
      await ApiService.postTrigger(endpoint);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: ${e.toString().substring(0, 80)}...')));
        setState(() => _optimisticStatus[deviceId] = currentValue);
      }
    } finally {
      if (mounted) setState(() => _pendingDevices.remove(deviceId));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricCard(String label, dynamic value, {String? unit}) {
    String displayValue = '--';
    if (value != null && value != '' && value != 'null') {
      if (value is num) {
        displayValue = (value is double && value % 1 != 0) ? value.toStringAsFixed(1) : value.toString();
      } else {
        displayValue = value.toString();
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text.rich(
              TextSpan(
                text: displayValue,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                children: unit != null
                    ? [TextSpan(text: ' $unit', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14))]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(AutomationDevice device) {
    final isPending = _pendingDevices.contains(device.id);
    final effectiveValue = _getEffectiveStatus(device.id);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: effectiveValue ? theme.colorScheme.primary.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveValue ? theme.colorScheme.primary : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                effectiveValue ? Icons.power : Icons.power_off,
                color: effectiveValue ? theme.colorScheme.primary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                device.label,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (isPending)
              const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
            if (!isPending)
              Switch.adaptive(
                value: effectiveValue,
                onChanged: (value) => _toggleDevice(device),
                activeColor: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && home.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Home Automation")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Monitor"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // === System Metrics ===
            _buildSectionTitle("System Status"),
            _buildMetricCard("Location", home['centre']),
            _buildMetricCard("Last Updated", home['last_updated']),
            _buildMetricCard("Battery", home['battery'], unit: "V"),
            _buildMetricCard("Door Status", home['door_status']),
            _buildMetricCard("Temperature", home['temperature'], unit: "°C"),
            _buildMetricCard("Humidity", home['humidity'], unit: "%"),
            _buildMetricCard("CO₂", home['co2'], unit: "ppm"),
            _buildMetricCard("Pressure", home['pressure'], unit: "hPa"),

            // === Lights ===
            _buildSectionTitle("Lights"),
            ..._lights.map(_buildDeviceTile),

            // === Fans ===
            _buildSectionTitle("Fans"),
            ..._fans.map(_buildDeviceTile),
          ],
        ),
      ),
    );
  }
}