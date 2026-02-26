import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../auth/domain/user_session.dart';
import '../dashboard/presentation/dashboard_page.dart';
import '../schedule/presentation/schedule_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.role});

  final UserRole role;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));

    final managerPages = [
      const DashboardPage(),
      SchedulePage(role: widget.role),
      const Center(child: Text('Clients migration in progress')),
      const Center(child: Text('Finance migration in progress')),
      const Center(child: Text('Settings migration in progress')),
    ];

    final employeePages = [
      const DashboardPage(),
      SchedulePage(role: widget.role),
      const Center(child: Text('Finance migration in progress')),
      const Center(child: Text('Settings migration in progress')),
    ];

    final pages =
        widget.role == UserRole.manager ? managerPages : employeePages;

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: widget.role == UserRole.manager
            ? [
                NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    label: strings.dashboard),
                NavigationDestination(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: strings.schedule),
                NavigationDestination(
                    icon: const Icon(Icons.people_outline),
                    label: strings.clients),
                NavigationDestination(
                    icon: const Icon(Icons.payments_outlined),
                    label: strings.finance),
                NavigationDestination(
                    icon: const Icon(Icons.settings_outlined),
                    label: strings.settings),
              ]
            : [
                NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    label: strings.dashboard),
                NavigationDestination(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: strings.schedule),
                NavigationDestination(
                    icon: const Icon(Icons.payments_outlined),
                    label: strings.finance),
                NavigationDestination(
                    icon: const Icon(Icons.settings_outlined),
                    label: strings.settings),
              ],
      ),
    );
  }
}
