import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool    _loading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<NotificationModel> get notifications => _notifications;
  bool    get loading => _loading;
  String? get error   => _error;

  // Cantidad de notificaciones no leídas — para el badge en la UI
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get hasUnread  => unreadCount > 0;

  // ── GET /notifications — Cargar notificaciones ────────────────────────────
  // soloNoLeidas: si true solo trae las pendientes de leer.
  // Para la pantalla principal se recomienda false para mostrar el historial.
  Future<void> loadNotifications({
    bool soloNoLeidas = false,
    int  limit        = 30,
    int  offset       = 0,
  }) async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      final fetched = await NotificationService.getNotifications(
        soloNoLeidas: soloNoLeidas,
        limit:        limit,
        offset:       offset,
      );
      // Si es la primera página reemplaza la lista; si es paginación agrega
      if (offset == 0) {
        _notifications = fetched;
      } else {
        _notifications = [..._notifications, ...fetched];
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  // ── PATCH /notifications/{id}/read — Marcar una como leída ───────────────
  Future<bool> markAsRead(int idNotification) async {
    _error = null;
    try {
      final updated = await NotificationService.markAsRead(idNotification);
      _replaceInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── PATCH /notifications/read-all — Marcar todas como leídas ─────────────
  Future<bool> markAllAsRead() async {
    _error = null;

    // Actualización optimista: marca todas localmente de inmediato
    _notifications = _notifications
        .map((n) => n.copyWithRead(true))
        .toList();
    notifyListeners();

    try {
      await NotificationService.markAllAsRead();
      return true;
    } catch (e) {
      // Recargar desde el servidor si falla para no dejar estado inconsistente
      _error = e.toString().replaceFirst('Exception: ', '');
      await loadNotifications();
      return false;
    }
  }

  // ── DELETE /notifications/{id} — Eliminar notificación ───────────────────
  Future<bool> deleteNotification(int idNotification) async {
    _error = null;

    // Guarda snapshot para revertir si falla
    final previous = List<NotificationModel>.from(_notifications);
    _notifications.removeWhere((n) => n.idNotification == idNotification);
    notifyListeners();

    try {
      await NotificationService.deleteNotification(idNotification);
      return true;
    } catch (e) {
      _notifications = previous;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Registrar token FCM — llamar después de cada login ───────────────────
  // El provider lo delega al service directamente; no hay estado que guardar.
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    _error = null;
    try {
      await NotificationService.registerDeviceToken(
        token:    token,
        platform: platform,
      );
    } catch (e) {
      // No es crítico — solo se registra el error sin bloquear el flujo
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ── Eliminar token FCM — llamar antes de cerrar sesión ───────────────────
  Future<void> unregisterDeviceToken(String token) async {
    _error = null;
    try {
      await NotificationService.unregisterDeviceToken(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ── Limpia el estado (cerrar sesión) ──────────────────────────────────────
  void clear() {
    _notifications = [];
    _error         = null;
    notifyListeners();
  }

  // ── Utilidad interna ──────────────────────────────────────────────────────
  void _replaceInList(NotificationModel updated) {
    final idx = _notifications.indexWhere(
      (n) => n.idNotification == updated.idNotification,
    );
    if (idx != -1) {
      _notifications[idx] = updated;
    }
  }
}