import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../offline/application/offline_store.dart';

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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppThemeTokens.cardBackground,
        borderRadius: BorderRadius.circular(AppThemeTokens.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
