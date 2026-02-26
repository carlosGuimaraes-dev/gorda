import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../auth/domain/user_session.dart';
import '../clients/presentation/clients_page.dart';
import '../dashboard/presentation/dashboard_page.dart';
import '../employees/presentation/employees_page.dart';
import '../finance/presentation/finance_page.dart';
import '../schedule/presentation/schedule_page.dart';
import '../services/presentation/services_page.dart';
import '../settings/presentation/settings_page.dart';
import '../teams/presentation/teams_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.role});

  final UserRole role;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  void _openCatalogPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _openMenu() {
    final strings = AppStrings.of(Localizations.localeOf(context));
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(strings.catalogs),
              ),
              ListTile(
                leading: const Icon(Icons.handyman_outlined),
                title: Text(strings.services),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCatalogPage(const ServicesPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: Text(strings.employees),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCatalogPage(const EmployeesPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(strings.teams),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCatalogPage(const TeamsPage());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));

    final managerPages = [
      DashboardPage(onMenu: _openMenu),
      SchedulePage(role: widget.role, onMenu: _openMenu),
      ClientsPage(onMenu: _openMenu),
      FinancePage(onMenu: _openMenu),
      SettingsPage(onMenu: _openMenu),
    ];

    final employeePages = [
      DashboardPage(onMenu: _openMenu),
      SchedulePage(role: widget.role, onMenu: _openMenu),
      FinancePage(onMenu: _openMenu),
      SettingsPage(onMenu: _openMenu),
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
