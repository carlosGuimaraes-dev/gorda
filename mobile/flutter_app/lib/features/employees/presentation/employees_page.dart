import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../employees/domain/employee.dart';
import '../../finance/domain/finance_entry.dart';
import '../../offline/application/offline_store.dart';

class EmployeesPage extends ConsumerWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final employees = [...state.employees]
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(
        title: Text(strings.employees),
        actions: [
          IconButton(
            onPressed: () => _showEmployeeFormDialog(context, ref),
            icon: const Icon(Icons.add),
            tooltip: strings.newItem,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          final hasPendingPayables = state.finance.any((entry) =>
              entry.employeeName == employee.name &&
              entry.type == FinanceEntryType.payable &&
              entry.status == FinanceStatus.pending);

          return ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeDetailPage(employeeId: employee.id),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: AppThemeTokens.primary.withOpacity(0.15),
              child: Text(
                _initials(employee.name),
                style: const TextStyle(
                  color: AppThemeTokens.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(employee.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employee.roleTitle.isNotEmpty) Text(employee.roleTitle),
                if (employee.team.isNotEmpty)
                  Text('${strings.team}: ${employee.team}'),
                if (employee.phone != null && employee.phone!.isNotEmpty)
                  Text(employee.phone!),
              ],
            ),
            trailing: Icon(
              hasPendingPayables
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: hasPendingPayables ? Colors.orange : Colors.green,
            ),
          );
        },
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class EmployeeDetailPage extends ConsumerWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final state = ref.watch(offlineStoreProvider);
    Employee? employee;
    for (final item in state.employees) {
      if (item.id == employeeId) {
        employee = item;
        break;
      }
    }
    if (employee == null) {
      return Scaffold(
        backgroundColor: AppThemeTokens.background,
        appBar: AppBar(title: Text(strings.employees)),
        body: Center(child: Text(strings.employeeNotFound)),
      );
    }
    final current = employee;
    final assignedTasks = state.tasks
        .where((task) => task.assignedEmployeeId == current.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(
        title: Text(current.name),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(strings.editEmployee),
            onTap: () => _showEmployeeFormDialog(
              context,
              ref,
              employee: current,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              strings.deleteEmployee,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(strings.deleteEmployeeQuestion),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(strings.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(strings.delete),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!confirmDelete) return;

              final deleted = ref
                  .read(offlineStoreProvider.notifier)
                  .deleteEmployee(current.id);
              if (deleted) {
                if (context.mounted) Navigator.of(context).pop();
                return;
              }
              if (!context.mounted) return;
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(strings.cannotDeleteEmployee),
                  content: Text(strings.employeeDeleteBlocked),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.close),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(title: Text('${strings.roleTitle}: ${current.roleTitle}')),
          ListTile(title: Text('${strings.team}: ${current.team}')),
          if (current.phone != null && current.phone!.isNotEmpty)
            ListTile(title: Text('${strings.phone}: ${current.phone!}')),
          if (current.hourlyRate != null)
            ListTile(
              title: Text(
                  '${strings.hourlyRate}: ${(current.currency == EmployeeCurrency.eur ? 'EUR' : 'USD')} ${current.hourlyRate!.toStringAsFixed(2)}'),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              strings.assignedServices,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (assignedTasks.isEmpty)
            ListTile(title: Text(strings.noAssignedServices))
          else
            ...assignedTasks.map((task) => ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    DateFormat.yMd(locale).add_Hm().format(task.date),
                  ),
                )),
        ],
      ),
    );
  }
}

Future<void> _showEmployeeFormDialog(
  BuildContext context,
  WidgetRef ref, {
  Employee? employee,
}) async {
  final strings = AppStrings.of(Localizations.localeOf(context));
  final nameCtrl = TextEditingController(text: employee?.name ?? '');
  final roleCtrl = TextEditingController(text: employee?.roleTitle ?? '');
  final teamCtrl = TextEditingController(text: employee?.team ?? '');
  final phoneCtrl = TextEditingController(text: employee?.phone ?? '');
  final rateCtrl = TextEditingController(
    text: employee?.hourlyRate == null ? '' : '${employee!.hourlyRate}',
  );
  EmployeeCurrency currency = employee?.currency ?? EmployeeCurrency.usd;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title:
              Text(employee == null ? strings.newEmployee : strings.editEmployee),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: strings.name),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: roleCtrl,
                  decoration: InputDecoration(labelText: strings.roleTitle),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: teamCtrl,
                  decoration: InputDecoration(labelText: strings.team),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: strings.phone),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: rateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.hourlyRate),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EmployeeCurrency>(
                  value: currency,
                  decoration: InputDecoration(labelText: strings.currency),
                  items: const [
                    DropdownMenuItem(
                      value: EmployeeCurrency.usd,
                      child: Text('USD'),
                    ),
                    DropdownMenuItem(
                      value: EmployeeCurrency.eur,
                      child: Text('EUR'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => currency = value);
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final rate = double.tryParse(rateCtrl.text.trim());

                if (employee == null) {
                  ref.read(offlineStoreProvider.notifier).addEmployee(
                        Employee(
                          id: 'emp-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          roleTitle: roleCtrl.text.trim(),
                          team: teamCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                          hourlyRate: rate,
                          currency: currency,
                        ),
                      );
                } else {
                  ref.read(offlineStoreProvider.notifier).updateEmployee(
                        employee.copyWith(
                          name: name,
                          roleTitle: roleCtrl.text.trim(),
                          team: teamCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                          hourlyRate: rate,
                          currency: currency,
                        ),
                      );
                }
                Navigator.of(context).pop();
              },
              child: Text(strings.save),
            ),
          ],
        );
      });
    },
  );
}
