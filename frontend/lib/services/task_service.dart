import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/task.dart';

class TaskService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── GET /tasks — Tareas del día actual ────────────────────────────────────
  // FIX: eliminado tasksToday (/tasks/today no existe en el backend).
  // El endpoint correcto es GET /tasks sin sufijo.
  static Future<List<Task>> getTodayTasks() async {
    final response = await http.get(
      Uri.parse(ApiConstants.tasks),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las tareas del día');
    }
  }

  // ── GET /tasks/calendar — Todas las tareas de un mes ─────────────────────
  // FIX: reemplaza getAllTasks() que llamaba a /tasks/ y solo devolvía
  // las tareas de hoy. Este endpoint devuelve todas las del mes indicado,
  // incluyendo instancias virtuales de tareas recurrentes.
  static Future<List<Task>> getCalendarTasks({
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(ApiConstants.tasksCalendar).replace(
      queryParameters: {
        'year':  '$year',
        'month': '$month',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las tareas del calendario');
    }
  }

  // ── POST /tasks — Crear tarea ─────────────────────────────────────────────
  // FIX: agregado isFointCandidate al payload.
  // El backend lo requiere para activar el sistema de Foints.
  static Future<Task> createTask({
    required String name,
    String? description,
    required bool isUrgent,
    required String scheduledDate,
    required String notificationType,
    required bool isFointCandidate,
    bool isRecurrent = false,
    String recurrenceType = 'ninguna',
    String? recurrenceDays,
    String? recurrenceEndDate,
    int? idTaskTemplate,
  }) async {
    final body = {
      'name':                name,
      'description':         description,
      'is_urgent':           isUrgent,
      'scheduled_date':      scheduledDate,
      'notification_type':   notificationType,
      'is_foint_candidate':  isFointCandidate,
      'is_recurrent':        isRecurrent,
      'recurrence_type':     recurrenceType,
      'recurrence_days':     recurrenceDays,
      'recurrence_end_date': recurrenceEndDate,
      'id_task_template':    idTaskTemplate,
    };

    final response = await http.post(
      Uri.parse(ApiConstants.tasks),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al crear la tarea');
    }
  }

  // ── PATCH /tasks/{id} — Editar tarea ─────────────────────────────────────
  // Solo envía los campos que cambian (edición parcial).
  static Future<Task> updateTask(int taskId, Map<String, dynamic> fields) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.taskById(taskId)),
      headers: await _headers(),
      body: jsonEncode(fields),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al editar la tarea');
    }
  }

  // ── POST /tasks/{id}/complete — Marcar como realizada ────────────────────
  // FIX: reemplaza updateTaskStatus() que usaba PUT /tasks/{id} con
  // {status: 'realizada'}, endpoint incorrecto que nunca acreditaba Foints.
  // Este es el único endpoint que activa el algoritmo de Foints en el backend.
  static Future<Task> completeTask(int taskId) async {
    final response = await http.post(
      Uri.parse(ApiConstants.taskComplete(taskId)),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al completar la tarea');
    }
  }

  // ── DELETE /tasks/{id} — Eliminar tarea ──────────────────────────────────
  // FIX: el backend devuelve 204 No Content al eliminar correctamente,
  // no 200. Se corrige la validación del status code.
  static Future<void> deleteTask(int taskId) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.taskById(taskId)),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al eliminar la tarea');
    }
  }
}