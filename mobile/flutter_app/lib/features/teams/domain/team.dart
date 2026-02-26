class Team {
  const Team({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  Team copyWith({
    String? id,
    String? name,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
