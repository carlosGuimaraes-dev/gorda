import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    AppThemeTokens.primary,
                    AppThemeTokens.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'AG',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Text(
                  'AG Home Organizer International',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppThemeTokens.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service & team management',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemeTokens.secondaryText,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
