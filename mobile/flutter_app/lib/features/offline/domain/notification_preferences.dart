class NotificationPreferences {
  const NotificationPreferences({
    this.enableClientNotifications = true,
    this.enableTeamNotifications = true,
    this.enablePush = true,
    this.enableSiri = false,
  });

  final bool enableClientNotifications;
  final bool enableTeamNotifications;
  final bool enablePush;
  final bool enableSiri;

  NotificationPreferences copyWith({
    bool? enableClientNotifications,
    bool? enableTeamNotifications,
    bool? enablePush,
    bool? enableSiri,
  }) {
    return NotificationPreferences(
      enableClientNotifications:
          enableClientNotifications ?? this.enableClientNotifications,
      enableTeamNotifications:
          enableTeamNotifications ?? this.enableTeamNotifications,
      enablePush: enablePush ?? this.enablePush,
      enableSiri: enableSiri ?? this.enableSiri,
    );
  }
}
