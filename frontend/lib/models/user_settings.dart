class UserSettings {
  final int idUser;

  // ── Notificaciones ────────────────────────────────────────────────────────
  final bool notifPush;
  final bool notifTaskReminder;
  final bool notifTaskExpired;
  final bool notifUrgentTask;
  final bool notifNewFollower;
  final bool notifSuggestionResolved;
  final int notifReminderMinutes;

  // ── Preferencias generales ────────────────────────────────────────────────
  final String theme;
  final String language;
  final String? appPurpose;
  final bool referredByFriend;

  final String updatedAt;

  UserSettings({
    required this.idUser,
    required this.notifPush,
    required this.notifTaskReminder,
    required this.notifTaskExpired,
    required this.notifUrgentTask,
    required this.notifNewFollower,
    required this.notifSuggestionResolved,
    required this.notifReminderMinutes,
    required this.theme,
    required this.language,
    this.appPurpose,
    required this.referredByFriend,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      idUser:                    json['id_user'],
      notifPush:                 json['notif_push']                  ?? true,
      notifTaskReminder:         json['notif_task_reminder']         ?? true,
      notifTaskExpired:          json['notif_task_expired']          ?? true,
      notifUrgentTask:           json['notif_urgent_task']           ?? true,
      notifNewFollower:          json['notif_new_follower']          ?? true,
      notifSuggestionResolved:   json['notif_suggestion_resolved']   ?? true,
      notifReminderMinutes:      json['notif_reminder_minutes']      ?? 30,
      theme:                     json['theme']                       ?? 'claro',
      language:                  json['language']                    ?? 'es',
      appPurpose:                json['app_purpose'],
      referredByFriend:          json['referred_by_friend']          ?? false,
      updatedAt:                 json['updated_at']                  ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notif_push':                notifPush,
      'notif_task_reminder':       notifTaskReminder,
      'notif_task_expired':        notifTaskExpired,
      'notif_urgent_task':         notifUrgentTask,
      'notif_new_follower':        notifNewFollower,
      'notif_suggestion_resolved': notifSuggestionResolved,
      'notif_reminder_minutes':    notifReminderMinutes,
      'theme':                     theme,
      'language':                  language,
      'app_purpose':               appPurpose,
      'referred_by_friend':        referredByFriend,
    };
  }

  // Útil para actualizar campos puntuales desde la pantalla de configuración
  UserSettings copyWith({
    bool? notifPush,
    bool? notifTaskReminder,
    bool? notifTaskExpired,
    bool? notifUrgentTask,
    bool? notifNewFollower,
    bool? notifSuggestionResolved,
    int? notifReminderMinutes,
    String? theme,
    String? language,
    String? appPurpose,
    bool? referredByFriend,
    String? updatedAt,
  }) {
    return UserSettings(
      idUser:                  idUser,
      notifPush:               notifPush               ?? this.notifPush,
      notifTaskReminder:       notifTaskReminder       ?? this.notifTaskReminder,
      notifTaskExpired:        notifTaskExpired        ?? this.notifTaskExpired,
      notifUrgentTask:         notifUrgentTask         ?? this.notifUrgentTask,
      notifNewFollower:        notifNewFollower        ?? this.notifNewFollower,
      notifSuggestionResolved: notifSuggestionResolved ?? this.notifSuggestionResolved,
      notifReminderMinutes:    notifReminderMinutes    ?? this.notifReminderMinutes,
      theme:                   theme                   ?? this.theme,
      language:                language                ?? this.language,
      appPurpose:              appPurpose              ?? this.appPurpose,
      referredByFriend:        referredByFriend        ?? this.referredByFriend,
      updatedAt:               updatedAt               ?? this.updatedAt,
    );
  }

  bool get isDarkTheme => theme == 'oscuro';
}