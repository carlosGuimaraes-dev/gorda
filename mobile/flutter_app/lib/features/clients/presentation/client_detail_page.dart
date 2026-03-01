import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../clients/domain/client.dart';
import '../../schedule/presentation/service_detail_page.dart';
import '../../services/domain/service_task.dart';
import '../../../core/design/design_theme.dart';
import '../../../core/design/design_tokens.dart';

class ClientDetailPage extends ConsumerWidget {
  const ClientDetailPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isManager = state.session?.role == UserRole.manager;

    Client? client;
    for (final item in state.clients) {
      if (item.id == clientId) {
        client = item;
        break;
      }
    }
    if (client == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(strings.clients),
        ),
        body: DsBackground(
          child: Center(child: Text(strings.clientNotFound)),
        ),
      );
    }
    final current = client;
    final tasks = state.tasks.where((task) {
      if (task.clientId != null && task.clientId == current.id) return true;
      return task.clientName == current.name;
    }).toList()
      ..sort(
          (a, b) => (b.startTime ?? b.date).compareTo(a.startTime ?? a.date));

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
        actions: [
          if (isManager)
            IconButton(
              onPressed: () => _showClientForm(context, ref, current),
              icon: const Icon(Icons.edit_outlined),
              tooltip: strings.edit,
            ),
          if (isManager)
            IconButton(
              onPressed: () => _deleteClient(context, ref, current),
              icon: const Icon(Icons.delete_outline),
              tooltip: strings.delete,
            ),
        ],
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
            DsCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: DsColorTokens.textPrimary)),
                  const SizedBox(height: 12),
                  if (current.phone.isNotEmpty)
                    _detailItem(strings.phone, current.phone),
                  if (current.whatsappPhone.isNotEmpty)
                    _detailItem('WhatsApp', current.whatsappPhone),
                  if (current.email.isNotEmpty)
                    _detailItem('Email', current.email),
                  if (current.address.isNotEmpty)
                    _detailItem(strings.address, current.address),
                  if (current.propertyDetails.isNotEmpty)
                    _detailItem(strings.property, current.propertyDetails),
                  if (current.preferredSchedule.isNotEmpty)
                    _detailItem(
                        strings.preferredSchedule, current.preferredSchedule),
                  if (current.accessNotes.isNotEmpty)
                    _detailItem(strings.accessNotes, current.accessNotes),
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
                      strings.serviceHistory,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: DsColorTokens.textPrimary),
                    ),
                  ),
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(strings.noServicesRegisteredYet,
                          style: const TextStyle(
                              color: DsColorTokens.textSecondary)),
                    )
                  else
                    ...tasks.map((task) => ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailPage(
                                taskId: task.id,
                                role: state.session?.role ?? UserRole.manager,
                              ),
                            ),
                          ),
                          title: Text(task.title,
                              style: const TextStyle(
                                  color: DsColorTokens.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(_taskSubtitle(locale, task),
                              style: const TextStyle(
                                  color: DsColorTokens.textSecondary)),
                          trailing: _StatusDot(status: task.status),
                        )),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline,
                        color: DsColorTokens.brandPrimary),
                    title: Text(strings.createService,
                        style: const TextStyle(
                            color: DsColorTokens.brandPrimary,
                            fontWeight: FontWeight.bold)),
                    onTap: () =>
                        _showCreateService(context, ref, current, state),
                  ),
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
            width: 100,
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

  String _taskSubtitle(String locale, ServiceTask task) {
    final date = DateFormat.yMd(locale).format(task.date);
    if (task.startTime == null) return date;
    return '$date · ${DateFormat.Hm(locale).format(task.startTime!)}';
  }

  Future<void> _showClientForm(
      BuildContext context, WidgetRef ref, Client client) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final nameCtrl = TextEditingController(text: client.name);
    final phoneCtrl = TextEditingController(text: client.phone);
    final addressCtrl = TextEditingController(text: client.address);
    final emailCtrl = TextEditingController(text: client.email);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.editClient),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: strings.clientName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(labelText: strings.phone),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(labelText: strings.address),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
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
              ref.read(offlineStoreProvider.notifier).updateClient(
                    client.copyWith(
                      name: name,
                      phone: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                    ),
                  );
              Navigator.of(context).pop();
            },
            child: Text(strings.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient(
      BuildContext context, WidgetRef ref, Client client) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.deleteClientQuestion),
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
    if (!confirmed) return;

    final deleted =
        ref.read(offlineStoreProvider.notifier).deleteClient(client.id);
    if (deleted) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.clientDeleteBlocked)),
    );
  }

  Future<void> _showCreateService(BuildContext context, WidgetRef ref,
      Client client, OfflineState state) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String employeeId = state.employees.isEmpty
        ? (state.session?.name ?? '')
        : state.employees.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(strings.createService),
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
                          setModalState(() => selectedDate = picked);
                        },
                        child: Text(strings.change),
                      ),
                    ],
                  ),
                  if (state.employees.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: employeeId,
                      decoration: InputDecoration(labelText: strings.employee),
                      items: state.employees
                          .map((employee) => DropdownMenuItem(
                                value: employee.id,
                                child: Text(employee.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => employeeId = value);
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
                  if (title.isEmpty) return;
                  ref.read(offlineStoreProvider.notifier).addTask(
                        ServiceTask(
                          id: 'task-${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          date: selectedDate,
                          status: TaskStatus.scheduled,
                          assignedEmployeeId: employeeId,
                          clientId: client.id,
                          clientName: client.name,
                          address: client.address,
                          notes: notesCtrl.text.trim(),
                        ),
                      );
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
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TaskStatus.scheduled => Colors.blue,
      TaskStatus.inProgress => Colors.orange,
      TaskStatus.completed => Colors.green,
      TaskStatus.canceled => Colors.red,
    };
    return Icon(Icons.circle, size: 12, color: color);
  }
}
