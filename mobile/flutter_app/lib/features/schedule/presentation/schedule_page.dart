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
import 'service_detail_page.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key, required this.role, this.onMenu});

  final UserRole role;
  final VoidCallback? onMenu;

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
        leading: widget.onMenu == null
            ? null
            : IconButton(
                onPressed: widget.onMenu,
                icon: const Icon(Icons.menu),
              ),
        title: Text(strings.schedule),
        actions: [
          IconButton(
            onPressed: () => _showNewServiceDialog(context, state),
            icon: const Icon(Icons.add),
            tooltip: strings.newService,
          ),
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
              height: 360,
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
                          onTap: () => _openTask(context, filteredTasks[index]),
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
                                      onTap: () => _openTask(context, task),
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

  void _openTask(BuildContext context, ServiceTask task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailPage(taskId: task.id, role: widget.role),
      ),
    );
  }

  Future<void> _showNewServiceDialog(
      BuildContext context, OfflineState state) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final titleCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = _selectedDate;
    DateTime startTime =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0);
    DateTime endTime = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
    String assignedEmployeeId = '';
    if (widget.role == UserRole.manager && state.employees.isNotEmpty) {
      assignedEmployeeId = state.employees.first.id;
    } else {
      assignedEmployeeId = state.session?.name ?? '';
    }
    if (state.employees.isNotEmpty &&
        !state.employees.any((employee) => employee.id == assignedEmployeeId)) {
      assignedEmployeeId = state.employees.first.id;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(strings.newService),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(labelText: strings.title),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: clientCtrl,
                      decoration: InputDecoration(labelText: strings.client),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(labelText: strings.address),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(labelText: strings.notes),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${strings.date}: ${DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(selectedDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked == null) return;
                            setModalState(() {
                              selectedDate = DateTime(
                                  picked.year, picked.month, picked.day);
                              startTime = DateTime(selectedDate.year,
                                  selectedDate.month, selectedDate.day, 9, 0);
                              endTime = DateTime(selectedDate.year,
                                  selectedDate.month, selectedDate.day, 10, 0);
                            });
                          },
                          child: Text(strings.change),
                        ),
                      ],
                    ),
                    if (state.employees.isNotEmpty &&
                        widget.role == UserRole.manager)
                      DropdownButtonFormField<String>(
                        value: assignedEmployeeId,
                        decoration:
                            InputDecoration(labelText: strings.employee),
                        items: state.employees
                            .map((employee) => DropdownMenuItem(
                                  value: employee.id,
                                  child: Text(employee.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => assignedEmployeeId = value);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.close),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final clientName = clientCtrl.text.trim();
                    if (title.isEmpty || clientName.isEmpty) return;
                    final address = addressCtrl.text.trim();
                    ref.read(offlineStoreProvider.notifier).addTask(
                          ServiceTask(
                            id: 'task-${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            date: selectedDate,
                            status: TaskStatus.scheduled,
                            assignedEmployeeId: assignedEmployeeId,
                            clientName: clientName,
                            address: address,
                            startTime: startTime,
                            endTime: endTime,
                            notes: notesCtrl.text.trim(),
                          ),
                        );
                    setState(() => _selectedDate = selectedDate);
                    Navigator.of(context).pop();
                  },
                  child: Text(strings.save),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow(
      {required this.task,
      required this.employeeName,
      required this.role,
      required this.onTap});

  final ServiceTask task;
  final String? employeeName;
  final UserRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeFormat = DateFormat.Hm(locale);

    final start =
        task.startTime == null ? null : timeFormat.format(task.startTime!);
    final end = task.endTime == null ? null : timeFormat.format(task.endTime!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppThemeTokens.cornerRadius),
      child: AppCard(
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
        color: color.withOpacity(0.12),
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
