import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/user_settings.dart';

class SettingsService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── GET /settings — Ver configuración ─────────────────────────────────────
  static Future<UserSettings> getSettings() async {
    final response = await http.get(
      Uri.parse(ApiConstants.settings),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return UserSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener la configuración');
    }
  }

  // ── PATCH /settings — Actualizar configuración ────────────────────────────
  // Solo envía los campos que cambian (edición parcial).
  // Usar UserSettings.toJson() o construir el Map manualmente con
  // solo los campos modificados para no sobreescribir todo.
  static Future<UserSettings> updateSettings(Map<String, dynamic> fields) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.settings),
      headers: await _headers(),
      body: jsonEncode(fields),
    );

    if (response.statusCode == 200) {
      return UserSettings.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al actualizar la configuración');
    }
  }
}