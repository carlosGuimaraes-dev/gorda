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
}
