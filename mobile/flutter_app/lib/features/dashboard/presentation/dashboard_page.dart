import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../employees/domain/employee.dart';
import '../../finance/domain/finance_entry.dart';
import '../../offline/application/offline_store.dart';
import '../../services/domain/service_task.dart';
import '../../../core/design/design_theme.dart';
import '../../../core/design/design_tokens.dart';

enum DashboardScope { day, week, month }

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DashboardScope _scope = DashboardScope.day;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final role = state.session?.role;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onMenu == null
            ? null
            : IconButton(
                onPressed: widget.onMenu,
                icon: const Icon(Icons.menu),
              ),
        title: Text(
          strings.dashboard,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<DashboardScope>(
              segments: [
                ButtonSegment(
                    value: DashboardScope.day, label: Text(strings.day)),
                ButtonSegment(
                    value: DashboardScope.week, label: Text(strings.week)),
                ButtonSegment(
                    value: DashboardScope.month, label: Text(strings.month)),
              ],
              selected: {_scope},
              onSelectionChanged: (value) =>
                  setState(() => _scope = value.first),
            ),
          ),
          Expanded(
            child: role == null
                ? Center(
                    child: Text(
                      strings.noActiveSession,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppThemeTokens.secondaryText,
                          ),
                    ),
                  )
                : role == UserRole.employee
                    ? _EmployeeDashboard(scope: _scope)
                    : _ManagerDashboard(scope: _scope),
          ),
        ],
      ),
    );
  }
}

class _EmployeeDashboard extends ConsumerWidget {
  const _EmployeeDashboard({required this.scope});

  final DashboardScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final session = state.session;

    if (session == null) return const SizedBox.shrink();

    final employee = _findEmployee(state, session.name);
    final employeeTasks = state.tasks.where((task) {
      final matchesEmployee = task.assignedEmployeeId == session.name ||
          (employee != null && task.assignedEmployeeId == employee.id);
      return matchesEmployee && _matchesScope(task.date, scope);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final scheduledCount = employeeTasks
        .where((task) => task.status == TaskStatus.scheduled)
        .length;
    final inProgressCount = employeeTasks
        .where((task) => task.status == TaskStatus.inProgress)
        .length;
    final completedCount = employeeTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;

    final totalWorkedHours = employeeTasks.fold<double>(0, (sum, task) {
      final checkIn = task.checkInTime;
      final checkOut = task.checkOutTime;
      if (checkIn == null || checkOut == null) return sum;
      final hours = checkOut.difference(checkIn).inMinutes / 60.0;
      return hours > 0 ? sum + hours : sum;
    });

    final hourlyRate = employee?.hourlyRate;
    final estimatedEarnings =
        hourlyRate == null ? null : totalWorkedHours * hourlyRate;
    final currency = employee?.currency == EmployeeCurrency.eur ? 'EUR' : 'USD';
    final currencyFmt = NumberFormat.currency(name: currency, decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        DsCard(
          child: Text(
            '${strings.hello}, ${session.name}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DsColorTokens.textPrimary,
                ),
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.workload,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DsColorTokens.textPrimary,
                      )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _MetricStat(
                          label: strings.scheduled, value: '$scheduledCount')),
                  Expanded(
                      child: _MetricStat(
                          label: strings.inProgress,
                          value: '$inProgressCount')),
                  Expanded(
                      child: _MetricStat(
                          label: strings.completed, value: '$completedCount')),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.todayLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DsColorTokens.textPrimary,
                      )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricStat(
                      label: strings.workedHours,
                      value: '${totalWorkedHours.toStringAsFixed(1)} h',
                      alignEnd: false,
                    ),
                  ),
                  if (estimatedEarnings != null)
                    Expanded(
                      child: _MetricStat(
                        label: strings.estimatedEarnings,
                        value: currencyFmt.format(estimatedEarnings),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (employeeTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                strings.noServicesInPeriod,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DsColorTokens.textSecondary,
                    ),
              ),
            ),
          )
        else
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.nextServices,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DsColorTokens.textPrimary,
                        )),
                const SizedBox(height: 8),
                ...employeeTasks
                    .take(5)
                    .map((task) => _DashboardTaskRow(task: task)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ManagerDashboard extends ConsumerWidget {
  const _ManagerDashboard({required this.scope});

  final DashboardScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final tasksForScope =
        state.tasks.where((task) => _matchesScope(task.date, scope)).toList();

    final completedCount = tasksForScope
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final pendingReceivables = state.finance
        .where((entry) =>
            entry.type == FinanceEntryType.receivable &&
            entry.status == FinanceStatus.pending)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final pendingPayables = state.finance
        .where((entry) =>
            entry.type == FinanceEntryType.payable &&
            entry.status == FinanceStatus.pending)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final netPending = pendingReceivables - pendingPayables;

    final currencyFmt = NumberFormat.currency(name: 'USD', decimalDigits: 2);
    final teamSummary = _buildTeamSummary(state, tasksForScope);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.operations,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DsColorTokens.textPrimary,
                      )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricStat(
                      label: strings.totalTasks,
                      value: '${tasksForScope.length}',
                      alignEnd: false,
                    ),
                  ),
                  Expanded(
                    child: _MetricStat(
                      label: strings.completed,
                      value: '$completedCount',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (teamSummary.isNotEmpty)
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.byTeam,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DsColorTokens.textPrimary,
                        )),
                const SizedBox(height: 8),
                ...teamSummary.map((summary) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(summary.team)),
                          Text(
                            '${summary.completed}/${summary.total} ${strings.completed.toLowerCase()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppThemeTokens.secondaryText),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.finance,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DsColorTokens.textPrimary,
                      )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricStat(
                      label: strings.receivables,
                      value: currencyFmt.format(pendingReceivables),
                      alignEnd: false,
                      valueColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _MetricStat(
                      label: strings.payables,
                      value: currencyFmt.format(pendingPayables),
                      valueColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    strings.netCashPending,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DsColorTokens.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    currencyFmt.format(netPending),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: netPending >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricStat extends StatelessWidget {
  const _MetricStat({
    required this.label,
    required this.value,
    this.alignEnd = true,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DsColorTokens.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: valueColor ?? DsColorTokens.textPrimary,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}

class _DashboardTaskRow extends StatelessWidget {
  const _DashboardTaskRow({required this.task});

  final ServiceTask task;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMd(locale).format(task.date);
    final timeLabel = task.startTime == null
        ? ''
        : DateFormat.Hm(locale).format(task.startTime!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            timeLabel.isEmpty ? dateLabel : '$dateLabel · $timeLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemeTokens.secondaryText,
                ),
          ),
          const SizedBox(height: 4),
          DsStatusPill(label: _labelForStatus(strings, task.status), color: _colorForStatus(task.status)),
          const Divider(height: 20),
        ],
      ),
    );
  }
}

