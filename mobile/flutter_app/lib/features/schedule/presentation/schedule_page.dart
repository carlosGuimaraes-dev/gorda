import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../offline/application/offline_store.dart';
import '../../services/domain/service_task.dart';
import 'agenda_calendar.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  DateTime _selectedDate = DateTime.now();
  AgendaScope _scope = AgendaScope.day;
  String? _selectedTeam;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final visibleTasks = _visibleTasksForRole(state);
    final eventDates = visibleTasks
        .map((task) => DateTime(task.date.year, task.date.month, task.date.day))
        .toSet();

    final teams =
        widget.role == UserRole.employee ? const <String>[] : _teams(state);
    final scopedTasks = _tasksForSelectedScope(visibleTasks);
    final filteredTasks = scopedTasks.where((task) {
      if (_selectedTeam == null || _selectedTeam!.isEmpty) return true;
      return _teamOfEmployee(state, task.assignedEmployeeId) == _selectedTeam;
    }).toList();

    final groupedByDay = _groupByDay(filteredTasks);

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(
        title: Text(strings.schedule),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(offlineStoreProvider.notifier)
                .syncPendingChangesStub(),
            icon: const Icon(Icons.sync),
            tooltip: strings.forceSync,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 320,
              child: AgendaCalendar(
                selectedDate: _selectedDate,
                eventDates: eventDates,
                onDateSelected: (value) =>
                    setState(() => _selectedDate = value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<AgendaScope>(
              segments: [
                ButtonSegment(value: AgendaScope.day, label: Text(strings.day)),
                ButtonSegment(
                    value: AgendaScope.month, label: Text(strings.month)),
              ],
              selected: {_scope},
              onSelectionChanged: (value) =>
                  setState(() => _scope = value.first),
            ),
          ),
          if (teams.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _selectedTeam,
                decoration: InputDecoration(labelText: strings.team),
                hint: Text(strings.allTeams),
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(strings.allTeams),
                  ),
                  ...teams.map((team) => DropdownMenuItem<String>(
                        value: team,
                        child: Text(team),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value == null || value.isEmpty) {
                      _selectedTeam = null;
                    } else {
                      _selectedTeam = value;
                    }
                  });
                },
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(child: Text(strings.noTasksForFilter))
                : _scope == AgendaScope.day
                    ? ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) => _TaskRow(
                          task: filteredTasks[index],
                          employeeName: _employeeNameById(
                              state, filteredTasks[index].assignedEmployeeId),
                          role: widget.role,
                        ),
                      )
                    : ListView(
                        children: groupedByDay.entries.map((entry) {
                          final day = entry.key;
                          final tasks = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    DateFormat.yMMMMd(
                                            Localizations.localeOf(context)
                                                .toLanguageTag())
                                        .format(day),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                ...tasks.map((task) => _TaskRow(
                                      task: task,
                                      employeeName: _employeeNameById(
                                          state, task.assignedEmployeeId),
                                      role: widget.role,
                                    )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  List<String> _teams(OfflineState state) {
    final set = <String>{};
    for (final employee in state.employees) {
      if (employee.team.trim().isNotEmpty) set.add(employee.team.trim());
    }
    final result = set.toList()..sort();
    return result;
  }

  List<ServiceTask> _visibleTasksForRole(OfflineState state) {
    if (widget.role == UserRole.manager) return state.tasks;

    final session = state.session;
    if (session == null) return const [];

    return state.tasks
        .where((task) => task.assignedEmployeeId == session.name)
        .toList();
  }

  List<ServiceTask> _tasksForSelectedScope(List<ServiceTask> tasks) {
    return tasks.where((task) {
      if (_scope == AgendaScope.day) {
        return _isSameDay(task.date, _selectedDate);
      }
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month;
    }).toList()
      ..sort(
          (a, b) => (a.startTime ?? a.date).compareTo(b.startTime ?? b.date));
  }

  Map<DateTime, List<ServiceTask>> _groupByDay(List<ServiceTask> tasks) {
    final groups = <DateTime, List<ServiceTask>>{};
    for (final task in tasks) {
      final day = DateTime(task.date.year, task.date.month, task.date.day);
      groups.putIfAbsent(day, () => []);
      groups[day]!.add(task);
    }
    final sortedKeys = groups.keys.toList()..sort();
    final sorted = <DateTime, List<ServiceTask>>{};
    for (final key in sortedKeys) {
      final dayTasks = groups[key]!
        ..sort(
            (a, b) => (a.startTime ?? a.date).compareTo(b.startTime ?? b.date));
      sorted[key] = dayTasks;
    }
    return sorted;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String? _employeeNameById(OfflineState state, String id) {
    for (final employee in state.employees) {
      if (employee.id == id) return employee.name;
    }
    return null;
  }

  String? _teamOfEmployee(OfflineState state, String id) {
    for (final employee in state.employees) {
      if (employee.id == id) return employee.team;
    }
    return null;
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow(
      {required this.task, required this.employeeName, required this.role});

  final ServiceTask task;
  final String? employeeName;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeFormat = DateFormat.Hm(locale);

    final start =
        task.startTime == null ? null : timeFormat.format(task.startTime!);
    final end = task.endTime == null ? null : timeFormat.format(task.endTime!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 6),
          if (start != null)
            Text(
              end == null ? start : '$start - $end',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppThemeTokens.secondaryText),
            ),
          Text('${strings.client}: ${task.clientName}'),
          Text(
            task.address,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppThemeTokens.secondaryText),
          ),
          if (role == UserRole.manager && employeeName != null)
            Text(
              '${strings.employee}: $employeeName',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppThemeTokens.secondaryText),
            ),
          if (task.notes.trim().isNotEmpty)
            Text(
              task.notes,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppThemeTokens.secondaryText),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final color = switch (status) {
      TaskStatus.scheduled => Colors.blue,
      TaskStatus.inProgress => Colors.orange,
      TaskStatus.completed => Colors.green,
      TaskStatus.canceled => Colors.red,
    };

    final label = switch (status) {
      TaskStatus.scheduled => strings.scheduled,
      TaskStatus.inProgress => strings.inProgress,
      TaskStatus.completed => strings.completed,
      TaskStatus.canceled => strings.canceled,
    };

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

enum AgendaScope { day, month }
