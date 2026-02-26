enum EmployeeCurrency { usd, eur }

class Employee {
  const Employee({
    required this.id,
    required this.name,
    this.roleTitle = '',
    this.team = '',
    this.phone,
    this.hourlyRate,
    this.currency,
    this.extraEarningsDescription,
    this.documentsDescription,
  });

  final String id;
  final String name;
  final String roleTitle;
  final String team;
  final String? phone;
  final double? hourlyRate;
  final EmployeeCurrency? currency;
  final String? extraEarningsDescription;
  final String? documentsDescription;
}
