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
}
