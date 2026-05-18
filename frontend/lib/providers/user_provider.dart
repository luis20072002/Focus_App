import 'package:flutter/material.dart';
import '../models/users.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  User?   _user;
  bool    _loading       = false;
  bool    _loadingSearch = false;
  String? _error;

  List<User> _searchResults = [];

  // ── Getters ──────────────────────────────────────────────────────────────
  User?      get user          => _user;
  bool       get loading       => _loading;
  bool       get loadingSearch => _loadingSearch;
  String?    get error         => _error;
  List<User> get searchResults => _searchResults;

  // ── GET /users/me — Cargar perfil propio ─────────────────────────────────
  Future<void> loadMe() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      _user = await UserService.getMe();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  // ── PATCH /users/me — Editar perfil ──────────────────────────────────────
  // Devuelve true si se actualizó correctamente.
  // Solo envía los campos que cambian (Map parcial).
  Future<bool> updateMe(Map<String, dynamic> fields) async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      _user = await UserService.updateMe(fields);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── GET /users/search — Buscar usuarios ──────────────────────────────────
  Future<void> searchUsers(String query, {int limit = 20, int offset = 0}) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _loadingSearch = true;
    _error         = null;
    notifyListeners();
    try {
      _searchResults = await UserService.searchUsers(
        query,
        limit:  limit,
        offset: offset,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loadingSearch = false;
    notifyListeners();
  }

  // Limpia los resultados de búsqueda sin disparar una petición
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // ── GET /users/{username} — Perfil público ────────────────────────────────
  // Retorna el User directamente en lugar de guardarlo en estado global,
  // porque es datos de otro usuario, no del propio.
  Future<User?> getPublicProfile(String username) async {
    _error = null;
    try {
      return await UserService.getUserByUsername(username);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── DELETE /users/me — Eliminar cuenta ───────────────────────────────────
  // El backend elimina todos los datos en cascada.
  // Después de llamar esto, la pantalla debe cerrar sesión y limpiar el token.
  Future<bool> deleteAccount() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      await UserService.deleteAccount();
      _user    = null;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Limpia el estado (cerrar sesión) ──────────────────────────────────────
  void clear() {
    _user          = null;
    _searchResults = [];
    _error         = null;
    notifyListeners();
  }
}