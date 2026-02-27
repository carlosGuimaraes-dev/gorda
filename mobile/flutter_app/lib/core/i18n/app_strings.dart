import 'package:flutter/material.dart';

class AppStrings {
  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(Locale locale) => AppStrings(locale);

  bool get _isEs => locale.languageCode == 'es';

  String get welcomeBack => _isEs ? 'Bienvenido de nuevo' : 'Welcome back';
  String get signInSubtitle => _isEs
      ? 'Inicia sesión para gestionar tus servicios'
      : 'Sign in to manage your services';
  String get user => _isEs ? 'Usuario' : 'User';
  String get signIn => _isEs ? 'Iniciar sesión' : 'Sign in';
  String get dashboard => _isEs ? 'Panel' : 'Dashboard';
  String get schedule => _isEs ? 'Agenda' : 'Schedule';
  String get clients => _isEs ? 'Clientes' : 'Clients';
  String get finance => _isEs ? 'Finanzas' : 'Finance';
  String get settings => _isEs ? 'Ajustes' : 'Settings';
  String get employee => _isEs ? 'Empleado' : 'Employee';
  String get manager => _isEs ? 'Gerente' : 'Manager';
  String get forceSync => _isEs ? 'Forzar sincronización' : 'Force sync';
  String get day => _isEs ? 'Día' : 'Day';
  String get week => _isEs ? 'Semana' : 'Week';
  String get month => _isEs ? 'Mes' : 'Month';
  String get team => _isEs ? 'Equipo' : 'Team';
  String get allTeams => _isEs ? 'Todos los equipos' : 'All teams';
  String get noTasksForFilter => _isEs
      ? 'No hay servicios para este filtro.'
      : 'No services found for this filter.';
  String get noActiveSession =>
      _isEs ? 'No hay sesión activa' : 'No active session';
  String get client => _isEs ? 'Cliente' : 'Client';
  String get address => _isEs ? 'Dirección' : 'Address';
  String get advanceStatus => _isEs ? 'Avanzar estado' : 'Advance status';
  String get newService => _isEs ? 'Nuevo servicio' : 'New service';
  String get all => _isEs ? 'Todos' : 'All';
  String get scheduled => _isEs ? 'Programado' : 'Scheduled';
  String get inProgress => _isEs ? 'En progreso' : 'In progress';
  String get completed => _isEs ? 'Completado' : 'Completed';
  String get canceled => _isEs ? 'Cancelado' : 'Canceled';
  String get hello => _isEs ? 'Hola' : 'Hello';
  String get workload => _isEs ? 'Carga de trabajo' : 'Workload';
  String get todayLabel => _isEs ? 'Hoy' : 'Today';
  String get workedHours => _isEs ? 'Horas trabajadas' : 'Worked hours';
  String get estimatedEarnings =>
      _isEs ? 'Ganancias estimadas' : 'Estimated earnings';
  String get noServicesInPeriod => _isEs
      ? 'No hay servicios en este período.'
      : 'No services in this period.';
  String get nextServices => _isEs ? 'Próximos servicios' : 'Next services';
  String get operations => _isEs ? 'Operaciones' : 'Operations';
  String get totalTasks => _isEs ? 'Total de servicios' : 'Total tasks';
  String get byTeam => _isEs ? 'Por equipo' : 'By team';
  String get receivables => _isEs ? 'Cuentas por cobrar' : 'Receivables';
  String get payables => _isEs ? 'Cuentas por pagar' : 'Payables';
  String get netCashPending =>
      _isEs ? 'Caja neta (pendiente)' : 'Net cash (pending)';
  String get filters => _isEs ? 'Filtros' : 'Filters';
  String get newItem => _isEs ? 'Nuevo' : 'New';
  String get searchClient => _isEs ? 'Buscar cliente' : 'Search client';
  String get noClientsForFilter => _isEs
      ? 'Ningún cliente coincide con los filtros.'
      : 'No clients match current filters.';
  String get clientFilters => _isEs ? 'Filtros de clientes' : 'Client Filters';
  String get status => _isEs ? 'Estado' : 'Status';
  String get active => _isEs ? 'Activo' : 'Active';
  String get inactive => _isEs ? 'Inactivo' : 'Inactive';
  String get period => _isEs ? 'Período' : 'Period';
  String get currentMonth => _isEs ? 'Mes actual' : 'Current month';
  String get last30Days => _isEs ? 'Últimos 30 días' : 'Last 30 days';
  String get sortBy => _isEs ? 'Ordenar por' : 'Sort by';
  String get nameAsc => _isEs ? 'Nombre (A-Z)' : 'Name (A-Z)';
  String get nameDesc => _isEs ? 'Nombre (Z-A)' : 'Name (Z-A)';
  String get pendingReceivablesDesc => _isEs
      ? 'Cobros pendientes (mayor primero)'
      : 'Pending receivables (high to low)';
  String get reset => _isEs ? 'Reiniciar' : 'Reset';
  String get newClient => _isEs ? 'Nuevo cliente' : 'New client';
  String get clientName => _isEs ? 'Nombre del cliente' : 'Client name';
  String get phone => _isEs ? 'Teléfono' : 'Phone';
  String get date => _isEs ? 'Fecha' : 'Date';
  String get start => _isEs ? 'Inicio' : 'Start';
  String get end => _isEs ? 'Fin' : 'End';
  String get close => _isEs ? 'Cerrar' : 'Close';
  String get save => _isEs ? 'Guardar' : 'Save';
  String get title => _isEs ? 'Título' : 'Title';
  String get notes => _isEs ? 'Notas' : 'Notes';
  String get change => _isEs ? 'Cambiar' : 'Change';
  String get execution => _isEs ? 'Ejecución' : 'Execution';
  String get checkIn => _isEs ? 'Check-in' : 'Check-in';
  String get checkOut => _isEs ? 'Check-out' : 'Check-out';
  String get taskNotFound =>
      _isEs ? 'Servicio no encontrado' : 'Task not found';
  String get newFinanceEntry =>
      _isEs ? 'Nuevo registro financiero' : 'New finance entry';
  String get amount => _isEs ? 'Monto' : 'Amount';
  String get type => _isEs ? 'Tipo' : 'Type';
  String get receivable => _isEs ? 'Por cobrar' : 'Receivable';
  String get payable => _isEs ? 'Por pagar' : 'Payable';
  String get currency => _isEs ? 'Moneda' : 'Currency';
  String get payroll => _isEs ? 'Nómina' : 'Payroll';
  String get noPayrollEntriesYet =>
      _isEs ? 'Aún no hay registros de nómina.' : 'No payroll entries yet.';
  String get session => _isEs ? 'Sesión' : 'Session';
  String get sync => _isEs ? 'Sincronización' : 'Sync';
  String get signOut => _isEs ? 'Cerrar sesión' : 'Sign out';
  String get last => _isEs ? 'Último' : 'Last';
  String get pendingChangesInQueue =>
      _isEs ? 'cambios pendientes en la cola' : 'pending changes in the queue';
  String get appPreferences =>
      _isEs ? 'Preferencias de la app' : 'App preferences';
  String get language => _isEs ? 'Idioma' : 'Language';
  String get notifications => _isEs ? 'Notificaciones' : 'Notifications';
  String get notificationsForClients =>
      _isEs ? 'Notificaciones para clientes' : 'Notifications for clients';
  String get notificationsForTeam =>
      _isEs ? 'Notificaciones para el equipo' : 'Notifications for team';
  String get pushNotifications =>
      _isEs ? 'Notificaciones push' : 'Push notifications';
  String get siriSuggestions =>
      _isEs ? 'Sugerencias de Siri' : 'Siri suggestions';
  String get deliveryChannels =>
      _isEs ? 'Canales de entrega' : 'Delivery channels';
  String get textMessage => _isEs ? 'Mensaje de texto' : 'Text Message';
  String get navigation => _isEs ? 'Navegación' : 'Navigation';
  String get catalogs => _isEs ? 'Catálogos' : 'Catalogs';
  String get services => _isEs ? 'Servicios' : 'Services';
  String get employees => _isEs ? 'Empleados' : 'Employees';
  String get teams => _isEs ? 'Equipos' : 'Teams';
  String get newTeam => _isEs ? 'Nuevo equipo' : 'New Team';
  String get removeTeam => _isEs ? 'Eliminar equipo' : 'Remove team';
  String get editTeam => _isEs ? 'Editar equipo' : 'Edit team';
  String get deleteTeamQuestion => _isEs ? '¿Eliminar equipo?' : 'Delete team?';
  String get assignEmployees =>
      _isEs ? 'Asignar empleados' : 'Assign employees';
  String get selectAtLeastOneEmployee => _isEs
      ? 'Seleccione al menos un empleado.'
      : 'Select at least one employee.';
  String get teamNameAlreadyExists => _isEs
      ? 'Ya existe un equipo con este nombre.'
      : 'A team with this name already exists.';
  String get unableToSaveTeam =>
      _isEs ? 'No se pudo guardar el equipo.' : 'Unable to save team.';
  String get unassigned => _isEs ? 'Sin asignar' : 'Unassigned';
  String get removeFromTeam =>
      _isEs ? 'Remover del equipo' : 'Remove from team';
  String get moveTo => _isEs ? 'Mover a' : 'Move to';
  String get noEmployeesYet =>
      _isEs ? 'Aún no hay empleados.' : 'No employees yet.';
  String get name => _isEs ? 'Nombre' : 'Name';
  String get roleTitle => _isEs ? 'Rol / Título' : 'Role / Title';
  String get hourlyRate => _isEs ? 'Tarifa por hora' : 'Hourly rate';
  String get assignedServices =>
      _isEs ? 'Servicios asignados' : 'Assigned services';
  String get noAssignedServices =>
      _isEs ? 'Sin servicios asignados.' : 'No assigned services.';
  String get employeeNotFound =>
      _isEs ? 'Empleado no encontrado' : 'Employee not found';
  String get newEmployee => _isEs ? 'Nuevo empleado' : 'New Employee';
  String get editEmployee => _isEs ? 'Editar empleado' : 'Edit Employee';
  String get deleteEmployee => _isEs ? 'Eliminar empleado' : 'Delete employee';
  String get deleteEmployeeQuestion =>
      _isEs ? '¿Eliminar empleado?' : 'Delete employee?';
  String get cannotDeleteEmployee =>
      _isEs ? 'No se puede eliminar' : 'Cannot delete';
  String get employeeDeleteBlocked => _isEs
      ? 'Este empleado tiene servicios o finanzas vinculados.'
      : 'This employee has linked services or finance entries.';
  String get edit => _isEs ? 'Editar' : 'Edit';
  String get delete => _isEs ? 'Eliminar' : 'Delete';
  String get cancel => _isEs ? 'Cancelar' : 'Cancel';
  String get property => _isEs ? 'Propiedad' : 'Property';
  String get preferredSchedule =>
      _isEs ? 'Horario preferido' : 'Preferred schedule';
  String get accessNotes => _isEs ? 'Notas de acceso' : 'Access notes';
  String get serviceHistory =>
      _isEs ? 'Historial de servicios' : 'Service history';
  String get noServicesRegisteredYet => _isEs
      ? 'Aún no hay servicios registrados.'
      : 'No services registered yet.';
  String get createService => _isEs ? 'Crear servicio' : 'Create service';
  String get editClient => _isEs ? 'Editar cliente' : 'Edit client';
  String get deleteClientQuestion =>
      _isEs ? '¿Eliminar cliente?' : 'Delete client?';
  String get clientDeleteBlocked => _isEs
      ? 'Este cliente tiene servicios o finanzas vinculados.'
      : 'This client has linked services or finance entries.';
  String get clientNotFound =>
      _isEs ? 'Cliente no encontrado' : 'Client not found';
  String get newServiceType => _isEs ? 'Nuevo servicio' : 'New Service';
  String get editService => _isEs ? 'Editar servicio' : 'Edit service';
  String get description => _isEs ? 'Descripción' : 'Description';
  String get basePrice => _isEs ? 'Precio base' : 'Base price';
  String get pricingModel => _isEs ? 'Modelo de precio' : 'Pricing model';
  String get perTask => _isEs ? 'Por servicio' : 'Per task';
  String get perHour => _isEs ? 'Por hora' : 'Per hour';
  String get serviceNotFound =>
      _isEs ? 'Servicio no encontrado' : 'Service not found';
  String get service => _isEs ? 'Servicio' : 'Service';
  String get usage => _isEs ? 'Uso' : 'Usage';
  String get reassignBeforeDelete =>
      _isEs ? 'Reasigne antes de eliminar.' : 'Reassign before deleting.';
  String get deleteService => _isEs ? 'Eliminar servicio' : 'Delete service';
  String get deleteServiceQuestion =>
      _isEs ? '¿Eliminar servicio?' : 'Delete service?';
  String get cannotDeleteService =>
      _isEs ? 'No se puede eliminar el servicio' : 'Cannot delete service';
  String get serviceDeleteBlocked => _isEs
      ? 'Este tipo de servicio está vinculado a tareas existentes. Reasigna o elimina esas tareas antes de borrar.'
      : 'This service type is linked to existing tasks. Reassign or remove those tasks before deleting.';
  String get pending => _isEs ? 'Pendiente' : 'Pending';
  String get paid => _isEs ? 'Pagado' : 'Paid';
  String get invoice => _isEs ? 'Factura' : 'Invoice';
  String get invoiceLabel => _isEs ? 'Factura' : 'Invoice';
  String get invoices => _isEs ? 'Facturas' : 'Invoices';
  String get newInvoice => _isEs ? 'Nueva factura' : 'New Invoice';
  String get dueDate => _isEs ? 'Fecha de vencimiento' : 'Due date';
  String get none => _isEs ? 'Ninguno' : 'None';
  String get method => _isEs ? 'Método' : 'Method';
  String get pix => _isEs ? 'Pix' : 'Pix';
  String get card => _isEs ? 'Tarjeta' : 'Card';
  String get cash => _isEs ? 'Efectivo' : 'Cash';
  String get lineItems => _isEs ? 'Líneas' : 'Line items';
  String get qty => _isEs ? 'Cant.' : 'Qty';
  String get unit => _isEs ? 'Unidad' : 'Unit';
  String get total => _isEs ? 'Total' : 'Total';
  String get disputed => _isEs ? 'En disputa' : 'Disputed';
  String get superseded => _isEs ? 'Sustituida' : 'Superseded';
  String get dispute => _isEs ? 'Disputa' : 'Dispute';
  String get clientDisputed =>
      _isEs ? 'Cliente en disputa' : 'Client disputed';
  String get clientMessageReason =>
      _isEs ? 'Mensaje / motivo del cliente' : 'Client message / reason';
  String get sendInvoice => _isEs ? 'Enviar factura' : 'Send invoice';
  String get sendReissue => _isEs ? 'Enviar / Reemitir' : 'Send / Reissue';
  String get previewPdf => _isEs ? 'Previsualizar PDF' : 'Preview PDF';
  String get sharePdf => _isEs ? 'Compartir PDF' : 'Share PDF';
  String get reissueInvoice =>
      _isEs ? 'Reemitir factura' : 'Reissue invoice';
  String get reissueInvoiceQuestion =>
      _isEs ? '¿Reemitir factura?' : 'Reissue invoice?';
  String get adjustmentsBlocked => _isEs
      ? 'Los ajustes se bloquean a menos de 1 día del vencimiento.'
      : 'Adjustments are blocked less than 1 day before due date.';
  String get noAvailableChannels => _isEs
      ? 'Sin canales disponibles. Agrega teléfono o email del cliente.'
      : 'No available channels. Add phone or email for this client.';
  String get channel => _isEs ? 'Canal' : 'Channel';
  String get whatsapp => _isEs ? 'WhatsApp' : 'WhatsApp';
  String get email => _isEs ? 'Email' : 'Email';
  String get unknown => _isEs ? 'Desconocido' : 'Unknown';
  String get task => _isEs ? 'Tarea' : 'Task';
  String get financeEntry =>
      _isEs ? 'Registro financiero' : 'Finance entry';
  String get expense => _isEs ? 'Gasto' : 'Expense';
  String get receipt => _isEs ? 'Recibo' : 'Receipt';
  String get shareReceipt => _isEs ? 'Compartir recibo' : 'Share receipt';
  String get receipts => _isEs ? 'Recibos' : 'Receipts';
  String get receiptsHub => _isEs ? 'Hub de recibos' : 'Receipts hub';
  String get receiptQueue => _isEs ? 'Cola de recibos' : 'Receipt queue';
  String get offlineQueue => _isEs ? 'Cola offline' : 'Offline queue';
  String get forceSyncNow =>
      _isEs ? 'Forzar sync ahora' : 'Force sync now';
  String get suggestedContext =>
      _isEs ? 'Contexto sugerido' : 'Suggested context';
  String get noSuggestedTask =>
      _isEs ? 'No hay tarea sugerida.' : 'No suggested task available.';
  String get latestLocalReceipts =>
      _isEs ? 'Últimos recibos locales' : 'Latest local receipts';
  String get noReceiptsCapturedYet =>
      _isEs ? 'Aún no hay recibos capturados.' : 'No receipts captured yet.';
  String get scanNew => _isEs ? 'Escanear nuevo' : 'Scan new';
  String get cameraUnavailableMessage => _isEs
      ? 'La cámara no está disponible en este dispositivo.'
      : 'Camera is unavailable on this device.';
  String get clientOptional =>
      _isEs ? 'Cliente (opcional)' : 'Client (optional)';
  String get unlinked => _isEs ? 'Sin vínculo' : 'Unlinked';
  String get saveReceipt => _isEs ? 'Guardar recibo' : 'Save receipt';
  String get emission => _isEs ? 'Emisión' : 'Emission';
  String get readyForEmission =>
      _isEs ? 'Listo para emitir' : 'Ready for emission';
  String get emitNow => _isEs ? 'Emitir ahora' : 'Emit now';
  String get primaryLabel => _isEs ? 'Principal' : 'Primary';
  String get fallbackLabel => _isEs ? 'Secundario' : 'Fallback';
  String get notConfigured =>
      _isEs ? 'No configurado' : 'Not configured';
  String get closingFlow =>
      _isEs ? 'Flujo de cierre' : 'Closing flow';
  String get closingWizard =>
      _isEs ? 'Asistente de cierre' : 'Closing wizard';
  String get readyToEmit => _isEs ? 'Listo para emitir' : 'Ready to emit';
  String get endOfMonth => _isEs ? 'Fin de mes' : 'End of month';
  String get generateClientInvoices => _isEs
      ? 'Generar facturas de clientes'
      : 'Generate client invoices';
  String get generatePayroll =>
      _isEs ? 'Generar nómina' : 'Generate payroll';
  String get invoicesAndPayroll =>
      _isEs ? 'Facturas y nómina' : 'Invoices & Payroll';
  String get monthlyReports =>
      _isEs ? 'Reportes mensuales' : 'Monthly reports';
  String get monthlyClosing =>
      _isEs ? 'Cierre mensual' : 'Monthly closing';
  String get closingPeriod =>
      _isEs ? 'Período de cierre' : 'Closing period';
  String get back => _isEs ? 'Atrás' : 'Back';
  String get ready => _isEs ? 'Listo' : 'Ready';
  String get review => _isEs ? 'Revisión' : 'Review';
  String get finishClosing =>
      _isEs ? 'Finalizar cierre' : 'Finish closing';
  String get continueLabel => _isEs ? 'Continuar' : 'Continue';
  String get resolvePendingIssuesFirst => _isEs
      ? 'Resuelve pendientes primero'
      : 'Resolve pending issues first';
  String get resolvePendingIssuesHelp => _isEs
      ? 'Corrige recibos sin cliente y conflictos de sync antes de avanzar.'
      : 'Fix receipts without client link and sync conflicts before moving forward.';
  String get receiptsWithoutClientLink =>
      _isEs ? 'Recibos sin cliente' : 'Receipts without client link';
  String get syncConflicts =>
      _isEs ? 'Conflictos de sincronización' : 'Sync conflicts';
  String get resolveTheseItems => _isEs
      ? 'Resuelve estos ítems para desbloquear el próximo paso.'
      : 'Resolve these items to unlock the next step.';
  String get stepSelectPeriod =>
      _isEs ? 'Paso 1: Seleccionar período' : 'Step 1: Select period';
  String get stepSelectPeriodHelp => _isEs
      ? 'Elige el mes para validar recibos, facturas y nómina pendientes.'
      : 'Choose the month to validate pending receipts, invoices and payroll.';
  String get stepPendingChecks =>
      _isEs ? 'Paso 2: Chequeos pendientes' : 'Step 2: Pending checks';
  String get stepReviewTotals =>
      _isEs ? 'Paso 3: Revisar totales' : 'Step 3: Review totals';
  String get stepReadyToEmit =>
      _isEs ? 'Paso 4: Listo para emitir' : 'Step 4: Ready to emit';
  String get stepReadyToEmitHelp => _isEs
      ? 'Tu lote mensual está listo. Continúa con emisión de facturas y nómina.'
      : 'Your monthly batch is ready. Continue with invoice and payroll emission.';
  String get newPayroll => _isEs ? 'Nueva nómina' : 'New Payroll';
  String get payrollLabel => _isEs ? 'Nómina' : 'Payroll';
  String get fromLabel => _isEs ? 'Desde' : 'From';
  String get toLabel => _isEs ? 'Hasta' : 'To';
  String get daysWorked => _isEs ? 'Días trabajados' : 'Days worked';
  String get hoursWorkedLabel =>
      _isEs ? 'Horas trabajadas' : 'Hours worked';
  String get basePay => _isEs ? 'Salario base' : 'Base pay';
  String get bonus => _isEs ? 'Bono' : 'Bonus';
  String get deductions => _isEs ? 'Deducciones' : 'Deductions';
  String get taxes => _isEs ? 'Impuestos' : 'Taxes';
  String get reimbursements =>
      _isEs ? 'Reembolsos' : 'Reimbursements';
  String get netPay => _isEs ? 'Pago neto' : 'Net pay';
  String get confirmPayroll =>
      _isEs ? 'Confirmar nómina' : 'Confirm payroll';
  String get confirmPayrollHelp => _isEs
      ? 'Este registro de nómina es manual. Confirma para continuar.'
      : 'This payroll entry is manual. Confirm to continue.';
  String get create => _isEs ? 'Crear' : 'Create';
  String get editingLockedAfterPayment => _isEs
      ? 'La edición se bloquea después de confirmar el pago.'
      : 'Editing is locked after payment confirmation.';
  String get reports => _isEs ? 'Reportes' : 'Reports';
  String get customRange =>
      _isEs ? 'Rango personalizado' : 'Custom range';
  String get startDate =>
      _isEs ? 'Fecha de inicio' : 'Start date';
  String get endDate => _isEs ? 'Fecha de fin' : 'End date';
  String get noDataForPeriod =>
      _isEs ? 'Sin datos para este período.' : 'No data for this period.';
  String get topClients => _isEs ? 'Top clientes' : 'Top clients';
  String get topEmployees =>
      _isEs ? 'Top empleados' : 'Top employees';
  String get net => _isEs ? 'Neto' : 'Net';
  String get export => _isEs ? 'Exportar' : 'Export';
  String get exportCsv => _isEs ? 'Exportar CSV' : 'Export CSV';
  String get exportPdf => _isEs ? 'Exportar PDF' : 'Export PDF';
  String get generate => _isEs ? 'Generar' : 'Generate';
  String get generateInvoicesTitle =>
      _isEs ? 'Generar facturas' : 'Generate invoices';
  String get generatePayrollTitle =>
      _isEs ? 'Generar nómina' : 'Generate payroll';
  String get allClients => _isEs ? 'Todos los clientes' : 'All clients';
  String get allEmployees =>
      _isEs ? 'Todos los empleados' : 'All employees';
  String get noEntries =>
      _isEs ? 'No hay registros.' : 'No entries.';
  String get oneTask => _isEs ? '1 servicio' : '1 task';
  String hoursQuantity(double value) =>
      _isEs ? '${value.toStringAsFixed(2)} h' : '${value.toStringAsFixed(2)} h';
  String calculatedDays(int days) =>
      _isEs ? 'Días calculados: $days' : 'Calculated days: $days';
  String disputesAllowedUntil(String dateText) => _isEs
      ? 'Las disputas están permitidas hasta $dateText.'
      : 'Disputes are allowed until $dateText.';
  String get disputesAllowedUntilDueDate => _isEs
      ? 'Las disputas están permitidas hasta la fecha de vencimiento.'
      : 'Disputes are allowed until the due date.';
  String disputeWindowClosedOn(String dateText) => _isEs
      ? 'La ventana de disputa cerró el $dateText.'
      : 'Dispute window closed on $dateText.';
  String supersededOn(String dateText) =>
      _isEs ? 'Sustituida el $dateText' : 'Superseded on $dateText';
  String summaryByCurrency(String currencyCode) => _isEs
      ? 'Resumen ($currencyCode)'
      : 'Summary ($currencyCode)';
  String reportLabel(bool monthly) =>
      monthly ? (_isEs ? 'Reporte mensual' : 'Monthly report') : (_isEs ? 'Reporte' : 'Report');
  String expenseReceiptShare(String title, String amount, String due) => _isEs
      ? 'Recibo de gasto para $title\nMonto: $amount\nVencimiento: $due'
      : 'Expense receipt for $title\nAmount: $amount\nDue: $due';
}
