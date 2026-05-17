import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/ranking_entry.dart';

class RankingService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── GET /ranking/global ─────────────────────────────────────────────────
  // Devuelve el ranking global paginado.
  // limit: cuántos traer, offset: desde cuál (para paginación futura).
  static Future<List<RankingEntry>> getGlobalRanking({
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(ApiConstants.rankingGlobal).replace(
      queryParameters: {
        'limit':  '$limit',
        'offset': '$offset',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RankingEntry.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener el ranking global');
    }
  }

  // ── GET /ranking/friends ────────────────────────────────────────────────
  // Devuelve el ranking entre amigos del usuario autenticado.
  // El backend incluye al propio usuario en la lista.
  static Future<List<RankingEntry>> getFriendsRanking() async {
    final response = await http.get(
      Uri.parse(ApiConstants.rankingFriends),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RankingEntry.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener el ranking de amigos');
    }
  }

  // ── GET /ranking/me ─────────────────────────────────────────────────────
  // Devuelve la posición global del usuario autenticado.
  // Lanza Exception con código 404 si foints_season == 0
  // (el usuario aún no tiene posición en el ranking).
  static Future<RankingEntry?> getMyPosition() async {
    final response = await http.get(
      Uri.parse(ApiConstants.rankingMe),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return RankingEntry.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      // Sin posición todavía — no es un error, el provider lo maneja
      return null;
    } else {
      throw Exception('Error al obtener tu posición en el ranking');
    }
  }
}