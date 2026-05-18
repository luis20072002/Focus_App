import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/users.dart';

class FollowService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── POST /follows — Seguir a un usuario ───────────────────────────────────
  // El backend notifica automáticamente al usuario seguido.
  static Future<void> followUser(int idFollowed) async {
    final response = await http.post(
      Uri.parse(ApiConstants.follows),
      headers: await _headers(),
      body: jsonEncode({'id_followed': idFollowed}),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al seguir al usuario');
    }
  }

  // ── DELETE /follows/{id_followed} — Dejar de seguir ──────────────────────
  static Future<void> unfollowUser(int idFollowed) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.unfollowById(idFollowed)),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al dejar de seguir al usuario');
    }
  }

  // ── DELETE /follows/followers/{id_follower} — Eliminar un seguidor ────────
  static Future<void> removeFollower(int idFollower) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.removeFollowerById(idFollower)),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al eliminar el seguidor');
    }
  }

  // ── GET /follows/followers — Mis seguidores ───────────────────────────────
  static Future<List<User>> getFollowers({
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(ApiConstants.followers).replace(
      queryParameters: {
        'limit':  '$limit',
        'offset': '$offset',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener los seguidores');
    }
  }

  // ── GET /follows/following — A quiénes sigo ───────────────────────────────
  static Future<List<User>> getFollowing({
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(ApiConstants.following).replace(
      queryParameters: {
        'limit':  '$limit',
        'offset': '$offset',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener los seguidos');
    }
  }

  // ── GET /follows/friends — Amigos mutuos ──────────────────────────────────
  static Future<List<User>> getFriends({
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(ApiConstants.friends).replace(
      queryParameters: {
        'limit':  '$limit',
        'offset': '$offset',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener los amigos');
    }
  }
}