class Suggestion {
  final int idSuggestion;
  final int idUser;
  final SuggestionType type;
  final String content;
  final SuggestionStatus status;
  final int? idAdmin;
  final String date;

  Suggestion({
    required this.idSuggestion,
    required this.idUser,
    required this.type,
    required this.content,
    required this.status,
    this.idAdmin,
    required this.date,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      idSuggestion: json['id_suggestion'],
      idUser:       json['id_user'],
      type:         SuggestionType.fromString(json['type']),
      content:      json['content'],
      status:       SuggestionStatus.fromString(json['status']),
      idAdmin:      json['id_admin'],
      date:         json['date'],
    );
  }

  bool get isPending  => status == SuggestionStatus.pending;
  bool get isApproved => status == SuggestionStatus.approved;
  bool get isRejected => status == SuggestionStatus.rejected;
}

// ── Tipo de sugerencia ───────────────────────────────────────────────────────

enum SuggestionType {
  task,
  category;

  static SuggestionType fromString(String value) {
    switch (value) {
      case 'tarea':     return SuggestionType.task;
      case 'categoria': return SuggestionType.category;
      default:          return SuggestionType.task;
    }
  }

  String get label {
    switch (this) {
      case SuggestionType.task:     return 'Tarea';
      case SuggestionType.category: return 'Categoría';
    }
  }

  // Valor que espera el backend al crear una sugerencia
  String get value {
    switch (this) {
      case SuggestionType.task:     return 'tarea';
      case SuggestionType.category: return 'categoria';
    }
  }
}

// ── Estado de la sugerencia ──────────────────────────────────────────────────

enum SuggestionStatus {
  pending,
  approved,
  rejected;

  static SuggestionStatus fromString(String value) {
    switch (value) {
      case 'pendiente': return SuggestionStatus.pending;
      case 'aprobada':  return SuggestionStatus.approved;
      case 'rechazada': return SuggestionStatus.rejected;
      default:          return SuggestionStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case SuggestionStatus.pending:  return 'Pendiente';
      case SuggestionStatus.approved: return 'Aprobada';
      case SuggestionStatus.rejected: return 'Rechazada';
    }
  }
}