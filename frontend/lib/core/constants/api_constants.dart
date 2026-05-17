import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';

  // ── Auth ────────────────────────────────────────────────────────────────
  static String get login    => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me       => '$baseUrl/auth/me';
  static String get logout   => '$baseUrl/auth/logout';

  // Recuperación de contraseña (3 pasos)
  static String get recoveryRequest => '$baseUrl/auth/password-recovery/request';
  static String get recoveryVerify  => '$baseUrl/auth/password-recovery/verify';
  static String get recoveryConfirm => '$baseUrl/auth/password-recovery/confirm';

  // ── Usuarios ─────────────────────────────────────────────────────────────
  static String get usersMe     => '$baseUrl/users/me';
  static String get usersSearch => '$baseUrl/users/search';
  static String userByUsername(String username) => '$baseUrl/users/$username';

  // ── Tareas ────────────────────────────────────────────────────────────────
  // GET /tasks         → tareas del día actual
  // GET /tasks/calendar?year=&month= → vista calendario
  // POST /tasks        → crear tarea
  // PATCH /tasks/{id}  → editar tarea
  // DELETE /tasks/{id} → eliminar tarea
  // POST /tasks/{id}/complete → marcar como realizada (acredita Foints)
  static String get tasks         => '$baseUrl/tasks';
  static String get tasksCalendar => '$baseUrl/tasks/calendar';
  static String taskById(int id)       => '$baseUrl/tasks/$id';
  static String taskComplete(int id)   => '$baseUrl/tasks/$id/complete';

  // ── Plantillas y categorías ───────────────────────────────────────────────
  static String get templates  => '$baseUrl/templates';
  static String get categories => '$baseUrl/categories';
  static String templateById(int id) => '$baseUrl/templates/$id';

  // ── Ranking ───────────────────────────────────────────────────────────────
  static String get rankingGlobal  => '$baseUrl/ranking/global';
  static String get rankingFriends => '$baseUrl/ranking/friends';
  static String get rankingMe      => '$baseUrl/ranking/me';

  // ── Seguimiento ───────────────────────────────────────────────────────────
  static String get follows   => '$baseUrl/follows';
  static String get followers => '$baseUrl/follows/followers';
  static String get following => '$baseUrl/follows/following';
  static String get friends   => '$baseUrl/follows/friends';
  static String unfollowById(int id)       => '$baseUrl/follows/$id';
  static String removeFollowerById(int id) => '$baseUrl/follows/followers/$id';

  // ── Notificaciones ────────────────────────────────────────────────────────
  static String get notifications => '$baseUrl/notifications';
  static String get deviceToken   => '$baseUrl/notifications/device-token';
  static String notificationById(int id) => '$baseUrl/notifications/$id';
  static String notificationRead(int id) => '$baseUrl/notifications/$id/read';
  static String get notificationsReadAll => '$baseUrl/notifications/read-all';

  // ── Configuración ─────────────────────────────────────────────────────────
  static String get settings => '$baseUrl/settings';

  // ── Sugerencias ───────────────────────────────────────────────────────────
  static String get suggestions     => '$baseUrl/suggestions';
  static String get suggestionsMine => '$baseUrl/suggestions/mine';
  static String suggestionById(int id) => '$baseUrl/suggestions/$id';
}