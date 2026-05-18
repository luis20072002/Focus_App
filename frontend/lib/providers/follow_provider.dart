import 'package:flutter/material.dart';
import '../models/users.dart';
import '../services/follow_service.dart';

class FollowProvider extends ChangeNotifier {
  List<User> _followers = [];
  List<User> _following = [];
  List<User> _friends   = [];

  bool    _loadingFollowers = false;
  bool    _loadingFollowing = false;
  bool    _loadingFriends   = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<User> get followers => _followers;
  List<User> get following => _following;
  List<User> get friends   => _friends;

  bool get loadingFollowers => _loadingFollowers;
  bool get loadingFollowing => _loadingFollowing;
  bool get loadingFriends   => _loadingFriends;
  bool get loading          => _loadingFollowers || _loadingFollowing || _loadingFriends;

  String? get error => _error;

  // Helpers útiles para la UI
  bool isFollowing(int idUser) => _following.any((u) => u.idUser == idUser);
  bool isFriend(int idUser)    => _friends.any((u) => u.idUser == idUser);

  // ── GET /follows/followers — Mis seguidores ───────────────────────────────
  Future<void> loadFollowers({int limit = 50, int offset = 0}) async {
    _loadingFollowers = true;
    _error            = null;
    notifyListeners();
    try {
      _followers = await FollowService.getFollowers(limit: limit, offset: offset);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loadingFollowers = false;
    notifyListeners();
  }

  // ── GET /follows/following — A quiénes sigo ───────────────────────────────
  Future<void> loadFollowing({int limit = 50, int offset = 0}) async {
    _loadingFollowing = true;
    _error            = null;
    notifyListeners();
    try {
      _following = await FollowService.getFollowing(limit: limit, offset: offset);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loadingFollowing = false;
    notifyListeners();
  }

  // ── GET /follows/friends — Amigos mutuos ─────────────────────────────────
  Future<void> loadFriends({int limit = 50, int offset = 0}) async {
    _loadingFriends = true;
    _error          = null;
    notifyListeners();
    try {
      _friends = await FollowService.getFriends(limit: limit, offset: offset);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loadingFriends = false;
    notifyListeners();
  }

  // Carga las tres listas a la vez — útil al entrar a la pantalla de perfil
  Future<void> loadAll() async {
    await Future.wait([
      loadFollowers(),
      loadFollowing(),
      loadFriends(),
    ]);
  }

  // ── POST /follows — Seguir a un usuario ───────────────────────────────────
  // El backend notifica automáticamente al usuario seguido.
  // Devuelve true si la operación fue exitosa.
  Future<bool> followUser(int idFollowed) async {
    _error = null;
    try {
      await FollowService.followUser(idFollowed);
      // Recarga following y friends para reflejar el nuevo estado
      await Future.wait([loadFollowing(), loadFriends()]);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── DELETE /follows/{id_followed} — Dejar de seguir ──────────────────────
  // Si eran amigos, el backend rompe la amistad automáticamente.
  Future<bool> unfollowUser(int idFollowed) async {
    _error = null;
    try {
      await FollowService.unfollowUser(idFollowed);
      _following.removeWhere((u) => u.idUser == idFollowed);
      _friends.removeWhere((u) => u.idUser == idFollowed);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── DELETE /follows/followers/{id_follower} — Eliminar un seguidor ────────
  // Fuerza que alguien deje de seguir al usuario autenticado (RF-F12).
  Future<bool> removeFollower(int idFollower) async {
    _error = null;
    try {
      await FollowService.removeFollower(idFollower);
      _followers.removeWhere((u) => u.idUser == idFollower);
      _friends.removeWhere((u) => u.idUser == idFollower);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Limpia el estado (cerrar sesión) ──────────────────────────────────────
  void clear() {
    _followers = [];
    _following = [];
    _friends   = [];
    _error     = null;
    notifyListeners();
  }
}