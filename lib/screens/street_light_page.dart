// lib/screens/street_light_page.dart
import 'dart:async';
import 'package:flutter/material.dart'; // debugPrint is available via assert
import 'package:flutter/services.dart';

import '../api_config.dart';
import '../api_service.dart';

class StreetLightPage extends StatefulWidget {
  const StreetLightPage({super.key});

  @override
  State<StreetLightPage> createState() => _StreetLightPageState();
}

class _StreetLightPageState extends State<StreetLightPage> {
  bool _isLightOn = false;
  bool _isPending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isOn(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return ['on', 'true', '1', 'enabled', 'active'].contains(s);
    }
    return false;
  }

  Future<void> _fetchStatus() async {
    try {
      final rawData = await ApiService.fetchData(ApiConfig.streetStatus);

      assert(() {
        debugPrint('[StreetLight] Raw status: $rawData');
        return true;
      }());

      final effectiveStatus = _isOn(rawData);

      if (mounted && !_isPending) {
        setState(() {
          _isLightOn = effectiveStatus;
        });
      }
    } catch (e, stack) {
      assert(() {
        debugPrint('[StreetLight] Fetch error: $e\n$stack');
        return true;
      }());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch status: $e')),
        );
      }
    }
  }

  Future<void> _toggleLight(bool newValue) async {
    if (_isPending) return;

    final previousValue = _isLightOn;
    setState(() {
      _isPending = true;
      _isLightOn = newValue;
    });

    try {
      final endpoint = newValue ? ApiConfig.streetOn : ApiConfig.streetOff;
      await ApiService.postTrigger(endpoint);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: ${e.toString().substring(0, 80)}...')),
        );
        setState(() {
          _isLightOn = previousValue;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _isLightOn ? theme.colorScheme.primary : theme.disabledColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Street Light"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        systemOverlayStyle: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lightbulb Icon
                  Icon(
                    Icons.lightbulb,
                    size: 80,
                    color: iconColor,
                  ),
                  const SizedBox(height: 24),

                  // Status Text
                  Text(
                    _isLightOn
                        ? "STREET LIGHT IS ON"
                        : "STREET LIGHT IS OFF",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Switch
                  Semantics(
                    container: true,
                    label: 'Street light, ${_isLightOn ? 'on' : 'off'}',
                    child: Switch.adaptive(
                      value: _isLightOn,
                      activeThumbColor: theme.colorScheme.primary, // ✅ Correct
                      onChanged: _isPending ? null : _toggleLight,
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