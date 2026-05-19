class Task {
  final int     idTask;
  final int     idUser;
  final int?    idTaskTemplate;
  final bool    isFointCandidate;
  final String  name;
  final String? description;
  final bool    isUrgent;
  final String  scheduledDate;
  final String  notificationType;
  final String  status;
  final int?    fointsEarned;
  final String  createdAt;
  final bool    isRecurrent;
  final String  recurrenceType;
  final String? recurrenceDays;
  final String? recurrenceEndDate;

  const Task({
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

  // ── Deserialización ───────────────────────────────────────────────────────

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      idTask:            json['id_task']           as int,
      idUser:            json['id_user']           as int,
      idTaskTemplate:    json['id_task_template']  as int?,
      isFointCandidate:  json['is_foint_candidate'] as bool? ?? false,
      name:              json['name']              as String,
      description:       json['description']       as String?,
      isUrgent:          json['is_urgent']         as bool,
      scheduledDate:     json['scheduled_date']    as String,
      notificationType:  json['notification_type'] as String,
      status:            json['status']            as String,
      fointsEarned:      json['foints_earned']     as int?,
      createdAt:         json['created_at']        as String,
      isRecurrent:       json['is_recurrent']      as bool? ?? false,
      recurrenceType:    json['recurrence_type']   as String? ?? 'ninguna',
      recurrenceDays:    json['recurrence_days']   as String?,
      recurrenceEndDate: json['recurrence_end_date'] as String?,
    );
  }

  // ── Serialización (solo campos editables, para PATCH /tasks/{id}) ─────────

  Map<String, dynamic> toJson() {
    return {
      'name':                name,
      'description':         description,
      'is_urgent':           isUrgent,
      'scheduled_date':      scheduledDate,
      'notification_type':   notificationType,
      'id_task_template':    idTaskTemplate,
      'is_foint_candidate':  isFointCandidate,
      'is_recurrent':        isRecurrent,
      'recurrence_type':     recurrenceType,
      'recurrence_days':     recurrenceDays,
      'recurrence_end_date': recurrenceEndDate,
    };
  }

  // ── copyWith con soporte explícito de null en campos opcionales ───────────
  //
  // El patron _Sentinel evita la ambigüedad entre "no se pasó el campo"
  // y "se quiere asignar null explícitamente". Sin esto, copyWith nunca
  // podría limpiar idTaskTemplate o fointsEarned a null tras una edición.

  static const _absent = Object();

  Task copyWith({
    int?    idTask,
    int?    idUser,
    Object? idTaskTemplate    = _absent,
    bool?   isFointCandidate,
    String? name,
    Object? description       = _absent,
    bool?   isUrgent,
    String? scheduledDate,
    String? notificationType,
    String? status,
    Object? fointsEarned      = _absent,
    String? createdAt,
    bool?   isRecurrent,
    String? recurrenceType,
    Object? recurrenceDays    = _absent,
    Object? recurrenceEndDate = _absent,
  }) {
    return Task(
      idTask:            idTask           ?? this.idTask,
      idUser:            idUser           ?? this.idUser,
      idTaskTemplate:    idTaskTemplate   == _absent
          ? this.idTaskTemplate
          : idTaskTemplate as int?,
      isFointCandidate:  isFointCandidate ?? this.isFointCandidate,
      name:              name             ?? this.name,
      description:       description      == _absent
          ? this.description
          : description as String?,
      isUrgent:          isUrgent         ?? this.isUrgent,
      scheduledDate:     scheduledDate    ?? this.scheduledDate,
      notificationType:  notificationType ?? this.notificationType,
      status:            status           ?? this.status,
      fointsEarned:      fointsEarned     == _absent
          ? this.fointsEarned
          : fointsEarned as int?,
      createdAt:         createdAt        ?? this.createdAt,
      isRecurrent:       isRecurrent      ?? this.isRecurrent,
      recurrenceType:    recurrenceType   ?? this.recurrenceType,
      recurrenceDays:    recurrenceDays   == _absent
          ? this.recurrenceDays
          : recurrenceDays as String?,
      recurrenceEndDate: recurrenceEndDate == _absent
          ? this.recurrenceEndDate
          : recurrenceEndDate as String?,
    );
  }

  // ── Helpers de estado ─────────────────────────────────────────────────────

  bool get isDone    => status == 'realizada';
  bool get isPending => status == 'pendiente';
  bool get isExpired => status == 'vencida';

  /// True si la tarea puede mostrar el badge de Foints.
  /// Requiere candidatura activa Y plantilla asociada.
  bool get showFointsBadge => isFointCandidate && idTaskTemplate != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && idTask == other.idTask;

  @override
  int get hashCode => idTask.hashCode;

  @override
  String toString() => 'Task(id=$idTask, name=$name, status=$status)';
}