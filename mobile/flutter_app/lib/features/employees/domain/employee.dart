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

  Employee copyWith({
    String? id,
    String? name,
    String? roleTitle,
    String? team,
    String? phone,
    double? hourlyRate,
    EmployeeCurrency? currency,
    String? extraEarningsDescription,
    String? documentsDescription,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      roleTitle: roleTitle ?? this.roleTitle,
      team: team ?? this.team,
      phone: phone ?? this.phone,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      currency: currency ?? this.currency,
      extraEarningsDescription:
          extraEarningsDescription ?? this.extraEarningsDescription,
      documentsDescription: documentsDescription ?? this.documentsDescription,
    );
  }
}
