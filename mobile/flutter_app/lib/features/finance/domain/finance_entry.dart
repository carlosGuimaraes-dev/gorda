enum FinanceEntryType { payable, receivable }

enum FinanceStatus { pending, paid }

enum FinanceCurrency { usd, eur }

enum FinanceKind { general, invoiceClient, payrollEmployee, expenseOutOfPocket }

class FinanceEntry {
  const FinanceEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.type,
    required this.dueDate,
    required this.status,
    required this.kind,
    this.clientId,
    this.clientName,
    this.employeeId,
    this.employeeName,
  });

  final String id;
  final String title;
  final double amount;
  final FinanceCurrency currency;
  final FinanceEntryType type;
  final DateTime dueDate;
  final FinanceStatus status;
  final FinanceKind kind;
  final String? clientId;
  final String? clientName;
  final String? employeeId;
  final String? employeeName;

  FinanceEntry copyWith({
    String? id,
    String? title,
    double? amount,
    FinanceCurrency? currency,
    FinanceEntryType? type,
    DateTime? dueDate,
    FinanceStatus? status,
    FinanceKind? kind,
    String? clientId,
    String? clientName,
    String? employeeId,
    String? employeeName,
  }) {
    return FinanceEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
    );
  }
}
