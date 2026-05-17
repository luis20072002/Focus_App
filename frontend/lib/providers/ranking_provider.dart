import 'package:flutter/material.dart';
import '../models/ranking_entry.dart';
import '../services/ranking_service.dart';

class RankingProvider extends ChangeNotifier {
  List<RankingEntry> _globalRanking  = [];
  List<RankingEntry> _friendsRanking = [];
  RankingEntry?      _myPosition;

  bool _loadingGlobal  = false;
  bool _loadingFriends = false;
  bool _loadingMe      = false;

  String? _error;

  // ── Getters ─────────────────────────────────────────────────────────────
  List<RankingEntry> get globalRanking  => _globalRanking;
  List<RankingEntry> get friendsRanking => _friendsRanking;
  RankingEntry?      get myPosition     => _myPosition;

  bool get loadingGlobal  => _loadingGlobal;
  bool get loadingFriends => _loadingFriends;
  bool get loadingMe      => _loadingMe;
  bool get loading        => _loadingGlobal || _loadingFriends;

  String? get error => _error;

  // true cuando el usuario aún no tiene posición (foints_season == 0)
  bool get hasNoPosition => !_loadingMe && _myPosition == null;

  // ── Carga global ─────────────────────────────────────────────────────────
  Future<void> loadGlobalRanking({int limit = 50}) async {
    _loadingGlobal = true;
    _error = null;
    notifyListeners();

    try {
      _globalRanking = await RankingService.getGlobalRanking(limit: limit);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loadingGlobal = false;
    notifyListeners();
  }

  // ── Carga amigos ─────────────────────────────────────────────────────────
  Future<void> loadFriendsRanking() async {
    _loadingFriends = true;
    _error = null;
    notifyListeners();

    try {
      _friendsRanking = await RankingService.getFriendsRanking();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loadingFriends = false;
    notifyListeners();
  }

  // ── Carga posición propia ────────────────────────────────────────────────
  Future<void> loadMyPosition() async {
    _loadingMe = true;
    _error = null;
    notifyListeners();

    try {
      // Devuelve null si foints_season == 0 — no es un error
      _myPosition = await RankingService.getMyPosition();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loadingMe = false;
    notifyListeners();
  }

  // ── Carga todo de una vez (usado al entrar al home) ──────────────────────
  Future<void> loadAll() async {
    await Future.wait([
      loadGlobalRanking(),
      loadFriendsRanking(),
      loadMyPosition(),
    ]);
  }

  // ── Limpia el estado (usado al cerrar sesión) ────────────────────────────
  void clear() {
    _globalRanking  = [];
    _friendsRanking = [];
    _myPosition     = null;
    _error          = null;
    notifyListeners();
  }
}