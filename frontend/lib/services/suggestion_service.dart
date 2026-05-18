import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/suggestion.dart';

class SuggestionService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── POST /suggestions — Enviar sugerencia ─────────────────────────────────
  // type: SuggestionType.task o SuggestionType.category
  // El backend limita a 3 sugerencias pendientes simultáneas por usuario.
  static Future<Suggestion> createSuggestion({
    required SuggestionType type,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.suggestions),
      headers: await _headers(),
      body: jsonEncode({
        'type':    type.value,
        'content': content.trim(),
      }),
    );

    if (response.statusCode == 201) {
      return Suggestion.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al enviar la sugerencia');
    }
  }

  // ── GET /suggestions/mine — Mis sugerencias ───────────────────────────────
  // statusFilter: 'pendiente', 'aprobada', 'rechazada' o null para todas.
  static Future<List<Suggestion>> getMySuggestions({
    SuggestionStatus? statusFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit':  '$limit',
      'offset': '$offset',
    };
    if (statusFilter != null) params['status'] = statusFilter.label.toLowerCase();

    final uri = Uri.parse(ApiConstants.suggestionsMine).replace(
      queryParameters: params,
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Suggestion.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las sugerencias');
    }
  }

  // ── DELETE /suggestions/{id} — Eliminar sugerencia propia ────────────────
  // Solo se pueden eliminar sugerencias en estado pendiente.
  static Future<void> deleteSuggestion(int idSuggestion) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.suggestionById(idSuggestion)),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al eliminar la sugerencia');
    }
  }
}