String _labelForStatus(AppStrings strings, TaskStatus status) {
  return switch (status) {
    TaskStatus.scheduled => strings.scheduled,
    TaskStatus.inProgress => strings.inProgress,
    TaskStatus.completed => strings.completed,
    TaskStatus.canceled => strings.canceled,
  };
}

Color _colorForStatus(TaskStatus status) {
  return switch (status) {
    TaskStatus.scheduled => Colors.blue,
    TaskStatus.inProgress => Colors.orange,
    TaskStatus.completed => Colors.green,
    TaskStatus.canceled => Colors.red,
  };
}

bool _matchesScope(DateTime date, DashboardScope scope) {
  final now = DateTime.now();
  if (scope == DashboardScope.day) {
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  if (scope == DashboardScope.month) {
    return date.year == now.year && date.month == now.month;
  }

  final weekdayFromMonday = now.weekday - DateTime.monday;
  final weekStart = DateTime(now.year, now.month, now.day - weekdayFromMonday);
  final weekEnd = weekStart.add(const Duration(days: 7));
  return !date.isBefore(weekStart) && date.isBefore(weekEnd);
}

Employee? _findEmployee(OfflineState state, String sessionNameOrId) {
  for (final employee in state.employees) {
    if (employee.id == sessionNameOrId || employee.name == sessionNameOrId) {
      return employee;
    }
  }
  return null;
}

List<({String team, int total, int completed})> _buildTeamSummary(
    OfflineState state, List<ServiceTask> tasks) {
  final grouped = <String, List<ServiceTask>>{};
  for (final task in tasks) {
    final employee = state.employees.firstWhere(
      (item) =>
          item.id == task.assignedEmployeeId ||
          item.name == task.assignedEmployeeId,
      orElse: () => const Employee(id: '', name: '', team: ''),
    );
    final team =
        employee.team.trim().isEmpty ? 'No team' : employee.team.trim();
    grouped.putIfAbsent(team, () => []);
    grouped[team]!.add(task);
  }

  final rows = grouped.entries.map((entry) {
    final completed =
        entry.value.where((task) => task.status == TaskStatus.completed).length;
    return (team: entry.key, total: entry.value.length, completed: completed);
  }).toList();
  rows.sort((a, b) => a.team.compareTo(b.team));
  return rows;
}
