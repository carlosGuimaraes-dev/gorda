enum UserRole { employee, manager }

class UserSession {
  const UserSession(
      {required this.token, required this.name, required this.role});

  final String token;
  final String name;
  final UserRole role;
}
