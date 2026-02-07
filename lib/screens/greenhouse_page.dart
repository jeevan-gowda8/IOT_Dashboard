// lib/screens/greenhouse_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Required for SystemUiOverlayStyle

import '../api_config.dart';
import '../api_service.dart';

class GreenhouseDevice {
  final String id;
  final String label;
  final String onEndpoint;
  final String offEndpoint;

  const GreenhouseDevice({
    required this.id,
    required this.label,
    required this.onEndpoint,
    required this.offEndpoint,
  });
}

class GreenhousePage extends StatefulWidget {
  const GreenhousePage({super.key});

  @override
  State<GreenhousePage> createState() => _GreenhousePageState();
}

class _GreenhousePageState extends State<GreenhousePage> {
  Map<String, dynamic> gh = {};
  Timer? _timer;
  bool _isLoading = true;

  final Set<String> _pendingDevices = {};
  final Map<String, bool> _optimisticStatus = {};

  static const List<GreenhouseDevice> _devices = [
    GreenhouseDevice(id: 'fogger', label: 'Fogger', onEndpoint: ApiConfig.foggerOn, offEndpoint: ApiConfig.foggerOff),
    GreenhouseDevice(id: 'drip_irrigation', label: 'Drip Irrigation', onEndpoint: ApiConfig.dripOn, offEndpoint: ApiConfig.dripOff),
    GreenhouseDevice(id: 'exhaust_fan', label: 'Exhaust Fan', onEndpoint: ApiConfig.exhaustOn, offEndpoint: ApiConfig.exhaustOff),
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
      final rawData = await ApiService.fetchData(ApiConfig.greenhouseData);
      if (rawData is! Map) throw Exception('Invalid data');
      final safeData = <String, dynamic>{};
      for (final entry in rawData.entries) {
        if (entry.key is String) safeData[entry.key] = entry.value;
      }
      if (mounted) setState(() => gh = safeData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
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

  bool _getEffectiveStatus(String deviceId) {
    return _optimisticStatus[deviceId] ?? isOn(gh[deviceId]);
  }

  Future<void> _toggleDevice(GreenhouseDevice device) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: ${e.toString().substring(0, 80)}...')),
        );
        setState(() => _optimisticStatus[deviceId] = currentValue);
      }
    } finally {
      if (mounted) {
        setState(() => _pendingDevices.remove(deviceId));
      }
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

  Widget _buildDeviceTile(GreenhouseDevice device) {
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
                color: effectiveValue
                    ? theme.colorScheme.primary.withValues(alpha: 0.15) // ✅ FIXED
                    : Colors.grey.withValues(alpha: 0.1), // ✅ FIXED
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveValue ? theme.colorScheme.primary : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                effectiveValue ? Icons.water_drop : Icons.water_drop_outlined,
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
                // ✅ FIXED: activeThumbColor instead of activeColor
                activeThumbColor: theme.colorScheme.primary,
                activeTrackColor: theme.colorScheme.primary.withOpacity(0.3), // optional track tint
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && gh.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Greenhouse Monitor")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Greenhouse Monitor"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        // ✅ FIXED: SystemUiOverlayStyle is now available
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // === Environment ===
            _buildSectionTitle("Environment"),
            _buildMetricCard("Temperature", gh['temp'], unit: "°C"),
            _buildMetricCard("Humidity", gh['humi'], unit: "%"),
            _buildMetricCard("CO₂", gh['co2'], unit: "ppm"),
            _buildMetricCard("Atmospheric Pressure", gh['pressure'], unit: "hPa"),

            // === Soil Conditions ===
            _buildSectionTitle("Soil Conditions"),
            _buildMetricCard("Soil Temperature", gh['soil_temp'], unit: "°C"),
            _buildMetricCard("Soil Humidity", gh['soil_humi'], unit: "%"),
            _buildMetricCard("Moisture", gh['moisture'], unit: "%"),
            _buildMetricCard("Soil Conductivity", gh['soil_conduct'], unit: "µS/cm"),
            _buildMetricCard("pH", gh['pH']),

            // === Nutrient Levels ===
            _buildSectionTitle("Nutrient Levels"),
            _buildMetricCard("Nitrogen (N)", gh['N'], unit: "mg/kg"),
            _buildMetricCard("Phosphorus (P)", gh['P'], unit: "mg/kg"),
            _buildMetricCard("Potassium (K)", gh['K'], unit: "mg/kg"),

            // === Water System ===
            _buildSectionTitle("Water System"),
            _buildMetricCard("Water Level", gh['water_level'], unit: "cm"),

            // === Controls ===
            _buildSectionTitle("Controls"),
            ..._devices.map(_buildDeviceTile),
          ],
        ),
      ),
    );
  }
}