import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/notification_model.dart';

class NotificationService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── POST /notifications/device-token — Registrar token FCM ───────────────
  // Llamar al hacer login y cuando Firebase genere un nuevo token.
  // platform: 'android' o 'ios'
  static Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.deviceToken),
      headers: await _headers(),
      body: jsonEncode({
        'token':    token,
        'platform': platform,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al registrar el token de dispositivo');
    }
  }

  // ── DELETE /notifications/device-token?token= — Eliminar token FCM ───────
  // Llamar siempre al cerrar sesión para dejar de recibir push.
  static Future<void> unregisterDeviceToken(String token) async {
    final uri = Uri.parse(ApiConstants.deviceToken).replace(
      queryParameters: {'token': token},
    );

    final response = await http.delete(uri, headers: await _headers());

    // 404 significa que el token ya no existía — no es un error crítico
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw Exception('Error al eliminar el token de dispositivo');
    }
  }

  // ── GET /notifications — Listar notificaciones ────────────────────────────
  static Future<List<NotificationModel>> getNotifications({
    bool soloNoLeidas = false,
    int limit = 30,
    int offset = 0,
  }) async {
    final uri = Uri.parse(ApiConstants.notifications).replace(
      queryParameters: {
        'solo_no_leidas': '$soloNoLeidas',
        'limit':          '$limit',
        'offset':         '$offset',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las notificaciones');
    }
  }

  // ── PATCH /notifications/{id}/read — Marcar una como leída ───────────────
  static Future<NotificationModel> markAsRead(int idNotification) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.notificationRead(idNotification)),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return NotificationModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al marcar la notificación como leída');
    }
  }

  // ── PATCH /notifications/read-all — Marcar todas como leídas ─────────────
  static Future<void> markAllAsRead() async {
    final response = await http.patch(
      Uri.parse(ApiConstants.notificationsReadAll),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al marcar las notificaciones como leídas');
    }
  }

  // ── DELETE /notifications/{id} — Eliminar notificación ───────────────────
  static Future<void> deleteNotification(int idNotification) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.notificationById(idNotification)),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al eliminar la notificación');
    }
  }
}