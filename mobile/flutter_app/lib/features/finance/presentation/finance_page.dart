import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/design_theme.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_session.dart';
import '../../clients/domain/client.dart';
import '../../employees/domain/employee.dart';
import '../../offline/application/offline_store.dart';
import '../../services/domain/service_task.dart';
import '../../services/domain/service_type.dart';
import '../domain/finance_entry.dart';

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
    final employeePayrollEntries = _payrollForCurrentEmployee(state);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: onMenu == null
            ? null
            : IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
        title: Text(
          strings.finance,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isManager)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GenericFinanceFormPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              tooltip: strings.newItem,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: DsSpaceTokens.space16),
        children: [
          if (isManager) ...[
            DsSectionContainer(
              title: strings.closingFlow,
              children: [
                _FinanceNavigationTile(
                  title: strings.closingWizard,
                  icon: Icons.format_list_numbered,
                  onTap: () => _openPage(
                    context,
                    const MonthlyClosingWizardPage(),
                  ),
                ),
                _FinanceNavigationTile(
                  title: strings.receiptsHub,
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _openPage(
                    context,
                    const ReceiptsHubPage(),
                  ),
                ),
                _FinanceNavigationTile(
                  title: strings.readyToEmit,
                  icon: Icons.send_outlined,
                  onTap: () => _openPage(
                    context,
                    const EmissionReadyPage(),
                  ),
                ),
              ],
            ),
            DsSectionContainer(
              title: strings.endOfMonth,
              children: [
                _FinanceActionTile(
                  title: strings.generateClientInvoices,
                  icon: Icons.description_outlined,
                  onTap: () => _openPage(
                    context,
                    const InvoiceGeneratorPage(),
                  ),
                ),
                _FinanceActionTile(
                  title: strings.generatePayroll,
                  icon: Icons.badge_outlined,
                  onTap: () => _openPage(
                    context,
                    const PayrollGeneratorPage(),
                  ),
                ),
              ],
            ),
            DsSectionContainer(
              title: strings.invoicesAndPayroll,
              children: [
                _FinanceNavigationTile(
                  title: strings.invoices,
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _openPage(
                    context,
                    const InvoicesListPage(),
                  ),
                ),
                _FinanceNavigationTile(
                  title: strings.payroll,
                  icon: Icons.payments_outlined,
                  onTap: () => _openPage(
                    context,
                    const PayrollListPage(),
                  ),
                ),
              ],
            ),
            DsSectionContainer(
              title: strings.reports,
              children: [
                _FinanceNavigationTile(
                  title: strings.monthlyReports,
                  icon: Icons.bar_chart_outlined,
                  onTap: () => _openPage(
                    context,
                    const ReportsPage(),
                  ),
                ),
              ],
            ),
            _FinanceEntriesSection(
              title: strings.receivables,
              entries: receivables,
            ),
            _FinanceEntriesSection(
              title: strings.payables,
              entries: payables,
            ),
          ] else ...[
            _FinanceEntriesSection(
              title: strings.payroll,
              entries: employeePayrollEntries,
              emptyMessage: strings.noPayrollEntriesYet,
            ),
          ],
        ],
      ),
    );
  }

  static List<FinanceEntry> _payrollForCurrentEmployee(OfflineState state) {
    final session = state.session;
    if (session == null || session.role != UserRole.employee) {
      return const [];
    }

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

  static void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _FinanceNavigationTile extends StatelessWidget {
  const _FinanceNavigationTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DsSpaceTokens.space1,
      ),
      dense: true,
      leading: Icon(icon, color: DsColorTokens.brandPrimary),
      title: Text(
        title,
        style: const TextStyle(
          color: DsColorTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: DsColorTokens.textMuted),
      onTap: onTap,
    );
  }
}

class _FinanceActionTile extends StatelessWidget {
  const _FinanceActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DsSpaceTokens.space1,
      ),
      dense: true,
      leading: Icon(icon, color: DsColorTokens.brandPrimary),
      title: Text(
        title,
        style: const TextStyle(
          color: DsColorTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _FinanceEntriesSection extends StatelessWidget {
  const _FinanceEntriesSection({
    required this.title,
    required this.entries,
    this.emptyMessage,
  });

  final String title;
  final List<FinanceEntry> entries;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));

    return DsSectionContainer(
      title: title,
      children: [
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpaceTokens.space2),
            child: Text(
              emptyMessage ?? strings.noEntries,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: DsColorTokens.textSecondary),
            ),
          )
        else
          ...entries.map(
            (entry) => InkWell(
              borderRadius: BorderRadius.circular(DsRadiusTokens.radiusLg),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FinanceEntryDetailRouterPage(entry: entry),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DsSpaceTokens.space2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: const TextStyle(
                              fontSize: DsTypeTokens.textBase,
                              fontWeight: DsTypeTokens.fontSemibold,
                            ),
                          ),
                          const SizedBox(height: DsSpaceTokens.space1),
                          Text(
                            _formatDate(context, entry.dueDate),
                            style: const TextStyle(
                              color: DsColorTokens.textSecondary,
                              fontSize: DsTypeTokens.textXs,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: DsSpaceTokens.space2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(entry.amount, entry.currency),
                          style: const TextStyle(
                            fontWeight: DsTypeTokens.fontSemibold,
                            fontSize: DsTypeTokens.textSm,
                          ),
                        ),
                        const SizedBox(height: DsSpaceTokens.space1),
                        DsStatusPill(
                          label: _statusLabel(strings, entry.status),
                          color: _statusColor(entry.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MonthlyClosingWizardPage extends ConsumerStatefulWidget {
  const MonthlyClosingWizardPage({super.key});

  @override
  ConsumerState<MonthlyClosingWizardPage> createState() =>
      _MonthlyClosingWizardPageState();
}

class _MonthlyClosingWizardPageState
    extends ConsumerState<MonthlyClosingWizardPage> {
  DateTime selectedMonth = DateTime.now();
  int stepIndex = 0;

  List<String> _stepTitles(AppStrings strings) {
    return [
      strings.period,
      strings.pending,
      strings.review,
      strings.ready,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final monthRange = _monthRange(selectedMonth);
    final pendingOutOfPocketReceipts = state.finance.where((entry) {
      return entry.kind == FinanceKind.expenseOutOfPocket &&
          entry.status == FinanceStatus.pending &&
          _isInRange(entry.dueDate, monthRange.start, monthRange.end);
    }).toList();

    final receiptsWithoutClientCount = pendingOutOfPocketReceipts.where((entry) {
      return (entry.clientId == null || entry.clientId!.isEmpty) &&
          (entry.clientName == null || entry.clientName!.isEmpty);
    }).length;

    final syncConflictsCount = state.conflictLog.length;
    final blockingIssuesCount = receiptsWithoutClientCount + syncConflictsCount;

    final draftInvoices = state.finance.where((entry) {
      return entry.kind == FinanceKind.invoiceClient &&
          entry.status == FinanceStatus.pending &&
          _isInRange(entry.dueDate, monthRange.start, monthRange.end);
    }).toList();

    final draftPayrolls = state.finance.where((entry) {
      return entry.kind == FinanceKind.payrollEmployee &&
          entry.status == FinanceStatus.pending &&
          _isInRange(entry.dueDate, monthRange.start, monthRange.end);
    }).toList();

    final invoicesTotal = draftInvoices.fold<double>(0, (sum, e) => sum + e.amount);
    final payrollTotal = draftPayrolls.fold<double>(0, (sum, e) => sum + e.amount);

    final stepTitles = _stepTitles(strings);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.monthlyClosing,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (stepIndex > 0)
            TextButton(
              onPressed: () => setState(() => stepIndex -= 1),
              child: Text(strings.back),
            ),
        ],
      ),
      body: DsBackground(
        child: ListView(
        padding: const EdgeInsets.all(DsSpaceTokens.space4),
        children: [
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.closingPeriod,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Row(
                  children: [
                    Text(_monthLabel(context, selectedMonth)),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: selectedMonth,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (selected == null) return;
                        setState(
                          () => selectedMonth = DateTime(
                            selected.year,
                            selected.month,
                            1,
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Row(
              children: [
                for (var i = 0; i < stepTitles.length; i++) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: DsSpaceTokens.space6,
                          height: DsSpaceTokens.space6,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i <= stepIndex
                                ? DsColorTokens.actionPrimary
                                : DsColorTokens.surfaceSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: i <= stepIndex
                                  ? DsColorTokens.textOnBrand
                                  : DsColorTokens.textSecondary,
                              fontSize: DsTypeTokens.textSm,
                              fontWeight: DsTypeTokens.fontSemibold,
                            ),
                          ),
                        ),
                        const SizedBox(height: DsSpaceTokens.space1),
                        Text(
                          stepTitles[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: i == stepIndex
                                ? DsColorTokens.actionPrimary
                                : DsColorTokens.textSecondary,
                            fontSize: DsTypeTokens.textXs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildWizardStepContent(
            strings: strings,
            stepIndex: stepIndex,
            receiptsWithoutClientCount: receiptsWithoutClientCount,
            syncConflictsCount: syncConflictsCount,
            draftInvoices: draftInvoices,
            draftPayrolls: draftPayrolls,
            invoicesTotal: invoicesTotal,
            payrollTotal: payrollTotal,
            currency: state.appPreferences.preferredCurrency,
          ),
        ],
      ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: stepIndex == stepTitles.length - 1
            ? strings.finishClosing
            : strings.continueLabel,
        onPressed: () {
          if (stepIndex == 1 && blockingIssuesCount > 0) {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.resolvePendingIssuesFirst),
                content: Text(strings.resolvePendingIssuesHelp),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.close),
                  ),
                ],
              ),
            );
            return;
          }

          if (stepIndex == stepTitles.length - 1) {
            Navigator.of(context).pop();
            return;
          }

          setState(() => stepIndex += 1);
        },
      ),
    );
  }

  Widget _buildWizardStepContent({
    required AppStrings strings,
    required int stepIndex,
    required int receiptsWithoutClientCount,
    required int syncConflictsCount,
    required List<FinanceEntry> draftInvoices,
    required List<FinanceEntry> draftPayrolls,
    required double invoicesTotal,
    required double payrollTotal,
    required FinanceCurrency currency,
  }) {
    switch (stepIndex) {
      case 0:
        return DsCard(
          margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.stepSelectPeriod,
                style: const TextStyle(
                  fontSize: DsTypeTokens.textBase,
                  fontWeight: DsTypeTokens.fontSemibold,
                ),
              ),
              const SizedBox(height: DsSpaceTokens.space2),
              Text(
                strings.stepSelectPeriodHelp,
                style: const TextStyle(color: DsColorTokens.textSecondary),
              ),
            ],
          ),
        );
      case 1:
        return DsCard(
          margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.stepPendingChecks,
                style: const TextStyle(
                  fontSize: DsTypeTokens.textBase,
                  fontWeight: DsTypeTokens.fontSemibold,
                ),
              ),
              const SizedBox(height: DsSpaceTokens.space2),
              _SummaryRow(
                label: strings.receiptsWithoutClientLink,
                value: '$receiptsWithoutClientCount',
                valueColor: receiptsWithoutClientCount == 0
                    ? DsColorTokens.statusSuccess
                    : DsColorTokens.statusWarning,
              ),
              _SummaryRow(
                label: strings.syncConflicts,
                value: '$syncConflictsCount',
                valueColor: syncConflictsCount == 0
                    ? DsColorTokens.statusSuccess
                    : DsColorTokens.statusWarning,
              ),
              if (receiptsWithoutClientCount + syncConflictsCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: DsSpaceTokens.space2),
                  child: Text(
                    strings.resolveTheseItems,
                    style: const TextStyle(
                      color: DsColorTokens.textSecondary,
                      fontSize: DsTypeTokens.textSm,
                    ),
                  ),
                ),
            ],
          ),
        );
      case 2:
        return DsCard(
          margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.stepReviewTotals,
                style: const TextStyle(
                  fontSize: DsTypeTokens.textBase,
                  fontWeight: DsTypeTokens.fontSemibold,
                ),
              ),
              const SizedBox(height: DsSpaceTokens.space2),
              _SummaryRow(
                label: strings.invoices,
                value: '${draftInvoices.length}',
              ),
              _SummaryRow(
                label: strings.payroll,
                value: '${draftPayrolls.length}',
              ),
              const Divider(),
              _SummaryRow(
                label: strings.receivables,
                value: _formatCurrency(invoicesTotal, currency),
                valueColor: DsColorTokens.statusSuccess,
              ),
              _SummaryRow(
                label: strings.payables,
                value: _formatCurrency(payrollTotal, currency),
                valueColor: DsColorTokens.statusError,
              ),
            ],
          ),
        );
      default:
        return DsCard(
          margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.stepReadyToEmit,
                style: const TextStyle(
                  fontSize: DsTypeTokens.textBase,
                  fontWeight: DsTypeTokens.fontSemibold,
                ),
              ),
              const SizedBox(height: DsSpaceTokens.space2),
              Text(
                strings.stepReadyToEmitHelp,
                style: const TextStyle(color: DsColorTokens.textSecondary),
              ),
            ],
          ),
        );
    }
  }
}

