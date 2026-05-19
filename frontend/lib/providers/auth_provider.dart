import 'package:flutter/material.dart';
import '../models/users.dart';
import '../services/auth_service.dart';
import '../core/utils/token_storage.dart';


enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User?      get user   => _user;
  String?    get error  => _error;

  // Se llama al abrir la app para ver si habia sesion activa
  Future<void> checkAuth() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user   = await AuthService.getMe(token);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await TokenStorage.deleteToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _error = null;
    try {
      final token = await AuthService.login(identifier, password);
      await TokenStorage.saveToken(token);
      _user   = await AuthService.getMe(token);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String lastname,
    required String username,
    required String password,
    String? email,
    String? phone,
    required String birthDate,
  }) async {
    _error = null;
    try {
      await AuthService.register(
        name:      name,
        lastname:  lastname,
        username:  username,
        password:  password,
        email:     email,
        phone:     phone,
        birthDate: birthDate,
      );
      // Despues del registro hace login automaticamente
      return await login(email ?? username, password);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}