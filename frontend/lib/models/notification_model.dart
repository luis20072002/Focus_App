class NotificationModel {
  final int idNotification;
  final int idUser;
  final NotificationType type;
  final String message;
  final bool read;
  final int? idReference;
  final String date;

  NotificationModel({
    required this.idNotification,
    required this.idUser,
    required this.type,
    required this.message,
    required this.read,
    this.idReference,
    required this.date,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotification: json['id_notification'],
      idUser:         json['id_user'],
      type:           NotificationType.fromString(json['type']),
      message:        json['message'],
      read:           json['read'] ?? false,
      idReference:    json['id_reference'],
      date:           json['date'],
    );
  }

  // Copia con read actualizado — usado por el provider al marcar como leída
  NotificationModel copyWithRead(bool read) {
    return NotificationModel(
      idNotification: idNotification,
      idUser:         idUser,
      type:           type,
      message:        message,
      read:           read,
      idReference:    idReference,
      date:           date,
    );
  }
}

// ── Tipos de notificación (enums del backend en español) ────────────────────

enum NotificationType {
  taskReminder,
  taskExpired,
  urgentTask,
  newFollower,
  suggestionResolved,
  unknown;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'recordatorio_tarea':   return NotificationType.taskReminder;
      case 'tarea_vencida':        return NotificationType.taskExpired;
      case 'tarea_urgente':        return NotificationType.urgentTask;
      case 'nuevo_seguidor':       return NotificationType.newFollower;
      case 'sugerencia_resuelta':  return NotificationType.suggestionResolved;
      default:                     return NotificationType.unknown;
    }
  }

  // Etiqueta legible para mostrar en la UI
  String get label {
    switch (this) {
      case NotificationType.taskReminder:       return 'Recordatorio';
      case NotificationType.taskExpired:        return 'Tarea vencida';
      case NotificationType.urgentTask:         return 'Tarea urgente';
      case NotificationType.newFollower:        return 'Nuevo seguidor';
      case NotificationType.suggestionResolved: return 'Sugerencia revisada';
      case NotificationType.unknown:            return 'Notificación';
    }
  }
}