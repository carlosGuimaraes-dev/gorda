class ServiceTask {
  const ServiceTask({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.assignedEmployeeId,
    required this.clientName,
    required this.address,
    this.clientId,
    this.startTime,
    this.endTime,
    this.notes = '',
    this.checkInTime,
    this.checkOutTime,
  });

  final String id;
  final String title;
  final DateTime date;
  final TaskStatus status;
  final String assignedEmployeeId;
  final String? clientId;
  final String clientName;
  final String address;
  final DateTime? startTime;
  final DateTime? endTime;
  final String notes;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  ServiceTask copyWith({
    String? id,
    String? title,
    DateTime? date,
    TaskStatus? status,
    String? assignedEmployeeId,
    String? clientId,
    String? clientName,
    String? address,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    return ServiceTask(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }
}

enum TaskStatus { scheduled, inProgress, completed, canceled }
