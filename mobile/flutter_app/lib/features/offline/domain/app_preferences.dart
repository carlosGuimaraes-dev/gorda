import '../../finance/domain/finance_entry.dart';

enum TaxCountry {
  unitedStates,
  spain,
  portugal,
  other,
}

class CompanyProfile {
  const CompanyProfile({
    this.legalName = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.region = '',
    this.postalCode = '',
    this.countryName = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.website = '',
    this.taxCountry = TaxCountry.unitedStates,
    this.taxIdentifier = '',
    this.logoData,
  });

  final String legalName;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String region;
  final String postalCode;
  final String countryName;
  final String contactEmail;
  final String contactPhone;
  final String website;
  final TaxCountry taxCountry;
  final String taxIdentifier;
  final List<int>? logoData;

  CompanyProfile copyWith({
    String? legalName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? region,
    String? postalCode,
    String? countryName,
    String? contactEmail,
    String? contactPhone,
    String? website,
    TaxCountry? taxCountry,
    String? taxIdentifier,
    List<int>? logoData,
    bool clearLogo = false,
  }) {
    return CompanyProfile(
      legalName: legalName ?? this.legalName,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      region: region ?? this.region,
      postalCode: postalCode ?? this.postalCode,
      countryName: countryName ?? this.countryName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      website: website ?? this.website,
      taxCountry: taxCountry ?? this.taxCountry,
      taxIdentifier: taxIdentifier ?? this.taxIdentifier,
      logoData: clearLogo ? null : (logoData ?? this.logoData),
    );
  }
}

class AppPreferences {
  const AppPreferences({
    this.preferredCurrency = FinanceCurrency.usd,
    this.disputeWindowDays = 0,
    this.enableWhatsApp = true,
    this.enableTextMessages = true,
    this.enableEmail = true,
    this.companyProfile,
  });

  final FinanceCurrency preferredCurrency;
  final int disputeWindowDays;
  final bool enableWhatsApp;
  final bool enableTextMessages;
  final bool enableEmail;
  final CompanyProfile? companyProfile;

  AppPreferences copyWith({
    FinanceCurrency? preferredCurrency,
    int? disputeWindowDays,
    bool? enableWhatsApp,
    bool? enableTextMessages,
    bool? enableEmail,
    CompanyProfile? companyProfile,
    bool clearCompanyProfile = false,
  }) {
    return AppPreferences(
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      disputeWindowDays: disputeWindowDays ?? this.disputeWindowDays,
      enableWhatsApp: enableWhatsApp ?? this.enableWhatsApp,
      enableTextMessages: enableTextMessages ?? this.enableTextMessages,
      enableEmail: enableEmail ?? this.enableEmail,
      companyProfile: clearCompanyProfile
          ? null
          : (companyProfile ?? this.companyProfile),
    );
  }
}
