// lib/screens/application_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for HapticFeedback
import 'package:google_fonts/google_fonts.dart';

import 'greenhouse_page.dart';
import 'home_automation_page.dart';
import 'street_light_page.dart';

class ApplicationTab extends StatelessWidget {
  const ApplicationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          Text(
            "APPLICATIONS",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 30),

          _appTile(
            context,
            icon: Icons.eco,
            title: "Greenhouse",
            subtitle: "Control fogger, drip, exhaust",
            page: const GreenhousePage(),
          ),

          const SizedBox(height: 20),

          _appTile(
            context,
            icon: Icons.home,
            title: "Home Automation",
            subtitle: "Lights, fans and smart controls",
            page: const HomeAutomationPage(),
          ),

          const SizedBox(height: 20),

          _appTile(
            context,
            icon: Icons.lightbulb,
            title: "Street Light System",
            subtitle: "Control street lighting",
            page: const StreetLightPage(),
          ),
        ],
      ),
    );
  }

  Widget _appTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}