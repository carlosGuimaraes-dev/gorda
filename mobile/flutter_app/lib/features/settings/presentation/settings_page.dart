import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../employees/presentation/employees_page.dart';
import '../../offline/application/offline_store.dart';
import 'audit_log_page.dart';
import 'company_profile_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifyClients = true;
  bool _notifyTeam = true;
  bool _pushEnabled = false;
  bool _siriSuggestions = false;
  bool _enableWhatsApp = true;
  bool _enableSms = true;
  bool _enableEmail = true;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final session = state.session;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lastSync = state.lastSync == null
        ? null
        : DateFormat.yMd(locale).add_Hm().format(state.lastSync!);

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(
        leading: widget.onMenu == null
            ? null
            : IconButton(
                onPressed: widget.onMenu,
                icon: const Icon(Icons.menu),
              ),
        title: Text(strings.settings),
      ),
      body: ListView(
        children: [
          if (session != null)
            _SettingsSection(
              title: strings.session,
              children: [
                ListTile(
                  title: Text('${strings.user}: ${session.name}'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                ListTile(
                  title: Text(
                    strings.signOut,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () => ref.read(offlineStoreProvider.notifier).logout(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          _SettingsSection(
            title: strings.sync,
            children: [
              ListTile(
                title: Text(strings.forceSync),
                onTap: () => ref
                    .read(offlineStoreProvider.notifier)
                    .syncPendingChangesStub(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              if (lastSync != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '${strings.last}: $lastSync',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeTokens.secondaryText,
                        ),
                  ),
                ),
              if (state.pendingChanges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    '${state.pendingChanges.length} ${strings.pendingChangesInQueue}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeTokens.secondaryText,
                        ),
                  ),
                ),
            ],
          ),
          _SettingsSection(
            title: 'Conflicts', // strings.conflicts doesn't exist
            children: [
              if (state.conflictLog.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'No conflicts recorded.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeTokens.secondaryText,
                    ),
                  ),
                )
              else
                ...state.conflictLog.map((entry) => ListTile(
                      title: Text(entry.summary),
                      subtitle: Text('${entry.entity} · ${entry.field}\n${DateFormat.yMd(locale).format(entry.timestamp)}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    )),
            ],
          ),
          if (session?.role == UserRole.manager)
            _SettingsSection(
              title: 'Audit log',
              children: [
                ListTile(
                  title: const Text('Audit log'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AuditLogPage(),
                    ));
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          if (session?.role == UserRole.manager)
            _SettingsSection(
              title: strings.team,
              children: [
                ListTile(
                  title: Text(strings.employees),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EmployeesPage(),
                    ));
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          if (session?.role == UserRole.manager)
            _SettingsSection(
              title: strings.appPreferences,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: DropdownButtonFormField<String>(
                    value: state.languageCode,
                    decoration: InputDecoration(labelText: strings.language),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      final country = value == 'es' ? 'ES' : 'US';
                      ref.read(offlineStoreProvider.notifier).setLocale(
                            languageCode: value,
                            countryCode: country,
                          );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DropdownButtonFormField<String>(
                    value: 'USD',
                    decoration: InputDecoration(labelText: strings.currency),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
                ListTile(
                  title: Text(state.appPreferences.disputeWindowDays == 1
                      ? 'Dispute window: 1 day after due date'
                      : 'Dispute window: ${state.appPreferences.disputeWindowDays} days after due date'),
                  subtitle: const Text('0 days means disputes are only allowed until the due date.'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (state.appPreferences.disputeWindowDays > 0) {
                            ref.read(offlineStoreProvider.notifier).setAppPreferences(
                                  state.appPreferences.copyWith(
                                    disputeWindowDays: state.appPreferences.disputeWindowDays - 1,
                                  ),
                                );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (state.appPreferences.disputeWindowDays < 30) {
                            ref.read(offlineStoreProvider.notifier).setAppPreferences(
                                  state.appPreferences.copyWith(
                                    disputeWindowDays: state.appPreferences.disputeWindowDays + 1,
                                  ),
                                );
                          }
                        },
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                ListTile(
                  title: const Text('Company profile (invoices)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CompanyProfilePage(),
                    ));
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          _SettingsSection(
            title: strings.notifications,
            children: [
              SwitchListTile(
                title: Text(strings.notificationsForClients),
                value: _notifyClients,
                onChanged: (value) => setState(() => _notifyClients = value),
              ),
              SwitchListTile(
                title: Text(strings.notificationsForTeam),
                value: _notifyTeam,
                onChanged: (value) => setState(() => _notifyTeam = value),
              ),
              SwitchListTile(
                title: Text(strings.pushNotifications),
                value: _pushEnabled,
                onChanged: (value) => setState(() => _pushEnabled = value),
              ),
              SwitchListTile(
                title: Text(strings.siriSuggestions),
                value: _siriSuggestions,
                onChanged: (value) => setState(() => _siriSuggestions = value),
              ),
            ],
          ),
          if (session?.role == UserRole.manager)
            _SettingsSection(
              title: strings.deliveryChannels,
              children: [
                SwitchListTile(
                  title: const Text('WhatsApp'),
                  value: _enableWhatsApp,
                  onChanged: (value) => setState(() => _enableWhatsApp = value),
                ),
                SwitchListTile(
                  title: Text(strings.textMessage),
                  value: _enableSms,
                  onChanged: (value) => setState(() => _enableSms = value),
                ),
                SwitchListTile(
                  title: const Text('Email'),
                  value: _enableEmail,
                  onChanged: (value) => setState(() => _enableEmail = value),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
