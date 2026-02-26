import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../employees/domain/employee.dart';
import '../../finance/domain/finance_entry.dart';
import '../../offline/application/offline_store.dart';

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final isManager = state.session?.role == UserRole.manager;

    final receivables = state.finance
        .where((entry) => entry.type == FinanceEntryType.receivable)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final payables = state.finance
        .where((entry) => entry.type == FinanceEntryType.payable)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final payrollForSession = _payrollForCurrentEmployee(state);

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(
        leading: onMenu == null
            ? null
            : IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu),
              ),
        title: Text(strings.finance),
        actions: [
          if (isManager)
            IconButton(
              onPressed: () => _showAddFinanceDialog(context, ref),
              icon: const Icon(Icons.add),
              tooltip: strings.newItem,
            ),
        ],
      ),
      body: ListView(
        children: [
          if (isManager) ...[
            _FinanceSection(
              title: strings.receivables,
              items: receivables,
            ),
            _FinanceSection(
              title: strings.payables,
              items: payables,
            ),
          ] else ...[
            _FinanceSection(
              title: strings.payroll,
              items: payrollForSession,
              emptyMessage: strings.noPayrollEntriesYet,
            ),
          ],
        ],
      ),
    );
  }

  List<FinanceEntry> _payrollForCurrentEmployee(OfflineState state) {
    final session = state.session;
    if (session == null || session.role != UserRole.employee) return const [];

    final employee = state.employees.firstWhere(
      (item) => item.id == session.name || item.name == session.name,
      orElse: () => const Employee(id: '', name: ''),
    );

    return state.finance.where((entry) {
      if (entry.kind != FinanceKind.payrollEmployee) return false;
      if (entry.employeeId != null && employee.id.isNotEmpty) {
        return entry.employeeId == employee.id;
      }
      return entry.employeeName == session.name;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> _showAddFinanceDialog(
      BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    FinanceEntryType type = FinanceEntryType.receivable;
    FinanceCurrency currency = FinanceCurrency.usd;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.newFinanceEntry),
          content: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: strings.title),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.amount),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<FinanceEntryType>(
                  value: type,
                  decoration: InputDecoration(labelText: strings.type),
                  items: [
                    DropdownMenuItem(
                      value: FinanceEntryType.receivable,
                      child: Text(strings.receivable),
                    ),
                    DropdownMenuItem(
                      value: FinanceEntryType.payable,
                      child: Text(strings.payable),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => type = value);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<FinanceCurrency>(
                  value: currency,
                  decoration: InputDecoration(labelText: strings.currency),
                  items: const [
                    DropdownMenuItem(
                      value: FinanceCurrency.usd,
                      child: Text('USD'),
                    ),
                    DropdownMenuItem(
                      value: FinanceCurrency.eur,
                      child: Text('EUR'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => currency = value);
                  },
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.close),
            ),
            FilledButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (title.isEmpty || amount <= 0) return;

                ref.read(offlineStoreProvider.notifier).addFinanceEntry(
                      FinanceEntry(
                        id: 'fin-${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        amount: amount,
                        currency: currency,
                        type: type,
                        dueDate: DateTime.now(),
                        status: FinanceStatus.pending,
                        kind: FinanceKind.general,
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
  }
}

class _FinanceSection extends StatelessWidget {
  const _FinanceSection({
    required this.title,
    required this.items,
    this.emptyMessage,
  });

  final String title;
  final List<FinanceEntry> items;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppThemeTokens.cardBackground,
        borderRadius: BorderRadius.circular(AppThemeTokens.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                emptyMessage ?? 'No entries.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemeTokens.secondaryText,
                    ),
              ),
            )
          else
            ...items.map((entry) => _FinanceRow(entry: entry)),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({required this.entry});

  final FinanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dueDate = DateFormat.yMd(locale).format(entry.dueDate);
    final amount = NumberFormat.currency(
      name: entry.currency == FinanceCurrency.eur ? 'EUR' : 'USD',
      decimalDigits: 2,
    ).format(entry.amount);
    final statusColor =
        entry.status == FinanceStatus.pending ? Colors.orange : Colors.green;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                amount,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                dueDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemeTokens.secondaryText,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.status == FinanceStatus.pending ? 'Pending' : 'Paid',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
