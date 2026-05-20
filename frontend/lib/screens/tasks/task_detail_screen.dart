import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

class TaskDetailScreen extends StatelessWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  // ── Busca en todayTasks y calendarTasks ───────────────────────────────────
  Task? _findTask(TaskProvider prov) {
    final inToday = prov.todayTasks.where((t) => t.idTask == taskId);
    if (inToday.isNotEmpty) return inToday.first;
    final inCalendar = prov.calendarTasks.where((t) => t.idTask == taskId);
    if (inCalendar.isNotEmpty) return inCalendar.first;
    return null;
  }

  Color _statusColor(BuildContext context, Task task) {
    final colors = Theme.of(context).colorScheme;
    if (task.isDone)    return Colors.green;
    if (task.isExpired) return colors.error;
    if (task.isUrgent)  return AppColors.gum;
    return colors.primary;
  }

  IconData _statusIcon(Task task) {
    if (task.isDone)    return Icons.check_circle_rounded;
    if (task.isExpired) return Icons.cancel_rounded;
    if (task.isUrgent)  return Icons.bolt_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  String _statusLabel(Task task) {
    if (task.isDone)    return 'Realizada';
    if (task.isExpired) return 'Vencida';
    if (task.isUrgent)  return 'Urgente';
    return 'Pendiente';
  }

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

  String _recurrenceLabel(String type) {
    switch (type) {
      case 'diaria':        return 'Todos los días';
      case 'semanal':       return 'Semanal';
      case 'personalizada': return 'Personalizada';
      default:              return type;
    }
  }

  String _parseDays(String days) {
    const labels = {
      '1': 'Lun', '2': 'Mar', '3': 'Mié',
      '4': 'Jue', '5': 'Vie', '6': 'Sáb', '7': 'Dom',
    };
    return days.split(',').map((d) => labels[d.trim()] ?? d).join(', ');
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: const Text('Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Eliminar',
                  style: TextStyle(
                    color:      theme.colorScheme.error,
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
    final theme    = Theme.of(context);
    final colors   = theme.colorScheme;
    final taskProv = context.watch<TaskProvider>();
    final task     = _findTask(taskProv);

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
              Text(
                'Tarea no encontrada',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Es posible que haya sido eliminada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grisTexto,
                ),
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

    final statusColor = _statusColor(context, task);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detalle de tarea'),
        actions: [
          if (!task.isDone)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/create-task');
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
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: colors.primary, size: 18),
                        const SizedBox(width: 10),
                        const Text('Editar',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: colors.error, size: 18),
                      const SizedBox(width: 10),
                      Text('Eliminar',
                          style: TextStyle(
                              color:      colors.error,
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:      statusColor,
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
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.grisTexto,
              ),
            ),

            // ── Descripción ───────────────────────────────────────────
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                task.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:  AppColors.grisTexto,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Foints ganados ────────────────────────────────────────
            if (task.isDone &&
                task.fointsEarned != null &&
                task.fointsEarned! > 0) ...[
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.08),
                      colors.primaryContainer.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color:        colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.bolt_rounded,
                          color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Foints ganados',
                            style: theme.textTheme.bodySmall),
                        Text(
                          '+${task.fointsEarned} F',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color:      colors.primary,
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
                value:      'Sí',
                valueColor: AppColors.gum,
              ),

            _DetailRow(
              icon:  Icons.notifications_outlined,
              label: 'Notificación',
              value: task.notificationType == 'push' ? 'Push' : 'Ninguna',
            ),

            if (task.showFointsBadge)
              _DetailRow(
                icon:       Icons.star_rounded,
                label:      'Candidata a Foints',
                value:      'Sí',
                valueColor: colors.primary,
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
                  label: 'Días',
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

            // ── Botón marcar como realizada ───────────────────────────
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

            // ── Mensaje si está vencida ───────────────────────────────
            if (task.isExpired)
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        colors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: colors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta tarea venció sin ser completada.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
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
}

// ── Fila de detalle ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:      valueColor,
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