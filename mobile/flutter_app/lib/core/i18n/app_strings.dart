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
  String get month => _isEs ? 'Mes' : 'Month';
  String get team => _isEs ? 'Equipo' : 'Team';
  String get allTeams => _isEs ? 'Todos los equipos' : 'All teams';
  String get noTasksForFilter => _isEs
      ? 'No hay servicios para este filtro.'
      : 'No services found for this filter.';
  String get client => _isEs ? 'Cliente' : 'Client';
  String get address => _isEs ? 'Dirección' : 'Address';
  String get advanceStatus => _isEs ? 'Avanzar estado' : 'Advance status';
  String get newService => _isEs ? 'Nuevo servicio' : 'New service';
  String get all => _isEs ? 'Todos' : 'All';
  String get scheduled => _isEs ? 'Programado' : 'Scheduled';
  String get inProgress => _isEs ? 'En progreso' : 'In progress';
  String get completed => _isEs ? 'Completado' : 'Completed';
  String get canceled => _isEs ? 'Cancelado' : 'Canceled';
}