class ReceiptsHubPage extends ConsumerStatefulWidget {
  const ReceiptsHubPage({super.key});

  @override
  ConsumerState<ReceiptsHubPage> createState() => _ReceiptsHubPageState();
}

class _ReceiptsHubPageState extends ConsumerState<ReceiptsHubPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final pendingSyncCount = state.pendingChanges.length;
    final nowDay = DateTime.now();
    final suggestedTask = state.tasks.where((task) {
      final dayStart = DateTime(nowDay.year, nowDay.month, nowDay.day);
      return !task.date.isBefore(dayStart) && task.status != TaskStatus.canceled;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final firstTask = suggestedTask.isEmpty ? null : suggestedTask.first;

    Client? suggestedClient;
    if (firstTask != null) {
      if (firstTask.clientId != null) {
        suggestedClient = state.clients.firstWhere(
          (client) => client.id == firstTask.clientId,
          orElse: () => const Client(id: '', name: ''),
        );
        if (suggestedClient.id.isEmpty) {
          suggestedClient = null;
        }
      }
      suggestedClient ??= state.clients.firstWhere(
        (client) => client.name == firstTask.clientName,
        orElse: () => const Client(id: '', name: ''),
      );
      if (suggestedClient.id.isEmpty) {
        suggestedClient = null;
      }
    }

    final latestReceipts = state.finance
        .where((entry) =>
            entry.kind == FinanceKind.expenseOutOfPocket &&
            entry.receiptData != null)
        .toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.receipts,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
        padding: const EdgeInsets.all(DsSpaceTokens.space4),
        children: [
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.receiptQueue,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _SummaryRow(
                  label: strings.offlineQueue,
                  value: '$pendingSyncCount',
                  valueColor: pendingSyncCount == 0
                      ? DsColorTokens.statusSuccess
                      : DsColorTokens.statusWarning,
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextButton.icon(
                  onPressed: () {
                    ref.read(offlineStoreProvider.notifier).syncPendingChangesStub();
                  },
                  icon: const Icon(Icons.sync),
                  label: Text(strings.forceSyncNow),
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.suggestedContext,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                if (firstTask == null)
                  Text(
                    strings.noSuggestedTask,
                    style: const TextStyle(color: DsColorTokens.textSecondary),
                  )
                else ...[
                  Text('${strings.task}: ${firstTask.title}'),
                  const SizedBox(height: DsSpaceTokens.space1),
                  Text(
                    '${strings.client}: ${suggestedClient?.name ?? firstTask.clientName}',
                    style: const TextStyle(color: DsColorTokens.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.latestLocalReceipts,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                if (latestReceipts.isEmpty)
                  Text(
                    strings.noReceiptsCapturedYet,
                    style: const TextStyle(color: DsColorTokens.textSecondary),
                  )
                else
                  ...latestReceipts.take(5).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: DsSpaceTokens.space2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      style: const TextStyle(
                                        fontSize: DsTypeTokens.textSm,
                                        fontWeight: DsTypeTokens.fontSemibold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(context, entry.dueDate),
                                      style: const TextStyle(
                                        fontSize: DsTypeTokens.textXs,
                                        color: DsColorTokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatCurrency(entry.amount, entry.currency),
                                style: const TextStyle(
                                  fontWeight: DsTypeTokens.fontSemibold,
                                  color: DsColorTokens.statusError,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.scanNew,
        leadingIcon: Icons.camera_alt,
        onPressed: () async {
          try {
            final image = await _picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 70,
            );
            if (image == null || !mounted) return;
            final bytes = await image.readAsBytes();
            if (!mounted) return;

            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return QuickReceiptEntrySheet(
                  imageBytes: bytes,
                  suggestedClientId: suggestedClient?.id,
                  clients: state.clients,
                  onSave: (title, amount, dueDate, clientId) {
                    final client = state.clients.firstWhere(
                      (value) => value.id == clientId,
                      orElse: () => const Client(id: '', name: ''),
                    );
                    ref.read(offlineStoreProvider.notifier).addFinanceEntry(
                          FinanceEntry(
                            id: 'fin-${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            amount: amount,
                            currency: state.appPreferences.preferredCurrency,
                            type: FinanceEntryType.payable,
                            dueDate: dueDate,
                            status: FinanceStatus.pending,
                            kind: FinanceKind.expenseOutOfPocket,
                            clientId: client.id.isEmpty ? null : client.id,
                            clientName: client.id.isEmpty ? null : client.name,
                            receiptData: bytes,
                          ),
                        );
                  },
                );
              },
            );
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.cameraUnavailableMessage)),
            );
          }
        },
      ),
    );
  }
}

class QuickReceiptEntrySheet extends StatefulWidget {
  const QuickReceiptEntrySheet({
    super.key,
    required this.imageBytes,
    required this.clients,
    required this.onSave,
    this.suggestedClientId,
  });

  final Uint8List imageBytes;
  final List<Client> clients;
  final String? suggestedClientId;
  final void Function(
    String title,
    double amount,
    DateTime dueDate,
    String? clientId,
  ) onSave;

  @override
  State<QuickReceiptEntrySheet> createState() => _QuickReceiptEntrySheetState();
}

class _QuickReceiptEntrySheetState extends State<QuickReceiptEntrySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  DateTime _dueDate = DateTime.now();
  String? _selectedClientId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Out-of-pocket expense');
    _amountController = TextEditingController();
    _selectedClientId = widget.suggestedClientId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final canSave =
        _titleController.text.trim().isNotEmpty && amount != null && amount > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DsSpaceTokens.space4,
        DsSpaceTokens.space4,
        DsSpaceTokens.space4,
        viewInsets + DsSpaceTokens.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DsRadiusTokens.radiusLg),
            child: Image.memory(
              widget.imageBytes,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: DsSpaceTokens.space3),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: strings.title),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: DsSpaceTokens.space2),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: strings.amount),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: DsSpaceTokens.space2),
          Row(
            children: [
              Text(strings.dueDate),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (selected == null) return;
                  setState(() => _dueDate = selected);
                },
                child: Text(_formatDate(context, _dueDate)),
              ),
            ],
          ),
          const SizedBox(height: DsSpaceTokens.space2),
          DropdownButtonFormField<String?>(
            value: _selectedClientId,
            decoration: InputDecoration(labelText: strings.clientOptional),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(strings.unlinked),
              ),
              ...widget.clients.map(
                (client) => DropdownMenuItem<String?>(
                  value: client.id,
                  child: Text(client.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedClientId = value),
          ),
          const SizedBox(height: DsSpaceTokens.space3),
          DsPrimaryButton(
            title: strings.saveReceipt,
            isDisabled: !canSave,
            onPressed: () {
              final parsedAmount =
                  double.parse(_amountController.text.replaceAll(',', '.'));
              widget.onSave(
                _titleController.text.trim(),
                parsedAmount,
                _dueDate,
                _selectedClientId,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class EmissionReadyPage extends ConsumerWidget {
  const EmissionReadyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final pendingInvoices = state.finance.where((entry) {
      return entry.kind == FinanceKind.invoiceClient &&
          entry.status == FinanceStatus.pending;
    }).toList();

    final pendingPayrolls = state.finance.where((entry) {
      return entry.kind == FinanceKind.payrollEmployee &&
          entry.status == FinanceStatus.pending;
    }).toList();

    final pendingInvoicesTotal =
        pendingInvoices.fold<double>(0, (sum, entry) => sum + entry.amount);
    final pendingPayrollTotal =
        pendingPayrolls.fold<double>(0, (sum, entry) => sum + entry.amount);

    final enabledChannels = <String>[];
    if (state.appPreferences.enableWhatsApp) {
      enabledChannels.add('WhatsApp');
    }
    if (state.appPreferences.enableEmail) {
      enabledChannels.add(strings.email);
    }
    if (state.appPreferences.enableTextMessages) {
      enabledChannels.add(strings.textMessage);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.emission,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.readyForEmission,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _SummaryRow(
                  label: strings.invoices,
                  value: '${pendingInvoices.length}',
                ),
                _SummaryRow(
                  label: strings.payroll,
                  value: '${pendingPayrolls.length}',
                ),
                const Divider(),
                _SummaryRow(
                  label: strings.receivables,
                  value: _formatCurrency(
                    pendingInvoicesTotal,
                    state.appPreferences.preferredCurrency,
                  ),
                  valueColor: DsColorTokens.statusSuccess,
                ),
                _SummaryRow(
                  label: strings.payables,
                  value: _formatCurrency(
                    pendingPayrollTotal,
                    state.appPreferences.preferredCurrency,
                  ),
                  valueColor: DsColorTokens.statusError,
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.deliveryChannels,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Text(
                  '${strings.primaryLabel}: '
                  '${enabledChannels.isEmpty ? strings.notConfigured : enabledChannels.first}',
                ),
                const SizedBox(height: DsSpaceTokens.space1),
                Text(
                  '${strings.fallbackLabel}: '
                  '${enabledChannels.length > 1 ? enabledChannels[1] : strings.notConfigured}',
                  style: const TextStyle(color: DsColorTokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.emitNow,
        leadingIcon: Icons.send,
        isDisabled: pendingInvoices.isEmpty,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InvoicesListPage()),
          );
        },
      ),
    );
  }
}

class FinanceEntryDetailRouterPage extends StatelessWidget {
  const FinanceEntryDetailRouterPage({super.key, required this.entry});

  final FinanceEntry entry;

  @override
  Widget build(BuildContext context) {
    switch (entry.kind) {
      case FinanceKind.invoiceClient:
        return InvoiceDetailPage(entry: entry);
      case FinanceKind.payrollEmployee:
        return PayrollDetailPage(entry: entry);
      case FinanceKind.expenseOutOfPocket:
        return ExpenseDetailPage(entry: entry);
      case FinanceKind.general:
        return GenericFinanceDetailPage(entry: entry);
    }
  }
}

class InvoicesListPage extends ConsumerWidget {
  const InvoicesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final invoices = ref.watch(offlineStoreProvider).finance.where((entry) {
      return entry.kind == FinanceKind.invoiceClient;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.invoices,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InvoiceFormPage()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: DsBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final entry = invoices[index];
            return Column(
              children: [
                if (index == 0) const SizedBox(height: kToolbarHeight + 10),
                DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: InkWell(
              borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailPage(entry: entry),
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontWeight: DsTypeTokens.fontSemibold,
                          ),
                        ),
                        const SizedBox(height: DsSpaceTokens.space1),
                        Text(
                          '${entry.clientName ?? strings.unknown} · '
                          '${_formatDate(context, entry.dueDate)}',
                          style: const TextStyle(
                            fontSize: DsTypeTokens.textXs,
                            color: DsColorTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: DsSpaceTokens.space1),
                        Wrap(
                          spacing: DsSpaceTokens.space1,
                          children: [
                            DsStatusPill(
                              label: _statusLabel(strings, entry.status),
                              color: _statusColor(entry.status),
                            ),
                            if (entry.isDisputed)
                              DsStatusPill(
                                label: strings.disputed,
                                color: DsColorTokens.statusError,
                              ),
                            if (entry.supersededById != null)
                              DsStatusPill(
                                label: strings.superseded,
                                color: DsColorTokens.textMuted,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DsSpaceTokens.space2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(entry.amount, entry.currency),
                        style: const TextStyle(
                          fontWeight: DsTypeTokens.fontSemibold,
                        ),
                      ),
                      const SizedBox(height: DsSpaceTokens.space1),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            ref
                                .read(offlineStoreProvider.notifier)
                                .deleteFinanceEntry(entry.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(strings.delete),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class InvoiceFormPage extends ConsumerStatefulWidget {
  const InvoiceFormPage({super.key});

  @override
  ConsumerState<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends ConsumerState<InvoiceFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _selectedClientId = '';
  FinancePaymentMethod? _method;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final clients = [...state.clients]..sort((a, b) => a.name.compareTo(b.name));
    final selectedClient = clients.firstWhere(
      (client) => client.id == _selectedClientId,
      orElse: () => const Client(id: '', name: ''),
    );

    if (_selectedClientId.isEmpty && clients.isNotEmpty) {
      _selectedClientId = clients.first.id;
      _titleController.text = '${strings.invoiceLabel} - ${clients.first.name}';
    }

    final parsedAmount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    final canSave = _titleController.text.trim().isNotEmpty &&
        _selectedClientId.isNotEmpty &&
        parsedAmount != null &&
        parsedAmount > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.newInvoice,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: strings.title),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: InputDecoration(labelText: strings.client),
                  items: clients
                      .map(
                        (client) => DropdownMenuItem<String>(
                          value: client.id,
                          child: Text(client.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final client = clients.firstWhere(
                      (item) => item.id == value,
                      orElse: () => const Client(id: '', name: ''),
                    );
                    setState(() {
                      _selectedClientId = value;
                      if (_titleController.text.trim().isEmpty ||
                          _titleController.text.startsWith('${strings.invoiceLabel} -')) {
                        _titleController.text = '${strings.invoiceLabel} - ${client.name}';
                      }
                    });
                  },
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.amount),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Row(
                  children: [
                    Text(strings.currency),
                    const Spacer(),
                    Text(_currencyCode(state.appPreferences.preferredCurrency)),
                  ],
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Row(
                  children: [
                    Text(strings.dueDate),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (selected == null) return;
                        setState(() => _dueDate = selected);
                      },
                      child: Text(_formatDate(context, _dueDate)),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinancePaymentMethod?>(
                  value: _method,
                  decoration: InputDecoration(labelText: strings.method),
                  items: [
                    DropdownMenuItem<FinancePaymentMethod?>(
                      value: null,
                      child: Text(strings.none),
                    ),
                    ...FinancePaymentMethod.values.map(
                      (method) => DropdownMenuItem<FinancePaymentMethod?>(
                        value: method,
                        child: Text(_methodLabel(strings, method)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.save,
        isDisabled: !canSave,
        onPressed: () {
          final amount =
              double.parse(_amountController.text.trim().replaceAll(',', '.'));
          ref.read(offlineStoreProvider.notifier).addFinanceEntry(
                FinanceEntry(
                  id: 'fin-${DateTime.now().millisecondsSinceEpoch}',
                  title: _titleController.text.trim(),
                  amount: amount,
                  currency: state.appPreferences.preferredCurrency,
                  type: FinanceEntryType.receivable,
                  dueDate: _dueDate,
                  status: FinanceStatus.pending,
                  method: _method,
                  clientId: selectedClient.id,
                  clientName: selectedClient.name,
                  kind: FinanceKind.invoiceClient,
                ),
              );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class InvoiceDetailPage extends ConsumerStatefulWidget {
  const InvoiceDetailPage({super.key, required this.entry});

  final FinanceEntry entry;

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _dueDate;
  FinancePaymentMethod? _method;
  FinanceStatus _status = FinanceStatus.pending;
  bool _isDisputed = false;
  final TextEditingController _disputeReasonController = TextEditingController();
  DeliveryChannel _selectedChannel = DeliveryChannel.email;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _amountController =
        TextEditingController(text: widget.entry.amount.toStringAsFixed(2));
    _dueDate = widget.entry.dueDate;
    _method = widget.entry.method;
    _status = widget.entry.status;
    _isDisputed = widget.entry.isDisputed;
    _disputeReasonController.text = widget.entry.disputeReason ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _disputeReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final store = ref.read(offlineStoreProvider.notifier);

    final entry = state.finance.firstWhere(
      (item) => item.id == widget.entry.id,
      orElse: () => widget.entry,
    );

    final client = state.clients.firstWhere(
      (item) => item.id == entry.clientId || item.name == entry.clientName,
      orElse: () => const Client(id: '', name: ''),
    );

    final hasClient = client.id.isNotEmpty;
    final lineItems = store.lineItemsForInvoice(entry);
    final lineItemTotal = lineItems.fold<double>(0, (sum, item) => sum + item.total);

    final disputeDeadline = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
    ).add(Duration(days: state.appPreferences.disputeWindowDays + 1));
    final disputeWindowOpen = DateTime.now().isBefore(disputeDeadline);
    final isSuperseded = entry.supersededById != null;

    final managerChannels = <DeliveryChannel>[];
    if (state.appPreferences.enableWhatsApp) {
      managerChannels.add(DeliveryChannel.whatsapp);
    }
    if (state.appPreferences.enableTextMessages) {
      managerChannels.add(DeliveryChannel.sms);
    }
    if (state.appPreferences.enableEmail) {
      managerChannels.add(DeliveryChannel.email);
    }

    final availableChannels = managerChannels.where((channel) {
      if (!hasClient) return false;
      if (client.preferredDeliveryChannels.isNotEmpty &&
          !client.preferredDeliveryChannels.contains(channel)) {
        return false;
      }
      return _channelHasContact(channel, client);
    }).toList();

    if (availableChannels.isNotEmpty &&
        !availableChannels.contains(_selectedChannel)) {
      _selectedChannel = availableChannels.first;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final canAdjustInvoice = _canAdjustInvoice(_dueDate, isSuperseded);
    final canSave = !isSuperseded &&
        amount != null &&
        amount > 0 &&
        _titleController.text.trim().isNotEmpty &&
        (!_isDisputed || _disputeReasonController.text.trim().isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.invoice,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  enabled: canAdjustInvoice,
                  decoration: InputDecoration(labelText: strings.title),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _amountController,
                  enabled: canAdjustInvoice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.amount),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Row(
                  children: [
                    Text(strings.currency),
                    const Spacer(),
                    Text(_currencyCode(state.appPreferences.preferredCurrency)),
                  ],
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Row(
                  children: [
                    Text(strings.dueDate),
                    const Spacer(),
                    TextButton(
                      onPressed: canAdjustInvoice
                          ? () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: _dueDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (selected == null) return;
                              setState(() => _dueDate = selected);
                            }
                          : null,
                      child: Text(_formatDate(context, _dueDate)),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinancePaymentMethod?>(
                  value: _method,
                  decoration: InputDecoration(labelText: strings.method),
                  items: [
                    DropdownMenuItem<FinancePaymentMethod?>(
                      value: null,
                      child: Text(strings.none),
                    ),
                    ...FinancePaymentMethod.values.map(
                      (method) => DropdownMenuItem<FinancePaymentMethod?>(
                        value: method,
                        child: Text(_methodLabel(strings, method)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinanceStatus>(
                  value: _status,
                  decoration: InputDecoration(labelText: strings.status),
                  items: FinanceStatus.values
                      .map(
                        (status) => DropdownMenuItem<FinanceStatus>(
                          value: status,
                          child: Text(_statusLabel(strings, status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.lineItems,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                ...lineItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: DsSpaceTokens.space2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.serviceTypeName,
                                style: const TextStyle(
                                  fontWeight: DsTypeTokens.fontSemibold,
                                ),
                              ),
                            ),
                            Text(_formatCurrency(item.total, entry.currency)),
                          ],
                        ),
                        const SizedBox(height: DsSpaceTokens.space1),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: DsTypeTokens.textSm,
                            color: DsColorTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: DsSpaceTokens.space1),
                        Text(
                          '${strings.qty}: '
                          '${_quantityLabel(strings, item.pricingModel, item.quantity)} · '
                          '${strings.unit}: ${_formatCurrency(item.unitPrice, entry.currency)} · '
                          '${strings.total}: ${_formatCurrency(item.total, entry.currency)}',
                          style: const TextStyle(
                            fontSize: DsTypeTokens.textXs,
                            color: DsColorTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                _SummaryRow(
                  label: strings.total,
                  value: _formatCurrency(lineItemTotal, entry.currency),
                  valueColor: DsColorTokens.actionPrimary,
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.dispute,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.clientDisputed),
                  value: _isDisputed,
                  onChanged: (!disputeWindowOpen && !_isDisputed)
                      ? null
                      : (value) => setState(() => _isDisputed = value),
                ),
                TextField(
                  controller: _disputeReasonController,
                  enabled: _isDisputed,
                  minLines: 2,
                  maxLines: 4,
                  decoration:
                      InputDecoration(labelText: strings.clientMessageReason),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Text(
                  disputeWindowOpen
                      ? _disputeWindowOpenText(strings, disputeDeadline,
                          state.appPreferences.disputeWindowDays)
                      : strings.disputeWindowClosedOn(_formatDate(context, disputeDeadline)),
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textXs,
                    color: DsColorTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.sendInvoice,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                if (isSuperseded)
                  Text(
                    strings.supersededOn(
                      entry.supersededAt == null
                          ? strings.unknown
                          : _formatDateTime(context, entry.supersededAt!),
                    ),
                    style: const TextStyle(
                      color: DsColorTokens.textSecondary,
                      fontSize: DsTypeTokens.textSm,
                    ),
                  ),
                if (availableChannels.isEmpty)
                  Text(
                    strings.noAvailableChannels,
                    style: const TextStyle(
                      color: DsColorTokens.textSecondary,
                    ),
                  )
                else ...[
                  DropdownButtonFormField<DeliveryChannel>(
                    value: _selectedChannel,
                    decoration: InputDecoration(labelText: strings.channel),
                    items: availableChannels
                        .map(
                          (channel) => DropdownMenuItem<DeliveryChannel>(
                            value: channel,
                            child: Text(_deliveryChannelLabel(strings, channel)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedChannel = value);
                    },
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
                  OutlinedButton.icon(
                    onPressed: () {
                      _shareInvoiceText(
                        strings: strings,
                        entry: entry,
                        lineItems: lineItems,
                        clientName: hasClient ? client.name : null,
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: Text(strings.sendReissue),
                  ),
                  const SizedBox(height: DsSpaceTokens.space1),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final data = await _buildInvoicePdf(
                        strings: strings,
                        state: state,
                        entry: entry,
                        lineItems: lineItems,
                        dueDate: _dueDate,
                        amount: amount ?? entry.amount,
                        disputeReason: _disputeReasonController.text.trim(),
                        isDisputed: _isDisputed,
                        client: hasClient ? client : null,
                      );
                      if (!mounted) return;
                      await Printing.layoutPdf(onLayout: (_) async => data);
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(strings.previewPdf),
                  ),
                  const SizedBox(height: DsSpaceTokens.space1),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final data = await _buildInvoicePdf(
                        strings: strings,
                        state: state,
                        entry: entry,
                        lineItems: lineItems,
                        dueDate: _dueDate,
                        amount: amount ?? entry.amount,
                        disputeReason: _disputeReasonController.text.trim(),
                        isDisputed: _isDisputed,
                        client: hasClient ? client : null,
                      );
                      if (!mounted) return;
                      await Printing.sharePdf(
                        bytes: data,
                        filename:
                            '${entry.title.replaceAll(' ', '-').toLowerCase()}.pdf',
                      );
                    },
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(strings.sharePdf),
                  ),
                ],
                if (!canAdjustInvoice)
                  Padding(
                    padding: const EdgeInsets.only(top: DsSpaceTokens.space2),
                    child: Text(
                      strings.adjustmentsBlocked,
                      style: const TextStyle(
                        fontSize: DsTypeTokens.textXs,
                        color: DsColorTokens.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: OutlinedButton.icon(
              onPressed: isSuperseded
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(strings.reissueInvoiceQuestion),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(strings.cancel),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text(strings.reissueInvoice),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!confirmed) return;

                      store.reissueInvoice(
                        entryId: entry.id,
                        amount: lineItemTotal > 0 ? lineItemTotal : entry.amount,
                        dueDate: _dueDate,
                      );
                    },
              icon: const Icon(Icons.refresh_outlined),
              label: Text(strings.reissueInvoice),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.save,
        isDisabled: !canSave,
        onPressed: () {
          final parsedAmount =
              double.parse(_amountController.text.trim().replaceAll(',', '.'));
          final updated = entry.copyWith(
            title: _titleController.text.trim(),
            amount: parsedAmount,
            dueDate: _dueDate,
            currency: state.appPreferences.preferredCurrency,
            method: _method,
            clearMethod: _method == null,
            status: _status,
            isDisputed: _isDisputed,
            disputeReason: _isDisputed
                ? _disputeReasonController.text.trim()
                : null,
            clearDisputeReason: !_isDisputed,
          );
          store.updateFinanceEntry(updated);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<Uint8List> _buildInvoicePdf({
    required AppStrings strings,
    required OfflineState state,
    required FinanceEntry entry,
    required List<InvoiceLineItemData> lineItems,
    required DateTime dueDate,
    required double amount,
    required bool isDisputed,
    required String disputeReason,
    required Client? client,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(strings.invoice,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.SizedBox(height: 8),
            pw.Text('${strings.title}: ${entry.title}'),
            pw.Text('${strings.dueDate}: ${_pdfDate(dueDate)}'),
            pw.Text('${strings.amount}: '
                '${_formatCurrency(amount, state.appPreferences.preferredCurrency)}'),
            if (client != null) pw.Text('${strings.client}: ${client.name}'),
            if (client != null && client.email.isNotEmpty)
              pw.Text('${strings.email}: ${client.email}'),
            if (client != null && client.phone.isNotEmpty)
              pw.Text('${strings.phone}: ${client.phone}'),
            pw.SizedBox(height: 12),
            pw.Text(strings.lineItems,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
          ];

          for (final item in lineItems) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '- ${item.serviceTypeName} (${_pdfDate(item.date)})',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(item.description),
                  pw.Text(
                    '${strings.qty}: ${_quantityLabel(strings, item.pricingModel, item.quantity)} | '
                    '${strings.unit}: ${_formatCurrency(item.unitPrice, entry.currency)} | '
                    '${strings.total}: ${_formatCurrency(item.total, entry.currency)}',
                  ),
                  pw.SizedBox(height: 6),
                ],
              ),
            );
          }

          widgets.add(
            pw.Text(
              '${strings.total}: ${_formatCurrency(amount, state.appPreferences.preferredCurrency)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          );

          if (isDisputed) {
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.Text(
                '${strings.status}: ${strings.disputed} - '
                '${disputeReason.isEmpty ? strings.pending : disputeReason}',
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return document.save();
  }

  void _shareInvoiceText({
    required AppStrings strings,
    required FinanceEntry entry,
    required List<InvoiceLineItemData> lineItems,
    required String? clientName,
  }) {
    final buffer = StringBuffer()
      ..writeln('${strings.invoice}: ${entry.title}')
      ..writeln('${strings.amount}: ${_formatCurrency(entry.amount, entry.currency)}')
      ..writeln('${strings.dueDate}: ${_pdfDate(_dueDate)}');

    if (clientName != null && clientName.isNotEmpty) {
      buffer.writeln('${strings.client}: $clientName');
    }

    if (lineItems.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(strings.lineItems);
      for (final item in lineItems) {
        buffer.writeln(
          '- ${item.serviceTypeName} | ${item.description} | '
          '${_quantityLabel(strings, item.pricingModel, item.quantity)} | '
          '${_formatCurrency(item.total, entry.currency)}',
        );
      }
    }

    Share.share(buffer.toString());
  }

  bool _channelHasContact(DeliveryChannel channel, Client client) {
    switch (channel) {
      case DeliveryChannel.email:
        return client.email.trim().isNotEmpty;
      case DeliveryChannel.whatsapp:
        return client.whatsappPhone.trim().isNotEmpty ||
            client.phone.trim().isNotEmpty;
      case DeliveryChannel.sms:
        return client.phone.trim().isNotEmpty;
    }
  }

  bool _canAdjustInvoice(DateTime dueDate, bool isSuperseded) {
    if (isSuperseded) return false;
    final limit = dueDate.subtract(const Duration(days: 1));
    return !DateTime.now().isAfter(limit);
  }
}

class PayrollListPage extends ConsumerWidget {
  const PayrollListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final payrolls = ref.watch(offlineStoreProvider).finance.where((entry) {
      return entry.kind == FinanceKind.payrollEmployee;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.payroll,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PayrollFormPage()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: DsBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          itemCount: payrolls.length,
          itemBuilder: (context, index) {
            final entry = payrolls[index];
            return Column(
              children: [
                if (index == 0) const SizedBox(height: kToolbarHeight + 10),
                DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: InkWell(
              borderRadius: BorderRadius.circular(DsRadiusTokens.radiusXl),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PayrollDetailPage(entry: entry),
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontWeight: DsTypeTokens.fontSemibold,
                          ),
                        ),
                        const SizedBox(height: DsSpaceTokens.space1),
                        if (entry.employeeName != null)
                          Text(
                            entry.employeeName!,
                            style: const TextStyle(
                              fontSize: DsTypeTokens.textXs,
                              color: DsColorTokens.textSecondary,
                            ),
                          ),
                        Text(
                          _formatDate(context, entry.dueDate),
                          style: const TextStyle(
                            fontSize: DsTypeTokens.textXs,
                            color: DsColorTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DsSpaceTokens.space2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(entry.amount, entry.currency),
                        style: const TextStyle(
                          fontWeight: DsTypeTokens.fontSemibold,
                        ),
                      ),
                      const SizedBox(height: DsSpaceTokens.space1),
                      DsStatusPill(
                        label: _statusLabel(strings, entry.status),
                        color: _statusColor(entry.status),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
}

class PayrollFormPage extends ConsumerStatefulWidget {
  const PayrollFormPage({super.key});

  @override
  ConsumerState<PayrollFormPage> createState() => _PayrollFormPageState();
}

class _PayrollFormPageState extends ConsumerState<PayrollFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hoursWorkedController = TextEditingController();
  final TextEditingController _daysWorkedController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _bonusController = TextEditingController();
  final TextEditingController _deductionsController = TextEditingController();
  final TextEditingController _taxesController = TextEditingController();
  final TextEditingController _reimbursementsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 5));
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime.now();
  FinancePaymentMethod? _method;
  String _selectedEmployeeId = '';

  @override
  void dispose() {
    _titleController.dispose();
    _hoursWorkedController.dispose();
    _daysWorkedController.dispose();
    _hourlyRateController.dispose();
    _bonusController.dispose();
    _deductionsController.dispose();
    _taxesController.dispose();
    _reimbursementsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final employees = [...state.employees]..sort((a, b) => a.name.compareTo(b.name));
    if (_selectedEmployeeId.isEmpty && employees.isNotEmpty) {
      final first = employees.first;
      _selectedEmployeeId = first.id;
      _titleController.text = '${strings.payrollLabel} - ${first.name}';
      if ((first.hourlyRate ?? 0) > 0) {
        _hourlyRateController.text = (first.hourlyRate ?? 0).toStringAsFixed(2);
      }
    }

    final selectedEmployee = employees.firstWhere(
      (e) => e.id == _selectedEmployeeId,
      orElse: () => const Employee(id: '', name: ''),
    );

    final hoursWorked = _parseDouble(_hoursWorkedController.text);
    final daysWorkedManual = _parseInt(_daysWorkedController.text);
    final hourlyRate = _parseDouble(_hourlyRateController.text);
    final bonus = _parseDouble(_bonusController.text);
    final deductions = _parseDouble(_deductionsController.text);
    final taxes = _parseDouble(_taxesController.text);
    final reimbursements = _parseDouble(_reimbursementsController.text);

    final computedDays = _daysBetween(_periodStart, _periodEnd);
    final finalDaysWorked = _daysWorkedController.text.trim().isEmpty
        ? computedDays
        : daysWorkedManual;

    final basePay = hoursWorked * hourlyRate;
    final netPay = basePay + bonus + reimbursements - deductions - taxes;

    final canSave = netPay > 0 &&
        _selectedEmployeeId.isNotEmpty &&
        _titleController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.newPayroll,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: strings.title),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  decoration: InputDecoration(labelText: strings.employee),
                  items: employees
                      .map(
                        (employee) => DropdownMenuItem<String>(
                          value: employee.id,
                          child: Text(employee.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final employee = employees.firstWhere(
                      (item) => item.id == value,
                      orElse: () => const Employee(id: '', name: ''),
                    );
                    setState(() {
                      _selectedEmployeeId = value;
                      if (_titleController.text.trim().isEmpty ||
                          _titleController.text.startsWith('${strings.payrollLabel} -')) {
                        _titleController.text = '${strings.payrollLabel} - ${employee.name}';
                      }
                      if (_hourlyRateController.text.trim().isEmpty &&
                          (employee.hourlyRate ?? 0) > 0) {
                        _hourlyRateController.text =
                            (employee.hourlyRate ?? 0).toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Row(
                  children: [
                    Text(strings.currency),
                    const Spacer(),
                    Text(_currencyCode(state.appPreferences.preferredCurrency)),
                  ],
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _DateFieldRow(
                  label: strings.dueDate,
                  value: _dueDate,
                  onChange: (date) => setState(() => _dueDate = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinancePaymentMethod?>(
                  value: _method,
                  decoration: InputDecoration(labelText: strings.method),
                  items: [
                    DropdownMenuItem<FinancePaymentMethod?>(
                      value: null,
                      child: Text(strings.none),
                    ),
                    ...FinancePaymentMethod.values.map(
                      (method) => DropdownMenuItem<FinancePaymentMethod?>(
                        value: method,
                        child: Text(_methodLabel(strings, method)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                _DateFieldRow(
                  label: strings.fromLabel,
                  value: _periodStart,
                  onChange: (date) => setState(() => _periodStart = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _DateFieldRow(
                  label: strings.toLabel,
                  value: _periodEnd,
                  onChange: (date) => setState(() => _periodEnd = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _daysWorkedController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: strings.daysWorked),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space1),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strings.calculatedDays(computedDays),
                    style: const TextStyle(
                      fontSize: DsTypeTokens.textXs,
                      color: DsColorTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                TextField(
                  controller: _hoursWorkedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.hoursWorkedLabel),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _hourlyRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.hourlyRate),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _SummaryRow(
                  label: strings.basePay,
                  value: _formatCurrency(
                    basePay,
                    state.appPreferences.preferredCurrency,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _bonusController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.bonus),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _deductionsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.deductions),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _taxesController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.taxes),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _reimbursementsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.reimbursements),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _SummaryRow(
                  label: strings.netPay,
                  value: _formatCurrency(
                    netPay,
                    state.appPreferences.preferredCurrency,
                  ),
                  valueColor: DsColorTokens.actionPrimary,
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: strings.notes),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.save,
        isDisabled: !canSave,
        onPressed: () async {
          final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(strings.confirmPayroll),
                  content: Text(strings.confirmPayrollHelp),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(strings.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(strings.create),
                    ),
                  ],
                ),
              ) ??
              false;

          if (!confirmed) return;

          ref.read(offlineStoreProvider.notifier).addFinanceEntry(
                FinanceEntry(
                  id: 'fin-${DateTime.now().millisecondsSinceEpoch}',
                  title: _titleController.text.trim(),
                  amount: netPay,
                  currency: state.appPreferences.preferredCurrency,
                  type: FinanceEntryType.payable,
                  dueDate: _dueDate,
                  status: FinanceStatus.pending,
                  method: _method,
                  kind: FinanceKind.payrollEmployee,
                  employeeId: selectedEmployee.id,
                  employeeName: selectedEmployee.name,
                  payrollPeriodStart: _periodStart,
                  payrollPeriodEnd: _periodEnd,
                  payrollHoursWorked: hoursWorked,
                  payrollDaysWorked: finalDaysWorked,
                  payrollHourlyRate: hourlyRate,
                  payrollBasePay: basePay,
                  payrollBonus: bonus,
                  payrollDeductions: deductions,
                  payrollTaxes: taxes,
                  payrollReimbursements: reimbursements,
                  payrollNetPay: netPay,
                  payrollNotes: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                ),
              );
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}
}

class PayrollDetailPage extends ConsumerStatefulWidget {
  const PayrollDetailPage({super.key, required this.entry});

  final FinanceEntry entry;

  @override
  ConsumerState<PayrollDetailPage> createState() => _PayrollDetailPageState();
}

class _PayrollDetailPageState extends ConsumerState<PayrollDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _hoursWorkedController;
  late final TextEditingController _daysWorkedController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _bonusController;
  late final TextEditingController _deductionsController;
  late final TextEditingController _taxesController;
  late final TextEditingController _reimbursementsController;
  late final TextEditingController _notesController;

  late DateTime _dueDate;
  late DateTime _periodStart;
  late DateTime _periodEnd;
  FinancePaymentMethod? _method;
  FinanceStatus _status = FinanceStatus.pending;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry.title);
    _hoursWorkedController = TextEditingController(
      text: entry.payrollHoursWorked > 0
          ? entry.payrollHoursWorked.toStringAsFixed(2)
          : '',
    );
    _daysWorkedController = TextEditingController(
      text: entry.payrollDaysWorked > 0 ? '${entry.payrollDaysWorked}' : '',
    );
    _hourlyRateController = TextEditingController(
      text: entry.payrollHourlyRate > 0
          ? entry.payrollHourlyRate.toStringAsFixed(2)
          : '',
    );
    _bonusController = TextEditingController(
      text: entry.payrollBonus > 0 ? entry.payrollBonus.toStringAsFixed(2) : '',
    );
    _deductionsController = TextEditingController(
      text: entry.payrollDeductions > 0
          ? entry.payrollDeductions.toStringAsFixed(2)
          : '',
    );
    _taxesController = TextEditingController(
      text: entry.payrollTaxes > 0 ? entry.payrollTaxes.toStringAsFixed(2) : '',
    );
    _reimbursementsController = TextEditingController(
      text: entry.payrollReimbursements > 0
          ? entry.payrollReimbursements.toStringAsFixed(2)
          : '',
    );
    _notesController = TextEditingController(text: entry.payrollNotes ?? '');

    _dueDate = entry.dueDate;
    _periodStart = entry.payrollPeriodStart ?? entry.dueDate;
    _periodEnd = entry.payrollPeriodEnd ?? entry.dueDate;
    _method = entry.method;
    _status = entry.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hoursWorkedController.dispose();
    _daysWorkedController.dispose();
    _hourlyRateController.dispose();
    _bonusController.dispose();
    _deductionsController.dispose();
    _taxesController.dispose();
    _reimbursementsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final store = ref.read(offlineStoreProvider.notifier);

    final entry = state.finance.firstWhere(
      (item) => item.id == widget.entry.id,
      orElse: () => widget.entry,
    );

    final isManager = state.session?.role == UserRole.manager;
    final canEditFields = _status == FinanceStatus.pending && isManager;

    final hoursWorked = _parseDouble(_hoursWorkedController.text);
    final daysWorkedManual = _parseInt(_daysWorkedController.text);
    final hourlyRate = _parseDouble(_hourlyRateController.text);
    final bonus = _parseDouble(_bonusController.text);
    final deductions = _parseDouble(_deductionsController.text);
    final taxes = _parseDouble(_taxesController.text);
    final reimbursements = _parseDouble(_reimbursementsController.text);

    final computedDays = _daysBetween(_periodStart, _periodEnd);
    final finalDaysWorked = _daysWorkedController.text.trim().isEmpty
        ? computedDays
        : daysWorkedManual;

    final basePay = hoursWorked * hourlyRate;
    final netPay = basePay + bonus + reimbursements - deductions - taxes;

    final canSave = isManager && netPay > 0 && _titleController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.payroll,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                if (entry.employeeName != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${strings.employee}: ${entry.employeeName!}',
                      style: const TextStyle(
                        color: DsColorTokens.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _titleController,
                  enabled: canEditFields,
                  decoration: InputDecoration(labelText: strings.title),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                Row(
                  children: [
                    Text(strings.currency),
                    const Spacer(),
                    Text(_currencyCode(state.appPreferences.preferredCurrency)),
                  ],
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _DateFieldRow(
                  label: strings.dueDate,
                  value: _dueDate,
                  enabled: canEditFields,
                  onChange: (date) => setState(() => _dueDate = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinancePaymentMethod?>(
                  value: _method,
                  decoration: InputDecoration(labelText: strings.method),
                  items: [
                    DropdownMenuItem<FinancePaymentMethod?>(
                      value: null,
                      child: Text(strings.none),
                    ),
                    ...FinancePaymentMethod.values.map(
                      (method) => DropdownMenuItem<FinancePaymentMethod?>(
                        value: method,
                        child: Text(_methodLabel(strings, method)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinanceStatus>(
                  value: _status,
                  decoration: InputDecoration(labelText: strings.status),
                  items: FinanceStatus.values
                      .map(
                        (status) => DropdownMenuItem<FinanceStatus>(
                          value: status,
                          child: Text(_statusLabel(strings, status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                _DateFieldRow(
                  label: strings.fromLabel,
                  value: _periodStart,
                  enabled: canEditFields,
                  onChange: (date) => setState(() => _periodStart = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _DateFieldRow(
                  label: strings.toLabel,
                  value: _periodEnd,
                  enabled: canEditFields,
                  onChange: (date) => setState(() => _periodEnd = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _daysWorkedController,
                  enabled: canEditFields,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: strings.daysWorked),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space1),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strings.calculatedDays(computedDays),
                    style: const TextStyle(
                      fontSize: DsTypeTokens.textXs,
                      color: DsColorTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                TextField(
                  controller: _hoursWorkedController,
                  enabled: canEditFields,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.hoursWorkedLabel),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _hourlyRateController,
                  enabled: canEditFields,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.hourlyRate),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _SummaryRow(
                  label: strings.basePay,
                  value: _formatCurrency(
                    basePay,
                    state.appPreferences.preferredCurrency,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _bonusController,
                  enabled: canEditFields,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.bonus),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _deductionsController,
                  enabled: canEditFields,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.deductions),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _taxesController,
                  enabled: canEditFields,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.taxes),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _reimbursementsController,
                  enabled: canEditFields,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.reimbursements),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _SummaryRow(
                  label: strings.netPay,
                  value: _formatCurrency(
                    netPay,
                    state.appPreferences.preferredCurrency,
                  ),
                  valueColor: DsColorTokens.actionPrimary,
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: TextField(
              controller: _notesController,
              enabled: canEditFields,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: strings.notes),
            ),
          ),
          if (!canEditFields)
            DsCard(
              margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
              child: Text(
                strings.editingLockedAfterPayment,
                style: const TextStyle(
                  color: DsColorTokens.textSecondary,
                ),
              ),
            ),
        ],
      ),
    ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.save,
        isDisabled: !canSave,
        onPressed: () {
          final updated = entry.copyWith(
            title: _titleController.text.trim(),
            amount: netPay,
            dueDate: _dueDate,
            currency: state.appPreferences.preferredCurrency,
            method: _method,
            clearMethod: _method == null,
            status: _status,
            payrollPeriodStart: _periodStart,
            payrollPeriodEnd: _periodEnd,
            payrollHoursWorked: hoursWorked,
            payrollDaysWorked: finalDaysWorked,
            payrollHourlyRate: hourlyRate,
            payrollBasePay: basePay,
            payrollBonus: bonus,
            payrollDeductions: deductions,
            payrollTaxes: taxes,
            payrollReimbursements: reimbursements,
            payrollNetPay: netPay,
            payrollNotes: _notesController.text.trim(),
            clearPayrollNotes: _notesController.text.trim().isEmpty,
          );
          store.updateFinanceEntry(updated);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class GenericFinanceDetailPage extends ConsumerStatefulWidget {
  const GenericFinanceDetailPage({super.key, required this.entry});

  final FinanceEntry entry;

  @override
  ConsumerState<GenericFinanceDetailPage> createState() =>
      _GenericFinanceDetailPageState();
}

class _GenericFinanceDetailPageState
    extends ConsumerState<GenericFinanceDetailPage> {
  late FinanceStatus _status;
  FinancePaymentMethod? _method;

  @override
  void initState() {
    super.initState();
    _status = widget.entry.status;
    _method = widget.entry.method;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final store = ref.read(offlineStoreProvider.notifier);

    final entry = state.finance.firstWhere(
      (item) => item.id == widget.entry.id,
      orElse: () => widget.entry,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.financeEntry,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
            DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space1),
                Text(
                  _formatDate(context, entry.dueDate),
                  style: const TextStyle(
                    color: DsColorTokens.textSecondary,
                  ),
                ),
                if (entry.clientName != null)
                  Text(
                    '${strings.client}: ${entry.clientName!}',
                    style: const TextStyle(
                      fontSize: DsTypeTokens.textSm,
                      color: DsColorTokens.textSecondary,
                    ),
                  ),
                if (entry.employeeName != null)
                  Text(
                    '${strings.employee}: ${entry.employeeName!}',
                    style: const TextStyle(
                      fontSize: DsTypeTokens.textSm,
                      color: DsColorTokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                DropdownButtonFormField<FinanceStatus>(
                  value: _status,
                  decoration: InputDecoration(labelText: strings.status),
                  items: FinanceStatus.values
                      .map(
                        (status) => DropdownMenuItem<FinanceStatus>(
                          value: status,
                          child: Text(_statusLabel(strings, status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinancePaymentMethod?>(
                  value: _method,
                  decoration: InputDecoration(labelText: strings.method),
                  items: [
                    DropdownMenuItem<FinancePaymentMethod?>(
                      value: null,
                      child: Text(strings.none),
                    ),
                    ...FinancePaymentMethod.values.map(
                      (method) => DropdownMenuItem<FinancePaymentMethod?>(
                        value: method,
                        child: Text(_methodLabel(strings, method)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.save,
        onPressed: () {
          store.updateFinanceEntry(
            entry.copyWith(
              status: _status,
              method: _method,
              clearMethod: _method == null,
            ),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class ExpenseDetailPage extends ConsumerStatefulWidget {
  const ExpenseDetailPage({super.key, required this.entry});

  final FinanceEntry entry;

  @override
  ConsumerState<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends ConsumerState<ExpenseDetailPage> {
  late FinanceStatus _status;
  FinancePaymentMethod? _method;

  @override
  void initState() {
    super.initState();
    _status = widget.entry.status;
    _method = widget.entry.method;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final store = ref.read(offlineStoreProvider.notifier);

    final entry = state.finance.firstWhere(
      (item) => item.id == widget.entry.id,
      orElse: () => widget.entry,
    );

    final receiptBytes = entry.receiptData == null
        ? null
        : Uint8List.fromList(entry.receiptData!);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.expense,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
            DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space1),
                Text(
                  _formatDate(context, entry.dueDate),
                  style: const TextStyle(color: DsColorTokens.textSecondary),
                ),
                const SizedBox(height: DsSpaceTokens.space1),
                if ((entry.clientName ?? '').isNotEmpty)
                  Text(
                    '${strings.client}: ${entry.clientName!}',
                    style: const TextStyle(color: DsColorTokens.textSecondary),
                  ),
                Text(
                  '${strings.amount}: ${_formatCurrency(entry.amount, entry.currency)}',
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                DropdownButtonFormField<FinanceStatus>(
                  value: _status,
                  decoration: InputDecoration(labelText: strings.status),
                  items: FinanceStatus.values
                      .map(
                        (status) => DropdownMenuItem<FinanceStatus>(
                          value: status,
                          child: Text(_statusLabel(strings, status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinancePaymentMethod?>(
                  value: _method,
                  decoration: InputDecoration(labelText: strings.method),
                  items: [
                    DropdownMenuItem<FinancePaymentMethod?>(
                      value: null,
                      child: Text(strings.none),
                    ),
                    ...FinancePaymentMethod.values.map(
                      (method) => DropdownMenuItem<FinancePaymentMethod?>(
                        value: method,
                        child: Text(_methodLabel(strings, method)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                ),
              ],
            ),
          ),
          if (receiptBytes != null)
            DsCard(
              margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.receipt,
                    style: const TextStyle(
                      fontSize: DsTypeTokens.textBase,
                      fontWeight: DsTypeTokens.fontSemibold,
                    ),
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
                  InkWell(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => Dialog(
                          child: InteractiveViewer(
                            child: Image.memory(receiptBytes),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DsRadiusTokens.radiusLg),
                      child: Image.memory(receiptBytes, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
                  OutlinedButton.icon(
                    onPressed: () {
                      final text = strings.expenseReceiptShare(
                        entry.title,
                        _formatCurrency(entry.amount, entry.currency),
                        _formatDate(context, entry.dueDate),
                      );
                      final file = XFile.fromData(
                        receiptBytes,
                        name: 'receipt-${entry.id}.jpg',
                        mimeType: 'image/jpeg',
                      );
                      Share.shareXFiles([file], text: text);
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: Text(strings.shareReceipt),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.save,
        onPressed: () {
          store.updateFinanceEntry(
            entry.copyWith(
              status: _status,
              method: _method,
              clearMethod: _method == null,
            ),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

enum _ReportScope { month, week, custom }

class _ReportsPageState extends ConsumerState<ReportsPage> {
  _ReportScope _scope = _ReportScope.month;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedWeek = DateTime.now();
  DateTime _customStart = DateTime.now();
  DateTime _customEnd = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final range = _reportRange();
    final entriesInRange = state.finance.where((entry) {
      return _isInRange(entry.dueDate, range.start, range.end);
    }).toList();

    final receivablesInRange = entriesInRange
        .where((entry) => entry.type == FinanceEntryType.receivable)
        .toList();
    final payablesInRange = entriesInRange
        .where((entry) => entry.type == FinanceEntryType.payable)
        .toList();

    final currencySet = entriesInRange.map((entry) => entry.currency).toSet();
    final currencies = FinanceCurrency.values
        .where((currency) => currencySet.contains(currency))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.reports,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.period,
                  style: const TextStyle(
                    fontSize: DsTypeTokens.textBase,
                    fontWeight: DsTypeTokens.fontSemibold,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                SegmentedButton<_ReportScope>(
                  segments: [
                    ButtonSegment<_ReportScope>(
                      value: _ReportScope.month,
                      label: Text(strings.month),
                    ),
                    ButtonSegment<_ReportScope>(
                      value: _ReportScope.week,
                      label: Text(strings.week),
                    ),
                    ButtonSegment<_ReportScope>(
                      value: _ReportScope.custom,
                      label: Text(strings.customRange),
                    ),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (value) {
                    setState(() => _scope = value.first);
                  },
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                if (_scope == _ReportScope.month)
                  _DateFieldRow(
                    label: strings.month,
                    value: _selectedMonth,
                    onChange: (date) => setState(() => _selectedMonth = date),
                  )
                else if (_scope == _ReportScope.week)
                  _DateFieldRow(
                    label: strings.week,
                    value: _selectedWeek,
                    onChange: (date) => setState(() => _selectedWeek = date),
                  )
                else ...[
                  _DateFieldRow(
                    label: strings.startDate,
                    value: _customStart,
                    onChange: (date) => setState(() => _customStart = date),
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
                  _DateFieldRow(
                    label: strings.endDate,
                    value: _customEnd,
                    onChange: (date) => setState(() => _customEnd = date),
                  ),
                ],
                const SizedBox(height: DsSpaceTokens.space2),
                Text(
                  _periodLabel(context, strings, range),
                  style: const TextStyle(color: DsColorTokens.textSecondary),
                ),
              ],
            ),
          ),
          if (entriesInRange.isEmpty)
            DsCard(
              margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
              child: Text(
                strings.noDataForPeriod,
                style: const TextStyle(color: DsColorTokens.textSecondary),
              ),
            )
          else ...[
            ...currencies.map(
              (currency) {
                final receivables = receivablesInRange
                    .where((entry) => entry.currency == currency)
                    .toList();
                final payables = payablesInRange
                    .where((entry) => entry.currency == currency)
                    .toList();

                final totalReceivables =
                    receivables.fold<double>(0, (sum, e) => sum + e.amount);
                final totalPayables =
                    payables.fold<double>(0, (sum, e) => sum + e.amount);
                final net = totalReceivables - totalPayables;

                final clientItems = _summaryItems(
                  entries: receivables,
                  keyFor: (entry) => entry.clientName ?? strings.unknown,
                );
                final employeeItems = _summaryItems(
                  entries: payables,
                  keyFor: (entry) => entry.employeeName ?? strings.unknown,
                );

                return Column(
                  children: [
                    DsCard(
                      margin: const EdgeInsets.symmetric(
                        vertical: DsSpaceTokens.space2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.summaryByCurrency(_currencyCode(currency)),
                            style: const TextStyle(
                              fontSize: DsTypeTokens.textBase,
                              fontWeight: DsTypeTokens.fontSemibold,
                            ),
                          ),
                          const SizedBox(height: DsSpaceTokens.space2),
                          _SummaryRow(
                            label: strings.receivables,
                            value: _formatCurrency(totalReceivables, currency),
                            valueColor: DsColorTokens.statusSuccess,
                          ),
                          _SummaryRow(
                            label: strings.payables,
                            value: _formatCurrency(totalPayables, currency),
                            valueColor: DsColorTokens.statusError,
                          ),
                          const Divider(),
                          _SummaryRow(
                            label: strings.net,
                            value: _formatCurrency(net, currency),
                            valueColor: net >= 0
                                ? DsColorTokens.statusSuccess
                                : DsColorTokens.statusError,
                          ),
                        ],
                      ),
                    ),
                    if (clientItems.isNotEmpty)
                      DsCard(
                        margin: const EdgeInsets.symmetric(
                          vertical: DsSpaceTokens.space2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.topClients,
                              style: const TextStyle(
                                fontSize: DsTypeTokens.textBase,
                                fontWeight: DsTypeTokens.fontSemibold,
                              ),
                            ),
                            const SizedBox(height: DsSpaceTokens.space2),
                            ...clientItems.take(5).map(
                                  (item) => _SummaryRow(
                                    label: item.name,
                                    value: _formatCurrency(item.total, currency),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    if (employeeItems.isNotEmpty)
                      DsCard(
                        margin: const EdgeInsets.symmetric(
                          vertical: DsSpaceTokens.space2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.topEmployees,
                              style: const TextStyle(
                                fontSize: DsTypeTokens.textBase,
                                fontWeight: DsTypeTokens.fontSemibold,
                              ),
                            ),
                            const SizedBox(height: DsSpaceTokens.space2),
                            ...employeeItems.take(5).map(
                                  (item) => _SummaryRow(
                                    label: item.name,
                                    value: _formatCurrency(item.total, currency),
                                  ),
                                ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            DsCard(
              margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.export,
                    style: const TextStyle(
                      fontSize: DsTypeTokens.textBase,
                      fontWeight: DsTypeTokens.fontSemibold,
                    ),
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
                  OutlinedButton.icon(
                    onPressed: () {
                      _exportCsv(
                        strings: strings,
                        range: range,
                        currencies: currencies,
                        receivablesInRange: receivablesInRange,
                        payablesInRange: payablesInRange,
                      );
                    },
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(strings.exportCsv),
                  ),
                  const SizedBox(height: DsSpaceTokens.space1),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final bytes = await _buildReportPdf(
                        strings: strings,
                        range: range,
                        currencies: currencies,
                        receivablesInRange: receivablesInRange,
                        payablesInRange: payablesInRange,
                      );
                      if (!mounted) return;
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename:
                            'report-${DateFormat('yyyy-MM-dd').format(range.start)}-${DateFormat('yyyy-MM-dd').format(range.end)}.pdf',
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(strings.exportPdf),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  _DateRange _reportRange() {
    if (_scope == _ReportScope.month) {
      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23,
          59, 59, 999);
      return _DateRange(start: start, end: end);
    }

    if (_scope == _ReportScope.week) {
      final weekday = _selectedWeek.weekday;
      final start = DateTime(
        _selectedWeek.year,
        _selectedWeek.month,
        _selectedWeek.day,
      ).subtract(Duration(days: weekday - 1));
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
      return _DateRange(start: start, end: end);
    }

    final start = _customStart.isBefore(_customEnd) ? _customStart : _customEnd;
    final end = _customStart.isAfter(_customEnd) ? _customStart : _customEnd;
    return _DateRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
    );
  }

  String _periodLabel(BuildContext context, AppStrings strings, _DateRange range) {
    final formatter = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    if (_scope == _ReportScope.month) {
      return DateFormat('MMMM yyyy', Localizations.localeOf(context).toLanguageTag())
          .format(_selectedMonth);
    }
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  List<_SummaryItemData> _summaryItems({
    required List<FinanceEntry> entries,
    required String Function(FinanceEntry entry) keyFor,
  }) {
    final map = <String, _SummaryItemData>{};
    for (final entry in entries) {
      final rawName = keyFor(entry).trim();
      final key = rawName.isEmpty ? 'Unknown' : rawName;
      final previous = map[key];
      if (previous == null) {
        map[key] = _SummaryItemData(name: key, total: entry.amount, count: 1);
      } else {
        map[key] = _SummaryItemData(
          name: key,
          total: previous.total + entry.amount,
          count: previous.count + 1,
        );
      }
    }
    final values = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return values;
  }

  void _exportCsv({
    required AppStrings strings,
    required _DateRange range,
    required List<FinanceCurrency> currencies,
    required List<FinanceEntry> receivablesInRange,
    required List<FinanceEntry> payablesInRange,
  }) {
    final start = DateFormat('yyyy-MM-dd').format(range.start);
    final end = DateFormat('yyyy-MM-dd').format(range.end);

    final lines = <String>[
      'Period Start,Period End,Currency,Type,Name,Count,Total',
    ];

    for (final currency in currencies) {
      final receivables = receivablesInRange
          .where((entry) => entry.currency == currency)
          .toList();
      final payables =
          payablesInRange.where((entry) => entry.currency == currency).toList();

      final clientItems = _summaryItems(
        entries: receivables,
        keyFor: (entry) => entry.clientName ?? strings.unknown,
      );
      final employeeItems = _summaryItems(
        entries: payables,
        keyFor: (entry) => entry.employeeName ?? strings.unknown,
      );

      for (final item in clientItems) {
        lines.add(_csvLine([
          start,
          end,
          _currencyCode(currency),
          strings.receivable,
          item.name,
          '${item.count}',
          item.total.toStringAsFixed(2),
        ]));
      }

      for (final item in employeeItems) {
        lines.add(_csvLine([
          start,
          end,
          _currencyCode(currency),
          strings.payable,
          item.name,
          '${item.count}',
          item.total.toStringAsFixed(2),
        ]));
      }
    }

    Share.share(lines.join('\n'));
  }

  Future<Uint8List> _buildReportPdf({
    required AppStrings strings,
    required _DateRange range,
    required List<FinanceCurrency> currencies,
    required List<FinanceEntry> receivablesInRange,
    required List<FinanceEntry> payablesInRange,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              strings.reportLabel(_scope == _ReportScope.month),
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '${strings.period}: '
              '${DateFormat('yyyy-MM-dd').format(range.start)} - '
              '${DateFormat('yyyy-MM-dd').format(range.end)}',
            ),
            pw.SizedBox(height: 12),
          ];

          for (final currency in currencies) {
            final receivables = receivablesInRange
                .where((entry) => entry.currency == currency)
                .toList();
            final payables = payablesInRange
                .where((entry) => entry.currency == currency)
                .toList();

            final totalReceivables =
                receivables.fold<double>(0, (sum, e) => sum + e.amount);
            final totalPayables =
                payables.fold<double>(0, (sum, e) => sum + e.amount);
            final net = totalReceivables - totalPayables;

            widgets.add(
              pw.Text(
                strings.summaryByCurrency(_currencyCode(currency)),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            );
            widgets.add(
              pw.Text(
                '${strings.receivables}: ${_formatCurrency(totalReceivables, currency)}',
              ),
            );
            widgets.add(
              pw.Text(
                '${strings.payables}: ${_formatCurrency(totalPayables, currency)}',
              ),
            );
            widgets.add(
              pw.Text('${strings.net}: ${_formatCurrency(net, currency)}'),
            );
            widgets.add(pw.SizedBox(height: 8));
          }

          return widgets;
        },
      ),
    );

    return document.save();
  }

  String _csvLine(List<String> values) {
    return values
        .map((value) => '"${value.replaceAll('"', '""')}"')
        .join(',');
  }
}

class InvoiceGeneratorPage extends ConsumerStatefulWidget {
  const InvoiceGeneratorPage({super.key});

  @override
  ConsumerState<InvoiceGeneratorPage> createState() => _InvoiceGeneratorPageState();
}

class _InvoiceGeneratorPageState extends ConsumerState<InvoiceGeneratorPage> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _selectedClientId = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final clients = [...ref.watch(offlineStoreProvider).clients]
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(title: Text(strings.generateInvoicesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DsSpaceTokens.space4),
        children: [
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                _DateFieldRow(
                  label: strings.fromLabel,
                  value: _startDate,
                  onChange: (date) => setState(() => _startDate = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _DateFieldRow(
                  label: strings.toLabel,
                  value: _endDate,
                  onChange: (date) => setState(() => _endDate = date),
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: _DateFieldRow(
              label: strings.dueDate,
              value: _dueDate,
              onChange: (date) => setState(() => _dueDate = date),
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: DropdownButtonFormField<String>(
              value: _selectedClientId,
              decoration: InputDecoration(labelText: strings.client),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(strings.allClients),
                ),
                ...clients.map(
                  (client) => DropdownMenuItem<String>(
                    value: client.id,
                    child: Text(client.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedClientId = value ?? ''),
            ),
          ),
        ],
      ),
    ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.generate,
        onPressed: () {
          ref.read(offlineStoreProvider.notifier).generateInvoicesForPeriod(
                startDate: _startDate,
                endDate: _endDate,
                dueDate: _dueDate,
                clientId: _selectedClientId.isEmpty ? null : _selectedClientId,
              );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class PayrollGeneratorPage extends ConsumerStatefulWidget {
  const PayrollGeneratorPage({super.key});

  @override
  ConsumerState<PayrollGeneratorPage> createState() => _PayrollGeneratorPageState();
}

class _PayrollGeneratorPageState extends ConsumerState<PayrollGeneratorPage> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 5));
  String _selectedEmployeeId = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final employees = [...ref.watch(offlineStoreProvider).employees]
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.generatePayrollTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                _DateFieldRow(
                  label: strings.fromLabel,
                  value: _startDate,
                  onChange: (date) => setState(() => _startDate = date),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _DateFieldRow(
                  label: strings.toLabel,
                  value: _endDate,
                  onChange: (date) => setState(() => _endDate = date),
                ),
              ],
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: _DateFieldRow(
              label: strings.dueDate,
              value: _dueDate,
              onChange: (date) => setState(() => _dueDate = date),
            ),
          ),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: DropdownButtonFormField<String>(
              value: _selectedEmployeeId,
              decoration: InputDecoration(labelText: strings.employee),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(strings.allEmployees),
                ),
                ...employees.map(
                  (employee) => DropdownMenuItem<String>(
                    value: employee.id,
                    child: Text(employee.name),
                  ),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedEmployeeId = value ?? ''),
            ),
          ),
        ],
      ),
    ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.generate,
        onPressed: () {
          ref.read(offlineStoreProvider.notifier).generatePayrollsForPeriod(
                startDate: _startDate,
                endDate: _endDate,
                dueDate: _dueDate,
                employeeId:
                    _selectedEmployeeId.isEmpty ? null : _selectedEmployeeId,
              );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class GenericFinanceFormPage extends ConsumerStatefulWidget {
  const GenericFinanceFormPage({super.key});

  @override
  ConsumerState<GenericFinanceFormPage> createState() =>
      _GenericFinanceFormPageState();
}

class _GenericFinanceFormPageState extends ConsumerState<GenericFinanceFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  FinanceEntryType _type = FinanceEntryType.receivable;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final canSave =
        _titleController.text.trim().isNotEmpty && amount != null && amount > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.newFinanceEntry,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.all(DsSpaceTokens.space4),
          children: [
            const SizedBox(height: kToolbarHeight + 10),
          DsCard(
            margin: const EdgeInsets.symmetric(vertical: DsSpaceTokens.space2),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: strings.title),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.amount),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DropdownButtonFormField<FinanceEntryType>(
                  value: _type,
                  decoration: InputDecoration(labelText: strings.type),
                  items: [
                    DropdownMenuItem<FinanceEntryType>(
                      value: FinanceEntryType.receivable,
                      child: Text(strings.receivable),
                    ),
                    DropdownMenuItem<FinanceEntryType>(
                      value: FinanceEntryType.payable,
                      child: Text(strings.payable),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _type = value);
                  },
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                _DateFieldRow(
                  label: strings.dueDate,
                  value: _dueDate,
                  onChange: (date) => setState(() => _dueDate = date),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
      bottomNavigationBar: DsPrimaryBottomCta(
        title: strings.save,
        isDisabled: !canSave,
        onPressed: () {
          ref.read(offlineStoreProvider.notifier).addFinanceEntry(
                FinanceEntry(
                  id: 'fin-${DateTime.now().millisecondsSinceEpoch}',
                  title: _titleController.text.trim(),
                  amount: amount!,
                  currency: state.appPreferences.preferredCurrency,
                  type: _type,
                  dueDate: _dueDate,
                  status: FinanceStatus.pending,
                  kind: FinanceKind.general,
                ),
              );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _DateFieldRow extends StatelessWidget {
  const _DateFieldRow({
    required this.label,
    required this.value,
    required this.onChange,
    this.enabled = true,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        TextButton(
          onPressed: enabled
              ? () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (selected == null) return;
                  onChange(selected);
                }
              : null,
          child: Text(_formatDate(context, value)),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: DsTypeTokens.textSm),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: DsTypeTokens.textSm,
            fontWeight: DsTypeTokens.fontSemibold,
            color: valueColor ?? DsColorTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SummaryItemData {
  const _SummaryItemData({
    required this.name,
    required this.total,
    required this.count,
  });

  final String name;
  final double total;
  final int count;
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

String _formatDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(date);
}

String _formatDateTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).add_Hm().format(date);
}

String _pdfDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

bool _isInRange(DateTime value, DateTime start, DateTime end) {
  return !value.isBefore(start) && !value.isAfter(end);
}

_DateRange _monthRange(DateTime selectedMonth) {
  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59,
      59, 999);
  return _DateRange(start: start, end: end);
}

String _monthLabel(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('MMMM yyyy', locale).format(date);
}

String _currencyCode(FinanceCurrency currency) {
  switch (currency) {
    case FinanceCurrency.usd:
      return 'USD';
    case FinanceCurrency.eur:
      return 'EUR';
  }
}

String _formatCurrency(double value, FinanceCurrency currency) {
  final formatter = NumberFormat.currency(
    name: _currencyCode(currency),
    decimalDigits: 2,
  );
  return formatter.format(value);
}

String _statusLabel(AppStrings strings, FinanceStatus status) {
  switch (status) {
    case FinanceStatus.pending:
      return strings.pending;
    case FinanceStatus.paid:
      return strings.paid;
  }
}

Color _statusColor(FinanceStatus status) {
  switch (status) {
    case FinanceStatus.pending:
      return DsColorTokens.statusWarning;
    case FinanceStatus.paid:
      return DsColorTokens.statusSuccess;
  }
}

String _methodLabel(AppStrings strings, FinancePaymentMethod method) {
  switch (method) {
    case FinancePaymentMethod.pix:
      return strings.pix;
    case FinancePaymentMethod.card:
      return strings.card;
    case FinancePaymentMethod.cash:
      return strings.cash;
  }
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

String _quantityLabel(
  AppStrings strings,
  ServicePricingModel pricingModel,
  double quantity,
) {
  switch (pricingModel) {
    case ServicePricingModel.perTask:
      return strings.oneTask;
    case ServicePricingModel.perHour:
      return strings.hoursQuantity(quantity);
  }
}

String _disputeWindowOpenText(
  AppStrings strings,
  DateTime deadline,
  int disputeWindowDays,
) {
  if (disputeWindowDays == 0) {
    return strings.disputesAllowedUntilDueDate;
  }
  return strings.disputesAllowedUntil(_pdfDate(deadline));
}

double _parseDouble(String value) {
  return double.tryParse(value.replaceAll(',', '.')) ?? 0;
}

int _parseInt(String value) {
  return int.tryParse(value.trim()) ?? 0;
}

int _daysBetween(DateTime start, DateTime end) {
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  if (endDay.isBefore(startDay)) return 0;
  return endDay.difference(startDay).inDays + 1;
}
