import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  UserSettings? _settings;
  bool    _loading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────
  UserSettings? get settings => _settings;
  bool    get loading        => _loading;
  String? get error          => _error;

  // Shortcut para que los widgets de tema no tengan que navegar hasta settings
  bool get isDarkTheme => _settings?.isDarkTheme ?? false;

  // ── GET /settings — Cargar configuración ─────────────────────────────────
  Future<void> loadSettings() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      _settings = await SettingsService.getSettings();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  // ── PATCH /settings — Actualizar uno o varios campos ─────────────────────
  // Recibe solo los campos que cambian. Actualiza el estado local
  // optimistamente con copyWith antes de confirmar con el servidor,
  // y revierte si falla.
  Future<bool> updateSettings(Map<String, dynamic> fields) async {
    if (_settings == null) return false;

    // Snapshot para revertir si el servidor falla
    final previous = _settings;

    // Actualización optimista local
    _settings = _applyFields(_settings!, fields);
    _error    = null;
    notifyListeners();

    try {
      _settings = await SettingsService.updateSettings(fields);
      notifyListeners();
      return true;
    } catch (e) {
      // Revertir al estado anterior
      _settings = previous;
      _error    = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Shortcuts para casos de uso frecuentes desde la UI ─────────────────────

  // Cambiar tema claro / oscuro (RF-F25)
  Future<bool> setTheme(String theme) =>
      updateSettings({'theme': theme});

  // Guardar propósito de uso al completar el tutorial (RF-F04)
  Future<bool> setAppPurpose(String purpose) =>
      updateSettings({'app_purpose': purpose});

  // Activar / desactivar notificaciones push globalmente (RF-F23)
  Future<bool> setNotifPush(bool value) =>
      updateSettings({'notif_push': value});

  // Cambiar minutos de anticipación del recordatorio (RF-F23)
  Future<bool> setReminderMinutes(int minutes) =>
      updateSettings({'notif_reminder_minutes': minutes});

  // ── Limpia el estado (cerrar sesión) ──────────────────────────────────────
  void clear() {
    _settings = null;
    _error    = null;
    notifyListeners();
  }

  // ── Utilidad interna ──────────────────────────────────────────────────────
  // Aplica un Map de campos parciales sobre el objeto actual usando copyWith,
  // evitando tener que pasar todos los campos en cada llamada.
  UserSettings _applyFields(UserSettings current, Map<String, dynamic> fields) {
    return current.copyWith(
      notifPush:               fields['notif_push']               as bool?,
      notifTaskReminder:       fields['notif_task_reminder']       as bool?,
      notifTaskExpired:        fields['notif_task_expired']        as bool?,
      notifUrgentTask:         fields['notif_urgent_task']         as bool?,
      notifNewFollower:        fields['notif_new_follower']        as bool?,
      notifSuggestionResolved: fields['notif_suggestion_resolved'] as bool?,
      notifReminderMinutes:    fields['notif_reminder_minutes']    as int?,
      theme:                   fields['theme']                     as String?,
      language:                fields['language']                  as String?,
      appPurpose:              fields['app_purpose']               as String?,
      referredByFriend:        fields['referred_by_friend']        as bool?,
    );
  }
}