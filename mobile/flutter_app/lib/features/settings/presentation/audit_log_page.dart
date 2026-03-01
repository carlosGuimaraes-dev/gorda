import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/design_theme.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../offline/application/offline_store.dart';

class AuditLogPage extends ConsumerWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(offlineStoreProvider);
    final sortedEntries = [...store.auditLog]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Audit log',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (sortedEntries.isNotEmpty)
            TextButton(
              onPressed: () => _showClearAlert(context, ref),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: DsBackground(
        child: sortedEntries.isEmpty
          ? const Center(
              child: Text(
                'No audit entries yet.',
                style: TextStyle(color: AppThemeTokens.secondaryText),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sortedEntries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                return DsCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.summary,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: DsColorTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Actor: ${entry.actor}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: DsColorTokens.textSecondary,
                        ),
                      ),
                      Text(
                        'Action: ${entry.action}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: DsColorTokens.textSecondary,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().add_Hms().format(entry.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: DsColorTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }

  void _showClearAlert(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear audit log?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(offlineStoreProvider.notifier).clearAuditLog();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
