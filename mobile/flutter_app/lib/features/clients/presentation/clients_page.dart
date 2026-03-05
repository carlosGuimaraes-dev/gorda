import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../clients/domain/client.dart';
import '../../employees/domain/employee.dart';
import '../../finance/domain/finance_entry.dart';
import '../../offline/application/offline_store.dart';
import '../../services/domain/service_task.dart';
import 'client_detail_page.dart';
import '../../../core/design/design_theme.dart';
import '../../../core/design/design_tokens.dart';

enum ClientStatusFilter { all, active, inactive }

enum ClientPeriodFilter { all, currentMonth, last30Days }

enum ClientSortOrder { nameAsc, nameDesc, pendingReceivablesDesc }

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  String _searchText = '';
  ClientStatusFilter _statusFilter = ClientStatusFilter.all;
  ClientPeriodFilter _periodFilter = ClientPeriodFilter.all;
  ClientSortOrder _sortOrder = ClientSortOrder.nameAsc;
  String _selectedTeam = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final isManager = state.session?.role == UserRole.manager;

    final teams = _teamOptions(state);
    final clients = _filteredClients(state);

    return Scaffold(
      backgroundColor: DsColorTokens.surfaceSection,
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
          strings.clients,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFiltersSheet(context, teams),
            icon: const Icon(Icons.tune),
            tooltip: strings.filters,
          ),
          if (isManager)
            IconButton(
              key: const ValueKey('clients_add_button'),
              onPressed: _showAddClientDialog,
              icon: const Icon(Icons.add),
              tooltip: strings.newItem,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: strings.searchClient,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),
          Expanded(
            child: clients.isEmpty
                ? Center(
                    child: Text(
                      strings.noClientsForFilter,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppThemeTokens.secondaryText,
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) => _ClientCard(
                      client: clients[index],
                      state: state,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ClientDetailPage(clientId: clients[index].id),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _teamOptions(OfflineState state) {
    final set = <String>{};
    for (final task in state.tasks) {
      final employee = state.employees.firstWhere(
        (item) =>
            item.id == task.assignedEmployeeId ||
            item.name == task.assignedEmployeeId,
        orElse: () => const Employee(id: '', name: '', team: ''),
      );
      if (employee.team.trim().isNotEmpty) {
        set.add(employee.team.trim());
      }
    }
    final values = set.toList()..sort();
    return values;
  }

  List<Client> _filteredClients(OfflineState state) {
    final query = _searchText.trim().toLowerCase();
    final range = _periodRange();

    final clients = state.clients.where((client) {
      final haystack = [
        client.name,
        client.phone,
        client.whatsappPhone,
        client.email,
        client.address,
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || haystack.contains(query);

      final tasks = _tasksForClient(state, client);
      final isActive = tasks.any((task) => task.status != TaskStatus.canceled);
      final matchesStatus = switch (_statusFilter) {
        ClientStatusFilter.all => true,
        ClientStatusFilter.active => isActive,
        ClientStatusFilter.inactive => !isActive,
      };

      final matchesPeriod = range == null
          ? true
          : tasks.any((task) =>
              !task.date.isBefore(range.start) &&
              !task.date.isAfter(range.end));

      final matchesTeam = _selectedTeam.isEmpty
          ? true
          : tasks.any((task) => _teamForTask(state, task) == _selectedTeam);

      return matchesSearch && matchesStatus && matchesPeriod && matchesTeam;
    }).toList();

    switch (_sortOrder) {
      case ClientSortOrder.nameAsc:
        clients.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ClientSortOrder.nameDesc:
        clients.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ClientSortOrder.pendingReceivablesDesc:
        clients.sort((a, b) => _pendingReceivables(state, b)
            .compareTo(_pendingReceivables(state, a)));
        break;
    }
    return clients;
  }

  ({DateTime start, DateTime end})? _periodRange() {
    final now = DateTime.now();
    switch (_periodFilter) {
      case ClientPeriodFilter.all:
        return null;
      case ClientPeriodFilter.currentMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start: start, end: end);
      case ClientPeriodFilter.last30Days:
        return (
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
    }
  }

  String _teamForTask(OfflineState state, ServiceTask task) {
    for (final employee in state.employees) {
      if (employee.id == task.assignedEmployeeId ||
          employee.name == task.assignedEmployeeId) {
        return employee.team;
      }
    }
    return '';
  }

  List<ServiceTask> _tasksForClient(OfflineState state, Client client) {
    return state.tasks.where((task) {
      if (task.clientId != null && task.clientId == client.id) return true;
      return task.clientName == client.name;
    }).toList();
  }

  double _pendingReceivables(OfflineState state, Client client) {
    return state.finance
        .where((entry) =>
            entry.type == FinanceEntryType.receivable &&
            entry.status == FinanceStatus.pending &&
            (entry.clientId == client.id || entry.clientName == client.name))
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  void _showFiltersSheet(BuildContext context, List<String> teamOptions) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final strings = AppStrings.of(Localizations.localeOf(context));
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.clientFilters,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ClientStatusFilter>(
                      value: _statusFilter,
                      decoration: InputDecoration(labelText: strings.status),
                      items: [
                        DropdownMenuItem(
                          value: ClientStatusFilter.all,
                          child: Text(strings.all),
                        ),
                        DropdownMenuItem(
                          value: ClientStatusFilter.active,
                          child: Text(strings.active),
                        ),
                        DropdownMenuItem(
                          value: ClientStatusFilter.inactive,
                          child: Text(strings.inactive),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => _statusFilter = value);
                        setState(() => _statusFilter = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedTeam.isEmpty ? '' : _selectedTeam,
                      decoration: InputDecoration(labelText: strings.team),
                      items: [
                        DropdownMenuItem(
                            value: '', child: Text(strings.allTeams)),
                        ...teamOptions.map(
                          (team) =>
                              DropdownMenuItem(value: team, child: Text(team)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => _selectedTeam = value);
                        setState(() => _selectedTeam = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ClientPeriodFilter>(
                      value: _periodFilter,
                      decoration: InputDecoration(labelText: strings.period),
                      items: [
                        DropdownMenuItem(
                          value: ClientPeriodFilter.all,
                          child: Text(strings.all),
                        ),
                        DropdownMenuItem(
                          value: ClientPeriodFilter.currentMonth,
                          child: Text(strings.currentMonth),
                        ),
                        DropdownMenuItem(
                          value: ClientPeriodFilter.last30Days,
                          child: Text(strings.last30Days),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => _periodFilter = value);
                        setState(() => _periodFilter = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ClientSortOrder>(
                      value: _sortOrder,
                      decoration: InputDecoration(labelText: strings.sortBy),
                      items: [
                        DropdownMenuItem(
                          value: ClientSortOrder.nameAsc,
                          child: Text(strings.nameAsc),
                        ),
                        DropdownMenuItem(
                          value: ClientSortOrder.nameDesc,
                          child: Text(strings.nameDesc),
                        ),
                        DropdownMenuItem(
                          value: ClientSortOrder.pendingReceivablesDesc,
                          child: Text(strings.pendingReceivablesDesc),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => _sortOrder = value);
                        setState(() => _sortOrder = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _statusFilter = ClientStatusFilter.all;
                            _periodFilter = ClientPeriodFilter.all;
                            _sortOrder = ClientSortOrder.nameAsc;
                            _selectedTeam = '';
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(strings.reset),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddClientDialog() async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final propertyCtrl = TextEditingController();
    final preferredScheduleCtrl = TextEditingController();
    final accessNotesCtrl = TextEditingController();
    bool enableEmail = true;
    bool enableWhatsApp = false;
    bool enableText = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(strings.newClient),
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
                    if (name.isEmpty) return;
                    final channels = <DeliveryChannel>[
                      if (enableEmail) DeliveryChannel.email,
                      if (enableWhatsApp) DeliveryChannel.whatsapp,
                      if (enableText) DeliveryChannel.sms,
                    ];
                    ref.read(offlineStoreProvider.notifier).addClient(
                          Client(
                            id: 'client-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            contact: name,
                            phone: phoneCtrl.text.trim(),
                            whatsappPhone: whatsappCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
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
            ),
          },
        );
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.state,
    required this.onTap,
  });

  final Client client;
  final OfflineState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final tasks = state.tasks.where((task) {
      if (task.clientId != null && task.clientId == client.id) return true;
      return task.clientName == client.name;
    }).toList();
    final active = tasks.any((task) => task.status != TaskStatus.canceled);
    final hasPendingReceivables = state.finance.any((entry) {
      return entry.type == FinanceEntryType.receivable &&
          entry.status == FinanceStatus.pending &&
          (entry.clientId == client.id || entry.clientName == client.name);
    });

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
      child: DsCard(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: DsColorTokens.actionPrimary.withOpacity(0.15),
              child: Text(
                _initials(client.name),
                style: const TextStyle(
                  color: DsColorTokens.actionPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          client.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: DsColorTokens.textPrimary,
                              ),
                        ),
                      ),
                      DsStatusPill(
                        label: active ? strings.active : strings.inactive,
                        color: active ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (client.phone.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 13, color: DsColorTokens.actionPrimary),
                        const SizedBox(width: 4),
                        Text(
                          client.phone,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DsColorTokens.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  if (client.phone.isEmpty && client.whatsappPhone.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.message,
                            size: 13, color: DsColorTokens.actionPrimary),
                        const SizedBox(width: 4),
                        Text(
                          client.whatsappPhone,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DsColorTokens.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  if (client.phone.isEmpty &&
                      client.whatsappPhone.isEmpty &&
                      client.email.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.alternate_email_outlined,
                            size: 13, color: DsColorTokens.actionPrimary),
                        const SizedBox(width: 4),
                        Text(
                          client.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DsColorTokens.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  if (client.address.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        client.address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DsColorTokens.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              hasPendingReceivables
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: hasPendingReceivables ? Colors.orange : Colors.green,
              size: 20,
            ),
          ],
        ),
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
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
