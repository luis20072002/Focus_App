import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _todayTasks    = [];
  List<Task> _calendarTasks = [];
  bool       _loading       = false;
  bool       _loadingAll    = false;
  String?    _error;

  List<Task> get todayTasks    => _todayTasks;
  List<Task> get calendarTasks => _calendarTasks;
  bool       get loading       => _loading;
  bool       get loadingAll    => _loadingAll;
  String?    get error         => _error;

  // ── Helpers de calendario ─────────────────────────────────────────────────

  Map<String, List<Task>> get tasksByDate {
    final map = <String, List<Task>>{};
    for (final task in _calendarTasks) {
      try {
        final dt  = DateTime.parse(task.scheduledDate);
        final key = '${dt.year}-${dt.month}-${dt.day}';
        map.putIfAbsent(key, () => []).add(task);
      } catch (_) {}
    }
    return map;
  }

  Set<int> completedDaysInMonth(int year, int month) {
    final byDay = <int, List<Task>>{};
    for (final task in _calendarTasks) {
      try {
        final dt = DateTime.parse(task.scheduledDate);
        if (dt.year == year && dt.month == month) {
          byDay.putIfAbsent(dt.day, () => []).add(task);
        }
      } catch (_) {}
    }
    final result = <int>{};
    byDay.forEach((day, tasks) {
      final past    = tasks.every((t) => DateTime.parse(t.scheduledDate).isBefore(DateTime.now()));
      final allDone = tasks.every((t) => t.isDone);
      if (past && allDone) result.add(day);
    });
    return result;
  }

  Set<int> failedDaysInMonth(int year, int month) {
    final byDay = <int, List<Task>>{};
    for (final task in _calendarTasks) {
      try {
        final dt = DateTime.parse(task.scheduledDate);
        if (dt.year == year && dt.month == month) {
          byDay.putIfAbsent(dt.day, () => []).add(task);
        }
      } catch (_) {}
    }
    final result = <int>{};
    byDay.forEach((day, tasks) {
      final hasExpired = tasks.any((t) => t.isExpired);
      final notAllDone = !tasks.every((t) => t.isDone);
      if (hasExpired || notAllDone) {
        final allPast = tasks.every(
          (t) => DateTime.parse(t.scheduledDate).isBefore(DateTime.now()),
        );
        if (allPast) result.add(day);
      }
    });
    return result..removeAll(completedDaysInMonth(year, month));
  }

  Set<int> scheduledDaysInMonth(int year, int month) {
    final now    = DateTime.now();
    final result = <int>{};
    for (final task in _calendarTasks) {
      try {
        final dt = DateTime.parse(task.scheduledDate);
        if (dt.year == year && dt.month == month && dt.isAfter(now)) {
          result.add(dt.day);
        }
      } catch (_) {}
    }
    return result;
  }

  List<Map<String, dynamic>> tasksForDay(int year, int month, int day) {
    final key   = '$year-$month-$day';
    final tasks = tasksByDate[key] ?? [];
    return tasks.map((t) {
      DateTime dt;
      try {
        dt = DateTime.parse(t.scheduledDate);
      } catch (_) {
        dt = DateTime.now();
      }
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');

      final int color;
      if (t.isDone) {
        color = AppColors.blueberry.value;
      } else if (t.isExpired) {
        color = AppColors.error.value;
      } else {
        color = AppColors.lightBlue.value;
      }

      return {
        'name':   t.name,
        'time':   '$h:$m',
        'done':   t.isDone,
        'foints': t.showFointsBadge,
        'color':  color,
      };
    }).toList();
  }

  // ── Carga de tareas ───────────────────────────────────────────────────────

  Future<void> loadTodayTasks() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      _todayTasks = await TaskService.getTodayTasks();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadCalendarTasks({required int year, required int month}) async {
    _loadingAll = true;
    _error      = null;
    notifyListeners();
    try {
      _calendarTasks = await TaskService.getCalendarTasks(
        year: year, month: month,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loadingAll = false;
    notifyListeners();
  }

  // ── Crear tarea ───────────────────────────────────────────────────────────

  Future<bool> createTask({
    required String name,
    String? description,
    required bool isUrgent,
    required String scheduledDate,
    required String notificationType,
    required bool isFointCandidate,
    bool isRecurrent = false,
    String recurrenceType = 'ninguna',
    String? recurrenceDays,
    String? recurrenceEndDate,
    int? idTaskTemplate,
  }) async {
    _error = null;
    try {
      final newTask = await TaskService.createTask(
        name:              name,
        description:       description,
        isUrgent:          isUrgent,
        scheduledDate:     scheduledDate,
        notificationType:  notificationType,
        isFointCandidate:  isFointCandidate,
        isRecurrent:       isRecurrent,
        recurrenceType:    recurrenceType,
        recurrenceDays:    recurrenceDays,
        recurrenceEndDate: recurrenceEndDate,
        idTaskTemplate:    idTaskTemplate,
      );
      _todayTasks.add(newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Editar tarea ──────────────────────────────────────────────────────────

  Future<bool> updateTask(int taskId, Map<String, dynamic> fields) async {
    _error = null;
    try {
      final updated = await TaskService.updateTask(taskId, fields);
      _updateTaskInLists(taskId, updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Marcar como realizada ─────────────────────────────────────────────────

  Future<bool> markAsDone(int taskId) async {
    _error = null;
    try {
      final updated = await TaskService.completeTask(taskId);
      _updateTaskInLists(taskId, updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Eliminar tarea ────────────────────────────────────────────────────────

  Future<bool> deleteTask(int taskId) async {
    _error = null;
    try {
      await TaskService.deleteTask(taskId);
      _todayTasks.removeWhere((t) => t.idTask == taskId);
      _calendarTasks.removeWhere((t) => t.idTask == taskId);
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
    _todayTasks    = [];
    _calendarTasks = [];
    _error         = null;
    notifyListeners();
  }

  // ── Utilidad interna ──────────────────────────────────────────────────────

  void _updateTaskInLists(int taskId, Task updated) {
    final todayIdx = _todayTasks.indexWhere((t) => t.idTask == taskId);
    if (todayIdx != -1) {
      _todayTasks[todayIdx] = updated;
    }

    final calIdx = _calendarTasks.indexWhere((t) => t.idTask == taskId);
    if (calIdx != -1) {
      _calendarTasks[calIdx] = updated;
    }
  }
}