class Task {
  final int idTask;
  final int idUser;
  final int? idTaskTemplate;
  final bool isFointCandidate;
  final String name;
  final String? description;
  final bool isUrgent;
  final String scheduledDate;
  final String notificationType;
  final String status;
  final int? fointsEarned;
  final String createdAt;
  final bool isRecurrent;
  final String recurrenceType;
  final String? recurrenceDays;
  final String? recurrenceEndDate;

  Task({
    required this.idTask,
    required this.idUser,
    this.idTaskTemplate,
    required this.isFointCandidate,
    required this.name,
    this.description,
    required this.isUrgent,
    required this.scheduledDate,
    required this.notificationType,
    required this.status,
    this.fointsEarned,
    required this.createdAt,
    required this.isRecurrent,
    required this.recurrenceType,
    this.recurrenceDays,
    this.recurrenceEndDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      idTask:             json['id_task'],
      idUser:             json['id_user'],
      idTaskTemplate:     json['id_task_template'],
      isFointCandidate:   json['is_foint_candidate'] ?? false,
      name:               json['name'],
      description:        json['description'],
      isUrgent:           json['is_urgent'],
      scheduledDate:      json['scheduled_date'],
      notificationType:   json['notification_type'],
      status:             json['status'],
      fointsEarned:       json['foints_earned'],
      createdAt:          json['created_at'],
      isRecurrent:        json['is_recurrent'] ?? false,
      recurrenceType:     json['recurrence_type'] ?? 'ninguna',
      recurrenceDays:     json['recurrence_days'],
      recurrenceEndDate:  json['recurrence_end_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name':                name,
      'description':         description,
      'is_urgent':           isUrgent,
      'scheduled_date':      scheduledDate,
      'notification_type':   notificationType,
      'status':              status,
      'id_task_template':    idTaskTemplate,
      'is_foint_candidate':  isFointCandidate,
      'is_recurrent':        isRecurrent,
      'recurrence_type':     recurrenceType,
      'recurrence_days':     recurrenceDays,
      'recurrence_end_date': recurrenceEndDate,
    };
  }

  // Útil para actualizar campos puntuales sin recrear el objeto completo
  Task copyWith({
    int? idTask,
    int? idUser,
    int? idTaskTemplate,
    bool? isFointCandidate,
    String? name,
    String? description,
    bool? isUrgent,
    String? scheduledDate,
    String? notificationType,
    String? status,
    int? fointsEarned,
    String? createdAt,
    bool? isRecurrent,
    String? recurrenceType,
    String? recurrenceDays,
    String? recurrenceEndDate,
  }) {
    return Task(
      idTask:            idTask            ?? this.idTask,
      idUser:            idUser            ?? this.idUser,
      idTaskTemplate:    idTaskTemplate    ?? this.idTaskTemplate,
      isFointCandidate:  isFointCandidate  ?? this.isFointCandidate,
      name:              name              ?? this.name,
      description:       description       ?? this.description,
      isUrgent:          isUrgent          ?? this.isUrgent,
      scheduledDate:     scheduledDate     ?? this.scheduledDate,
      notificationType:  notificationType  ?? this.notificationType,
      status:            status            ?? this.status,
      fointsEarned:      fointsEarned      ?? this.fointsEarned,
      createdAt:         createdAt         ?? this.createdAt,
      isRecurrent:       isRecurrent       ?? this.isRecurrent,
      recurrenceType:    recurrenceType    ?? this.recurrenceType,
      recurrenceDays:    recurrenceDays    ?? this.recurrenceDays,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
    );
  }

  // ── Helpers de estado ───────────────────────────────────────────────────
  bool get isDone    => status == 'realizada';
  bool get isPending => status == 'pendiente';
  bool get isExpired => status == 'vencida';

  // Una tarea muestra el badge de Foints si es candidata Y tiene plantilla
  bool get showFointsBadge => isFointCandidate && idTaskTemplate != null;
}