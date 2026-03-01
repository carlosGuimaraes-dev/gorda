import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/design/design_theme.dart';
import '../../../core/design/design_tokens.dart';
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.employees,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showEmployeeFormDialog(context, ref),
            icon: const Icon(Icons.add),
            tooltip: strings.newItem,
          ),
        ],
      ),
      body: DsBackground(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            final hasPendingPayables = state.finance.any((entry) =>
                entry.employeeName == employee.name &&
                entry.type == FinanceEntryType.payable &&
                entry.status == FinanceStatus.pending);

            return Column(
              children: [
                if (index == 0) const SizedBox(height: kToolbarHeight + 10),
                DsCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeDetailPage(employeeId: employee.id),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: DsColorTokens.brandPrimary.withOpacity(0.15),
                      child: Text(
                        _initials(employee.name),
                        style: const TextStyle(
                          color: DsColorTokens.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(employee.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: DsColorTokens.textPrimary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (employee.roleTitle.isNotEmpty)
                          Text(employee.roleTitle,
                              style: const TextStyle(
                                  color: DsColorTokens.textSecondary)),
                        if (employee.team.isNotEmpty)
                          Text('${strings.team}: ${employee.team}',
                              style: const TextStyle(
                                  color: DsColorTokens.textSecondary)),
                        if (employee.phone != null && employee.phone!.isNotEmpty)
                          Text(employee.phone!,
                              style: const TextStyle(
                                  color: DsColorTokens.textSecondary)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPendingPayables
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: hasPendingPayables
                              ? DsColorTokens.statusWarning
                              : DsColorTokens.statusSuccess,
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEmployeeFormDialog(context, ref,
                                  employee: employee);
                              return;
                            }
                            if (value == 'delete') {
                              _deleteEmployeeFromList(context, ref, employee);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(strings.editEmployee),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(strings.deleteEmployee),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteEmployeeFromList(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
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

    final deleted =
        ref.read(offlineStoreProvider.notifier).deleteEmployee(employee.id);
    if (deleted) return;
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(strings.employees),
        ),
        body: DsBackground(
          child: Center(child: Text(strings.employeeNotFound)),
        ),
      );
    }
    final current = employee;
    final assignedTasks = state.tasks
        .where((task) => task.assignedEmployeeId == current.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          current.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
            DsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined,
                        color: DsColorTokens.brandPrimary),
                    title: Text(strings.editEmployee,
                        style: const TextStyle(
                            color: DsColorTokens.brandPrimary,
                            fontWeight: FontWeight.bold)),
                    onTap: () => _showEmployeeFormDialog(
                      context,
                      ref,
                      employee: current,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: DsColorTokens.statusError),
                    title: Text(
                      strings.deleteEmployee,
                      style: const TextStyle(
                          color: DsColorTokens.statusError,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(strings.deleteEmployeeQuestion),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailItem(strings.roleTitle, current.roleTitle),
                  _detailItem(strings.team, current.team),
                  if (current.phone != null && current.phone!.isNotEmpty)
                    _detailItem(strings.phone, current.phone!),
                  if (current.hourlyRate != null)
                    _detailItem(strings.hourlyRate,
                        '${(current.currency == EmployeeCurrency.eur ? 'EUR' : 'USD')} ${current.hourlyRate!.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DsCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      strings.assignedServices,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: DsColorTokens.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (assignedTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(strings.noAssignedServices,
                          style: const TextStyle(
                              color: DsColorTokens.textSecondary)),
                    )
                  else
                    ...assignedTasks.map((task) => ListTile(
                          title: Text(task.title,
                              style: const TextStyle(
                                  color: DsColorTokens.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            DateFormat.yMd(locale).add_Hm().format(task.date),
                            style: const TextStyle(
                                color: DsColorTokens.textSecondary),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: DsColorTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: DsColorTokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
          title: Text(
              employee == null ? strings.newEmployee : strings.editEmployee),
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
