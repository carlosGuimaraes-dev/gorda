import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../employees/domain/employee.dart';
import '../../offline/application/offline_store.dart';

class TeamsPage extends ConsumerWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final teams = [...state.teams]..sort((a, b) => a.name.compareTo(b.name));
    final membersByTeam = _groupTeams(state.employees);
    final teamNames = teams.map((team) => team.name).toList();
    final unassigned = state.employees
        .where((employee) => employee.team.trim().isEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(
        title: Text(strings.teams),
        actions: [
          IconButton(
            onPressed: () => _showTeamFormDialog(context, ref),
            icon: const Icon(Icons.add),
            tooltip: strings.newTeam,
          ),
        ],
      ),
      body: ListView(
        children: [
          if (teams.isEmpty && unassigned.isEmpty)
            ListTile(title: Text(strings.noEmployeesYet)),
          for (final team in teams)
            ExpansionTile(
              title: Text('${team.name} (${membersByTeam[team.name]?.length ?? 0})'),
              children: [
                ...(membersByTeam[team.name] ?? const <Employee>[]).map(
                  (employee) => _TeamEmployeeRow(
                    employee: employee,
                    teamOptions: teamNames,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(strings.editTeam),
                  onTap: () => _showTeamFormDialog(
                    context,
                    ref,
                    existingTeamName: team.name,
                    initiallySelectedIds:
                        (membersByTeam[team.name] ?? const <Employee>[])
                            .map((employee) => employee.id)
                            .toSet(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    strings.removeTeam,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(strings.deleteTeamQuestion),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(strings.cancel),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(strings.delete),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!confirmDelete) return;
                    ref.read(offlineStoreProvider.notifier).deleteTeam(team.name);
                  },
                ),
              ],
            ),
          if (unassigned.isNotEmpty)
            ExpansionTile(
              title: Text(strings.unassigned),
              initiallyExpanded: true,
              children: unassigned
                  .map(
                    (employee) => _TeamEmployeeRow(
                      employee: employee,
                      teamOptions: teamNames,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Map<String, List<Employee>> _groupTeams(List<Employee> employees) {
    final groups = <String, List<Employee>>{};
    for (final employee in employees) {
      final team = employee.team.trim();
      if (team.isEmpty) continue;
      groups.putIfAbsent(team, () => []);
      groups[team]!.add(employee);
    }
    final sortedKeys = groups.keys.toList()..sort();
    final sorted = <String, List<Employee>>{};
    for (final key in sortedKeys) {
      final members = [...groups[key]!]..sort((a, b) => a.name.compareTo(b.name));
      sorted[key] = members;
    }
    return sorted;
  }
}

class _TeamEmployeeRow extends ConsumerWidget {
  const _TeamEmployeeRow({
    required this.employee,
    required this.teamOptions,
  });

  final Employee employee;
  final List<String> teamOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));

    return ListTile(
      title: Text(employee.name),
      subtitle:
          Text(employee.team.isEmpty ? strings.unassigned : employee.team),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          ref.read(offlineStoreProvider.notifier).updateEmployee(
                employee.copyWith(team: value),
              );
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: '',
              child: Text(strings.removeFromTeam),
            ),
          ];
          for (final team in teamOptions) {
            if (team == employee.team) continue;
            items.add(
              PopupMenuItem<String>(
                value: team,
                child: Text('${strings.moveTo} $team'),
              ),
            );
          }
          return items;
        },
      ),
    );
  }
}

Future<void> _showTeamFormDialog(
  BuildContext context,
  WidgetRef ref, {
  String? existingTeamName,
  Set<String>? initiallySelectedIds,
}) async {
  final strings = AppStrings.of(Localizations.localeOf(context));
  final state = ref.read(offlineStoreProvider);
  final allEmployees = [...state.employees]..sort((a, b) => a.name.compareTo(b.name));
  final nameCtrl = TextEditingController(text: existingTeamName ?? '');
  final selectedIds = Set<String>.from(initiallySelectedIds ?? <String>{});

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existingTeamName == null ? strings.newTeam : strings.editTeam,
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: strings.name),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.assignEmployees,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final employee in allEmployees)
                      CheckboxListTile(
                        value: selectedIds.contains(employee.id),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(employee.name),
                        subtitle: employee.team.trim().isEmpty
                            ? null
                            : Text('${strings.team}: ${employee.team}'),
                        onChanged: (checked) {
                          setModalState(() {
                            if (checked == true) {
                              selectedIds.add(employee.id);
                            } else {
                              selectedIds.remove(employee.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.close),
              ),
              FilledButton(
                onPressed: () {
                  final teamName = nameCtrl.text.trim();
                  if (teamName.isEmpty) return;

                  final existingNames = state.teams
                      .map((team) => team.name.trim())
                      .where((name) => name.isNotEmpty)
                      .toSet();
                  final currentName = existingTeamName?.trim() ?? '';
                  final takenByOtherTeam = existingNames.any(
                    (name) =>
                        name.toLowerCase() == teamName.toLowerCase() &&
                        name.toLowerCase() != currentName.toLowerCase(),
                  );
                  if (takenByOtherTeam) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.teamNameAlreadyExists)),
                    );
                    return;
                  }

                  final notifier = ref.read(offlineStoreProvider.notifier);
                  final saved = existingTeamName == null
                      ? notifier.createTeam(
                          teamName: teamName,
                          memberIds: selectedIds.toList(),
                        )
                      : notifier.updateTeam(
                          oldName: existingTeamName!,
                          newName: teamName,
                          memberIds: selectedIds.toList(),
                        );
                  if (!saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.unableToSaveTeam)),
                    );
                    return;
                  }
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
