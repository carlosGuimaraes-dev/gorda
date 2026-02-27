import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../finance/domain/finance_entry.dart';
import '../../offline/application/offline_store.dart';
import '../domain/service_type.dart';

class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    final serviceTypes = [...state.serviceTypes]
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(
        title: Text(strings.services),
        actions: [
          IconButton(
            onPressed: () => ServicesPage.showServiceTypeFormDialog(context, ref),
            icon: const Icon(Icons.add),
            tooltip: strings.newItem,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: serviceTypes.length,
        itemBuilder: (context, index) {
          final serviceType = serviceTypes[index];
          return ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ServiceTypeDetailPage(serviceTypeId: serviceType.id),
              ),
            ),
            title: Text(serviceType.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_pricingModelLabel(strings, serviceType.pricingModel)),
                if (serviceType.description.trim().isNotEmpty)
                  Text(
                    serviceType.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currencyCode(serviceType.currency)} ${serviceType.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppThemeTokens.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      ServicesPage.showServiceTypeFormDialog(context, ref,
                          serviceType: serviceType);
                      return;
                    }
                    if (value == 'delete') {
                      ServicesPage.deleteServiceTypeFromListDialog(
                        context,
                        ref,
                        serviceType,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(strings.editService),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(strings.deleteService),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> deleteServiceTypeFromListDialog(
    BuildContext context,
    WidgetRef ref,
    ServiceType serviceType,
  ) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.deleteServiceQuestion),
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

    final deleted = ref
        .read(offlineStoreProvider.notifier)
        .deleteServiceType(serviceType.id);
    if (deleted) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.cannotDeleteService),
        content: Text(strings.serviceDeleteBlocked),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  static String _pricingModelLabel(AppStrings strings, ServicePricingModel model) {
    return switch (model) {
      ServicePricingModel.perTask => strings.perTask,
      ServicePricingModel.perHour => strings.perHour,
    };
  }

  static String _currencyCode(FinanceCurrency currency) {
    return switch (currency) {
      FinanceCurrency.usd => 'USD',
      FinanceCurrency.eur => 'EUR',
    };
  }

  static Future<void> showServiceTypeFormDialog(
    BuildContext context,
    WidgetRef ref, {
    ServiceType? serviceType,
  }) async {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final nameCtrl = TextEditingController(text: serviceType?.name ?? '');
    final descriptionCtrl =
        TextEditingController(text: serviceType?.description ?? '');
    final basePriceCtrl = TextEditingController(
      text: serviceType == null ? '' : serviceType.basePrice.toStringAsFixed(2),
    );
    ServicePricingModel pricingModel =
        serviceType?.pricingModel ?? ServicePricingModel.perTask;
    FinanceCurrency currency = serviceType?.currency ?? FinanceCurrency.usd;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              serviceType == null ? strings.newServiceType : strings.editService,
            ),
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
                    controller: descriptionCtrl,
                    decoration: InputDecoration(labelText: strings.description),
                    maxLines: 3,
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
                  TextField(
                    controller: basePriceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: strings.basePrice),
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
                  DropdownButtonFormField<ServicePricingModel>(
                    value: pricingModel,
                    decoration:
                        InputDecoration(labelText: strings.pricingModel),
                    items: [
                      DropdownMenuItem(
                        value: ServicePricingModel.perTask,
                        child: Text(strings.perTask),
                      ),
                      DropdownMenuItem(
                        value: ServicePricingModel.perHour,
                        child: Text(strings.perHour),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => pricingModel = value);
                    },
                  ),
                  const SizedBox(height: DsSpaceTokens.space2),
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
                  final basePrice = double.tryParse(basePriceCtrl.text.trim());
                  if (name.isEmpty || basePrice == null) return;
                  if (serviceType == null) {
                    ref.read(offlineStoreProvider.notifier).addServiceType(
                          ServiceType(
                            id: 'service-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            description: descriptionCtrl.text.trim(),
                            basePrice: basePrice,
                            currency: currency,
                            pricingModel: pricingModel,
                          ),
                        );
                  } else {
                    ref.read(offlineStoreProvider.notifier).updateServiceType(
                          serviceType.copyWith(
                            name: name,
                            description: descriptionCtrl.text.trim(),
                            basePrice: basePrice,
                            currency: currency,
                            pricingModel: pricingModel,
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
}

class ServiceTypeDetailPage extends ConsumerWidget {
  const ServiceTypeDetailPage({super.key, required this.serviceTypeId});

  final String serviceTypeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));
    final state = ref.watch(offlineStoreProvider);
    ServiceType? serviceType;
    for (final item in state.serviceTypes) {
      if (item.id == serviceTypeId) {
        serviceType = item;
        break;
      }
    }
    if (serviceType == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.services)),
        body: Center(child: Text(strings.serviceNotFound)),
      );
    }
    final current = serviceType;
    final linkedTasks =
        state.tasks.where((task) => task.serviceTypeId == current.id).length;
    final canDelete = linkedTasks == 0;

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(title: Text(strings.service)),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              current.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: current.description.trim().isEmpty
                ? null
                : Text(current.description),
          ),
          ListTile(
            title: Text(
              '${strings.basePrice}: ${current.currency == FinanceCurrency.eur ? 'EUR' : 'USD'} ${current.basePrice.toStringAsFixed(2)}',
            ),
          ),
          ListTile(
            title: Text(
              '${strings.pricingModel}: ${current.pricingModel == ServicePricingModel.perTask ? strings.perTask : strings.perHour}',
            ),
          ),
          if (linkedTasks > 0)
            ListTile(
              title: Text('${strings.usage}: $linkedTasks'),
              subtitle: Text(strings.reassignBeforeDelete),
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(strings.editService),
            onTap: () => ServicesPage.showServiceTypeFormDialog(
              context,
              ref,
              serviceType: current,
            ),
          ),
          if (canDelete)
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: DsColorTokens.statusError,
              ),
              title: Text(strings.deleteService,
                  style: const TextStyle(color: DsColorTokens.statusError)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(strings.deleteServiceQuestion),
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
                final deleted = ref
                    .read(offlineStoreProvider.notifier)
                    .deleteServiceType(current.id);
                if (deleted && context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
