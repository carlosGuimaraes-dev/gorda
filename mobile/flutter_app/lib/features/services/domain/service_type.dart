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
  });

  final String id;
  final String name;
  final String description;
  final double basePrice;
  final FinanceCurrency currency;
  final ServicePricingModel pricingModel;

  ServiceType copyWith({
    String? id,
    String? name,
    String? description,
    double? basePrice,
    FinanceCurrency? currency,
    ServicePricingModel? pricingModel,
  }) {
    return ServiceType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      pricingModel: pricingModel ?? this.pricingModel,
    );
  }
}
