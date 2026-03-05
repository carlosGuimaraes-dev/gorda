import '../../finance/domain/finance_entry.dart';

enum ServicePricingModel { perTask, perHour }

class ServiceType {
  const ServiceType({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.currency,
    this.description = '',
    this.pricingModel = ServicePricingModel.perTask,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String description;
  final double basePrice;
  final FinanceCurrency currency;
  final ServicePricingModel pricingModel;
  final bool isDeleted;
  final DateTime? deletedAt;

  ServiceType copyWith({
    String? id,
    String? name,
    String? description,
    double? basePrice,
    FinanceCurrency? currency,
    ServicePricingModel? pricingModel,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ServiceType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      pricingModel: pricingModel ?? this.pricingModel,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
