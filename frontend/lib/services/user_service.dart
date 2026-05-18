import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/users.dart';

class UserService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── GET /users/me — Mi perfil completo ────────────────────────────────────
  static Future<User> getMe() async {
    final response = await http.get(
      Uri.parse(ApiConstants.usersMe),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener el perfil');
    }
  }

  // ── PATCH /users/me — Editar perfil ──────────────────────────────────────
  // Solo envía los campos que cambian (edición parcial).
  // Campos editables: name, lastname, username, email, phone, description.
  static Future<User> updateMe(Map<String, dynamic> fields) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.usersMe),
      headers: await _headers(),
      body: jsonEncode(fields),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al actualizar el perfil');
    }
  }

  // ── GET /users/search?q= — Buscar usuarios ────────────────────────────────
  // Búsqueda por username, nombre o apellido (case-insensitive, parcial).
  // Excluye al propio usuario de los resultados.
  static Future<List<User>> searchUsers(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse(ApiConstants.usersSearch).replace(
      queryParameters: {
        'q':      query,
        'limit':  '$limit',
        'offset': '$offset',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Error al buscar usuarios');
    }
  }

  // ── GET /users/{username} — Perfil público de otro usuario ───────────────
  static Future<User> getUserByUsername(String username) async {
    final response = await http.get(
      Uri.parse(ApiConstants.userByUsername(username)),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    } else {
      throw Exception('Error al obtener el perfil');
    }
  }

  // ── DELETE /users/me — Eliminar cuenta ───────────────────────────────────
  // El backend elimina todos los datos del usuario en cascada.
  // El frontend debe cerrar sesión y limpiar el token después de llamar esto.
  static Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse(ApiConstants.usersMe),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al eliminar la cuenta');
    }
  }
}