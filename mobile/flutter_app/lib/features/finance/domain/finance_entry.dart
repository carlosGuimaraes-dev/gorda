enum FinanceEntryType { payable, receivable }

enum FinanceStatus { pending, paid }

enum FinanceCurrency { usd, eur }

enum FinanceKind { general, invoiceClient, payrollEmployee, expenseOutOfPocket }

enum FinancePaymentMethod { pix, card, cash }

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
    this.method,
    this.clientId,
    this.clientName,
    this.employeeId,
    this.employeeName,
    this.isDisputed = false,
    this.disputeReason,
    this.receiptData,
    this.supersededById,
    this.supersedesId,
    this.supersededAt,
    this.payrollPeriodStart,
    this.payrollPeriodEnd,
    this.payrollHoursWorked = 0,
    this.payrollDaysWorked = 0,
    this.payrollHourlyRate = 0,
    this.payrollBasePay = 0,
    this.payrollBonus = 0,
    this.payrollDeductions = 0,
    this.payrollTaxes = 0,
    this.payrollReimbursements = 0,
    this.payrollNetPay = 0,
    this.payrollNotes,
    this.notes,
  });

  final String id;
  final String title;
  final double amount;
  final FinanceCurrency currency;
  final FinanceEntryType type;
  final DateTime dueDate;
  final FinanceStatus status;
  final FinanceKind kind;
  final FinancePaymentMethod? method;
  final String? clientId;
  final String? clientName;
  final String? employeeId;
  final String? employeeName;
  final bool isDisputed;
  final String? disputeReason;
  final List<int>? receiptData;
  final String? supersededById;
  final String? supersedesId;
  final DateTime? supersededAt;
  final DateTime? payrollPeriodStart;
  final DateTime? payrollPeriodEnd;
  final double payrollHoursWorked;
  final int payrollDaysWorked;
  final double payrollHourlyRate;
  final double payrollBasePay;
  final double payrollBonus;
  final double payrollDeductions;
  final double payrollTaxes;
  final double payrollReimbursements;
  final double payrollNetPay;
  final String? payrollNotes;
  final String? notes;

  FinanceEntry copyWith({
    String? id,
    String? title,
    double? amount,
    FinanceCurrency? currency,
    FinanceEntryType? type,
    DateTime? dueDate,
    FinanceStatus? status,
    FinanceKind? kind,
    FinancePaymentMethod? method,
    bool clearMethod = false,
    String? clientId,
    String? clientName,
    String? employeeId,
    String? employeeName,
    bool? isDisputed,
    String? disputeReason,
    bool clearDisputeReason = false,
    List<int>? receiptData,
    bool clearReceiptData = false,
    String? supersededById,
    String? supersedesId,
    DateTime? supersededAt,
    DateTime? payrollPeriodStart,
    DateTime? payrollPeriodEnd,
    double? payrollHoursWorked,
    int? payrollDaysWorked,
    double? payrollHourlyRate,
    double? payrollBasePay,
    double? payrollBonus,
    double? payrollDeductions,
    double? payrollTaxes,
    double? payrollReimbursements,
    double? payrollNetPay,
    String? payrollNotes,
    bool clearPayrollNotes = false,
    String? notes,
    bool clearNotes = false,
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
      method: clearMethod ? null : (method ?? this.method),
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      isDisputed: isDisputed ?? this.isDisputed,
      disputeReason: clearDisputeReason
          ? null
          : (disputeReason ?? this.disputeReason),
      receiptData: clearReceiptData ? null : (receiptData ?? this.receiptData),
      supersededById: supersededById ?? this.supersededById,
      supersedesId: supersedesId ?? this.supersedesId,
      supersededAt: supersededAt ?? this.supersededAt,
      payrollPeriodStart: payrollPeriodStart ?? this.payrollPeriodStart,
      payrollPeriodEnd: payrollPeriodEnd ?? this.payrollPeriodEnd,
      payrollHoursWorked: payrollHoursWorked ?? this.payrollHoursWorked,
      payrollDaysWorked: payrollDaysWorked ?? this.payrollDaysWorked,
      payrollHourlyRate: payrollHourlyRate ?? this.payrollHourlyRate,
      payrollBasePay: payrollBasePay ?? this.payrollBasePay,
      payrollBonus: payrollBonus ?? this.payrollBonus,
      payrollDeductions: payrollDeductions ?? this.payrollDeductions,
      payrollTaxes: payrollTaxes ?? this.payrollTaxes,
      payrollReimbursements:
          payrollReimbursements ?? this.payrollReimbursements,
      payrollNetPay: payrollNetPay ?? this.payrollNetPay,
      payrollNotes: clearPayrollNotes ? null : (payrollNotes ?? this.payrollNotes),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
