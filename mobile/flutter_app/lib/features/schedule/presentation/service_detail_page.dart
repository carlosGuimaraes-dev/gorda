import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../offline/application/offline_store.dart';
import '../../services/domain/service_task.dart';

class ServiceDetailPage extends ConsumerWidget {
  const ServiceDetailPage({
    super.key,
    required this.taskId,
    required this.role,
  });

  final String taskId;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineStoreProvider);
    final strings = AppStrings.of(Localizations.localeOf(context));
    final locale = Localizations.localeOf(context).toLanguageTag();

    ServiceTask? task;
    for (final item in state.tasks) {
      if (item.id == taskId) {
        task = item;
        break;
      }
    }
    if (task == null) {
      return Scaffold(
        backgroundColor: AppThemeTokens.background,
        appBar: AppBar(title: Text(strings.schedule)),
        body: Center(child: Text(strings.taskNotFound)),
      );
    }
    final currentTask = task;

    final startLabel = currentTask.startTime == null
        ? '-'
        : DateFormat.Hm(locale).format(currentTask.startTime!);
    final endLabel = currentTask.endTime == null
        ? '-'
        : DateFormat.Hm(locale).format(currentTask.endTime!);
    final checkInLabel = currentTask.checkInTime == null
        ? '-'
        : DateFormat.yMd(locale).add_Hm().format(currentTask.checkInTime!);
    final checkOutLabel = currentTask.checkOutTime == null
        ? '-'
        : DateFormat.yMd(locale).add_Hm().format(currentTask.checkOutTime!);

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(title: Text(currentTask.title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(context, strings.client, currentTask.clientName),
                _field(context, strings.address, currentTask.address),
                _field(context, strings.date,
                    DateFormat.yMMMMd(locale).format(currentTask.date)),
                _field(context, strings.start, startLabel),
                _field(context, strings.end, endLabel),
                _field(context, strings.status,
                    _statusLabel(strings, currentTask.status)),
                if (currentTask.notes.trim().isNotEmpty)
                  _field(context, strings.notes, currentTask.notes),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.execution,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _field(context, strings.checkIn, checkInLabel),
                _field(context, strings.checkOut, checkOutLabel),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(offlineStoreProvider.notifier)
                            .markTaskCheckIn(currentTask.id, DateTime.now());
                      },
                      child: Text(strings.checkIn),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(offlineStoreProvider.notifier)
                            .markTaskCheckOut(currentTask.id, DateTime.now());
                      },
                      child: Text(strings.checkOut),
                    ),
                    if (role == UserRole.manager)
                      OutlinedButton(
                        onPressed: () {
                          ref
                              .read(offlineStoreProvider.notifier)
                              .advanceTaskStatus(currentTask.id);
                        },
                        child: Text(strings.advanceStatus),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemeTokens.secondaryText,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppStrings strings, TaskStatus status) {
    return switch (status) {
      TaskStatus.scheduled => strings.scheduled,
      TaskStatus.inProgress => strings.inProgress,
      TaskStatus.completed => strings.completed,
      TaskStatus.canceled => strings.canceled,
    };
  }
}
