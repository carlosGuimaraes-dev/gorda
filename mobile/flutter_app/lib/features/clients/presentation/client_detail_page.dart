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
import '../../offline/application/offline_store.dart';

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
    for (final item in state.activeClients) {
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
    final hasDeliveryChannels = current.phone.trim().isNotEmpty ||
        current.whatsappPhone.trim().isNotEmpty ||
        current.email.trim().isNotEmpty;
    final preferredChannels = current.preferredDeliveryChannels
        .map((channel) => _deliveryChannelLabel(strings, channel))
        .join(', ');

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
              key: const ValueKey('client_detail_edit_button'),
              onPressed: () => _showClientForm(context, ref, current),
              icon: const Icon(Icons.edit_outlined),
              tooltip: strings.edit,
            ),
          if (isManager)
            IconButton(
              key: const ValueKey('client_detail_delete_button'),
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
                  Text(
                    strings.client,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DsColorTokens.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(current.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: DsColorTokens.textPrimary)),
                  const SizedBox(height: 12),
                  Text(
                    strings.deliveryChannels,
                    style: const TextStyle(
                      color: DsColorTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (current.phone.trim().isNotEmpty)
                    _channelItem(
                      icon: Icons.phone_outlined,
                      label: strings.phone,
                      value: current.phone.trim(),
                    ),
                  if (current.whatsappPhone.trim().isNotEmpty)
                    _channelItem(
                      icon: Icons.message_outlined,
                      label: strings.whatsapp,
                      value: current.whatsappPhone.trim(),
                    ),
                  if (current.email.trim().isNotEmpty)
                    _channelItem(
                      icon: Icons.alternate_email_outlined,
                      label: strings.email,
                      value: current.email.trim(),
                    ),
                  if (!hasDeliveryChannels)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        strings.noAvailableChannels,
                        style: const TextStyle(
                          color: DsColorTokens.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (preferredChannels.isNotEmpty)
                    _detailItem(strings.deliveryChannels, preferredChannels),
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
                  if (isManager)
                    ListTile(
                      key: const ValueKey('client_detail_create_service_button'),
                      leading: const Icon(Icons.add_circle_outline,
                          color: DsColorTokens.actionPrimary),
                      title: Text(strings.createService,
                          style: const TextStyle(
                              color: DsColorTokens.actionPrimary,
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

  Widget _channelItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: DsColorTokens.actionPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
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

  String _resolveSessionEmployeeId(OfflineState state) {
    final identity = state.session?.name.trim().toLowerCase() ?? '';
    if (identity.isEmpty) return '';
    for (final employee in state.activeEmployees) {
      if (employee.id.trim().toLowerCase() == identity) return employee.id;
      if (employee.name.trim().toLowerCase() == identity) return employee.id;
    }
    return '';
  }

  String _taskSubtitle(String locale, ServiceTask task) {
    final date = DateFormat.yMd(locale).format(task.date);
    if (task.startTime == null) return date;
    return '$date · ${DateFormat.Hm(locale).format(task.startTime!)}';
  }

  String _deliveryChannelLabel(AppStrings strings, DeliveryChannel channel) {
    switch (channel) {
      case DeliveryChannel.email:
        return strings.email;
      case DeliveryChannel.whatsapp:
        return strings.whatsapp;
      case DeliveryChannel.sms:
        return strings.textMessage;
    }
  }

  Future<void> _showClientForm(
      BuildContext context, WidgetRef ref, Client client) async {
    final isManager =
        ref.read(offlineStoreProvider).session?.role == UserRole.manager;
    if (!isManager) return;
    final strings = AppStrings.of(Localizations.localeOf(context));
    final nameCtrl = TextEditingController(text: client.name);
    final phoneCtrl = TextEditingController(text: client.phone);
    final whatsappCtrl = TextEditingController(text: client.whatsappPhone);
    final addressCtrl = TextEditingController(text: client.address);
    final emailCtrl = TextEditingController(text: client.email);
    final propertyCtrl = TextEditingController(text: client.propertyDetails);
    final preferredScheduleCtrl =
        TextEditingController(text: client.preferredSchedule);
    final accessNotesCtrl = TextEditingController(text: client.accessNotes);
    bool enableEmail =
        client.preferredDeliveryChannels.contains(DeliveryChannel.email);
    bool enableWhatsApp =
        client.preferredDeliveryChannels.contains(DeliveryChannel.whatsapp);
    bool enableText =
        client.preferredDeliveryChannels.contains(DeliveryChannel.sms);
    if (client.preferredDeliveryChannels.isEmpty) {
      enableEmail = true;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(strings.editClient),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: const ValueKey('client_form_name'),
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: strings.clientName),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('client_form_phone'),
                        controller: phoneCtrl,
                        decoration: InputDecoration(labelText: strings.phone),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('client_form_whatsapp'),
                        controller: whatsappCtrl,
                        decoration: InputDecoration(labelText: strings.whatsapp),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('client_form_email'),
                        controller: emailCtrl,
                        decoration: InputDecoration(labelText: strings.email),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('client_form_address'),
                        controller: addressCtrl,
                        decoration: InputDecoration(labelText: strings.address),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('client_form_property'),
                        controller: propertyCtrl,
                        decoration: InputDecoration(labelText: strings.property),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('client_form_preferred_schedule'),
                        controller: preferredScheduleCtrl,
                        decoration:
                            InputDecoration(labelText: strings.preferredSchedule),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('client_form_access_notes'),
                        controller: accessNotesCtrl,
                        decoration: InputDecoration(labelText: strings.accessNotes),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.deliveryChannels,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      CheckboxListTile(
                        key: const ValueKey('client_form_channel_email'),
                        value: enableEmail,
                        title: Text(strings.email),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setModalState(() => enableEmail = value ?? false);
                        },
                      ),
                      CheckboxListTile(
                        key: const ValueKey('client_form_channel_whatsapp'),
                        value: enableWhatsApp,
                        title: Text(strings.whatsapp),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setModalState(() => enableWhatsApp = value ?? false);
                        },
                      ),
                      CheckboxListTile(
                        key: const ValueKey('client_form_channel_sms'),
                        value: enableText,
                        title: Text(strings.textMessage),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setModalState(() => enableText = value ?? false);
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
                  key: const ValueKey('client_form_save_button'),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.completeClientName)),
                      );
                      return;
                    }
                    final channels = <DeliveryChannel>[
                      if (enableEmail) DeliveryChannel.email,
                      if (enableWhatsApp) DeliveryChannel.whatsapp,
                      if (enableText) DeliveryChannel.sms,
                    ];
                    ref.read(offlineStoreProvider.notifier).updateClient(
                          client.copyWith(
                            name: name,
                            contact: name,
                            phone: phoneCtrl.text.trim(),
                            whatsappPhone: whatsappCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            propertyDetails: propertyCtrl.text.trim(),
                            preferredSchedule: preferredScheduleCtrl.text.trim(),
                            accessNotes: accessNotesCtrl.text.trim(),
                            preferredDeliveryChannels: channels.isEmpty
                                ? const [DeliveryChannel.email]
                                : channels,
                          ),
                        );
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

  Future<void> _deleteClient(
      BuildContext context, WidgetRef ref, Client client) async {
    final isManager =
        ref.read(offlineStoreProvider).session?.role == UserRole.manager;
    if (!isManager) return;
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
    if (state.session?.role != UserRole.manager) return;
    final strings = AppStrings.of(Localizations.localeOf(context));
    final isManager = state.session?.role == UserRole.manager;
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String employeeId = isManager
        ? (state.activeEmployees.isEmpty ? '' : state.activeEmployees.first.id)
        : _resolveSessionEmployeeId(state);

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
                  if (isManager && state.activeEmployees.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: employeeId,
                      decoration: InputDecoration(labelText: strings.employee),
                      items: state.activeEmployees
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
                  if (title.isEmpty || employeeId.trim().isEmpty) return;
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
