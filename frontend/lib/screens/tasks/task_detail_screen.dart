import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

class TaskDetailScreen extends StatelessWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  // ── Busca la tarea en todayTasks y calendarTasks ──────────────────────────
  Task? _findTask(TaskProvider prov) {
    final inToday = prov.todayTasks.where((t) => t.idTask == taskId);
    if (inToday.isNotEmpty) return inToday.first;
    final inCalendar = prov.calendarTasks.where((t) => t.idTask == taskId);
    if (inCalendar.isNotEmpty) return inCalendar.first;
    return null;
  }

  // ── Color segun estado ────────────────────────────────────────────────────
  Color _statusColor(Task task) {
    if (task.isDone)    return const Color(0xFF34C759);
    if (task.isExpired) return AppColors.error;
    if (task.isUrgent)  return AppColors.gum;
    return AppColors.blueberry;
  }

  // ── Etiqueta legible del estado ───────────────────────────────────────────
  String _statusLabel(Task task) {
    if (task.isDone)    return 'Realizada';
    if (task.isExpired) return 'Vencida';
    if (task.isUrgent)  return 'Urgente';
    return 'Pendiente';
  }

  // ── Formato de fecha ──────────────────────────────────────────────────────
  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${meses[dt.month - 1]} ${dt.year}  $h:$m';
    } catch (_) {
      return iso;
    }
  }

  // ── Dialogo de confirmacion ───────────────────────────────────────────────
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Eliminar tarea',
              style: TextStyle(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Esta accion no se puede deshacer.',
              style: TextStyle(color: AppColors.grisTexto),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(
                    color:      AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final task     = _findTask(taskProv);
    final colors   = Theme.of(context).colorScheme;

    // ── Tarea no encontrada ───────────────────────────────────────────────
    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size:  56,
                color: AppColors.grisTexto.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tarea no encontrada',
                style: TextStyle(
                  color:      AppColors.textPrimary,
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Es posible que haya sido eliminada.',
                style: TextStyle(color: AppColors.grisTexto),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _statusColor(task);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detalle de tarea'),
        actions: [
          if (!task.isDone)
            PopupMenuButton<String>(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/edit-task/${task.idTask}');
                } else if (value == 'delete') {
                  final confirmed = await _confirmDelete(context);
                  if (confirmed && context.mounted) {
                    final ok = await context
                        .read<TaskProvider>()
                        .deleteTask(task.idTask);
                    if (ok && context.mounted) context.pop();
                  }
                }
              },
              itemBuilder: (_) => [
                if (!task.isExpired)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: AppColors.blueberry, size: 18),
                        SizedBox(width: 10),
                        Text('Editar',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 10),
                      Text('Eliminar',
                          style: TextStyle(
                              color:      AppColors.error,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Chip de estado ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:        statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: statusColor.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(task), color: statusColor, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _statusLabel(task),
                    style: TextStyle(
                      color:      statusColor,
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Nombre ────────────────────────────────────────────────
            Text(
              task.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.grisTexto,
              ),
            ),

            // ── Descripcion ───────────────────────────────────────────
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                task.description!,
                style: const TextStyle(
                  color:  AppColors.grisTexto,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Foints ganados (si ya fue realizada) ──────────────────
            if (task.isDone &&
                task.fointsEarned != null &&
                task.fointsEarned! > 0) ...[
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.blueberry.withOpacity(0.08),
                      AppColors.lightBlue.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.blueberry.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width:  40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:        AppColors.blueberry.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.blueberry,
                        size:  22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foints ganados',
                          style: TextStyle(
                            color:    AppColors.grisTexto,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '+${task.fointsEarned} F',
                          style: const TextStyle(
                            color:      AppColors.blueberry,
                            fontSize:   22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Separador ─────────────────────────────────────────────
            const Divider(),
            const SizedBox(height: 16),

            // ── Filas de detalle ──────────────────────────────────────
            _DetailRow(
              icon:  Icons.calendar_today_rounded,
              label: 'Programada para',
              value: _formatDate(task.scheduledDate),
            ),

            if (task.isUrgent)
              _DetailRow(
                icon:       Icons.bolt_rounded,
                label:      'Urgente',
                value:      'Si',
                valueColor: AppColors.gum,
              ),

            _DetailRow(
              icon:  Icons.notifications_outlined,
              label: 'Notificacion',
              value: task.notificationType == 'push' ? 'Push' : 'Ninguna',
            ),

            if (task.showFointsBadge)
              const _DetailRow(
                icon:       Icons.star_rounded,
                label:      'Candidata a Foints',
                value:      'Si',
                valueColor: AppColors.blueberry,
              ),

            if (task.isRecurrent) ...[
              _DetailRow(
                icon:  Icons.repeat_rounded,
                label: 'Recurrencia',
                value: _recurrenceLabel(task.recurrenceType),
              ),
              if (task.recurrenceDays != null)
                _DetailRow(
                  icon:  Icons.calendar_view_week_rounded,
                  label: 'Dias',
                  value: _parseDays(task.recurrenceDays!),
                ),
              if (task.recurrenceEndDate != null)
                _DetailRow(
                  icon:  Icons.event_busy_rounded,
                  label: 'Hasta',
                  value: task.recurrenceEndDate!,
                ),
            ],

            const SizedBox(height: 32),

            // ── Boton marcar como realizada ───────────────────────────
            if (!task.isDone && !task.isExpired)
              SizedBox(
                width:  double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await context
                        .read<TaskProvider>()
                        .markAsDone(task.idTask);
                    if (context.mounted) {
                      if (ok) {
                        context.pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.read<TaskProvider>().error ??
                                  'No se pudo completar la tarea',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon:  const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Marcar como realizada'),
                ),
              ),

            // ── Mensaje si esta vencida ───────────────────────────────
            if (task.isExpired)
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(
                    color: AppColors.error.withOpacity(0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta tarea venció sin ser completada.',
                        style: TextStyle(
                          color:    AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  IconData _statusIcon(Task task) {
    if (task.isDone)    return Icons.check_circle_rounded;
    if (task.isExpired) return Icons.cancel_rounded;
    if (task.isUrgent)  return Icons.bolt_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  String _recurrenceLabel(String type) {
    switch (type) {
      case 'diaria':        return 'Todos los dias';
      case 'semanal':       return 'Semanal';
      case 'personalizada': return 'Personalizada';
      default:              return type;
    }
  }

  // Convierte "1,3,5" → "Lun, Mie, Vie"
  String _parseDays(String days) {
    const labels = {
      '1': 'Lun', '2': 'Mar', '3': 'Mie',
      '4': 'Jue', '5': 'Vie', '6': 'Sab', '7': 'Dom',
    };
    return days
        .split(',')
        .map((d) => labels[d.trim()] ?? d)
        .join(', ');
  }
}

// ── Fila de detalle ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.grisTexto, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color:    AppColors.grisTexto,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color:      valueColor,
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}