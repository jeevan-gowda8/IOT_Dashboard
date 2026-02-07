// lib/screens/settings_tab.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsTab extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SettingsTab({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingTile(
            context,
            icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: "Dark Theme",
            trailing: Switch.adaptive(
              value: isDarkMode,
              onChanged: (_) => onThemeToggle(),
              activeColor: theme.colorScheme.primary,
            ),
            onTap: onThemeToggle,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(context),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Campus Monitor v1.0",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Smart monitoring system for Greenhouse, Home Automation and Street Light using Thingsay API integration.",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}