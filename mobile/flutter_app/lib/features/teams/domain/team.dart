class Team {
  const Team({
    required this.id,
    required this.name,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final bool isDeleted;
  final DateTime? deletedAt;

  Team copyWith({
    String? id,
    String? name,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
