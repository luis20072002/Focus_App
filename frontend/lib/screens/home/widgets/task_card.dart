import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  // ── Helpers de estado ─────────────────────────────────────────────────────

  Color get _statusColor {
    if (task.isDone)    return const Color(0xFF34C759); // verde sistema
    if (task.isExpired) return AppColors.error;
    if (task.isUrgent)  return AppColors.gum;
    return AppColors.blueberry;
  }

  IconData get _statusIcon {
    if (task.isDone)    return Icons.check_circle_rounded;
    if (task.isExpired) return Icons.cancel_rounded;
    if (task.isUrgent)  return Icons.priority_high_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  String get _formattedTime {
    try {
      final dt = DateTime.parse(task.scheduledDate);
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  // Borde izquierdo de color segun estado
  Color get _accentColor {
    if (task.isDone)    return const Color(0xFF34C759);
    if (task.isExpired) return AppColors.error;
    if (task.isUrgent)  return AppColors.gum;
    return AppColors.blueberry;
  }

  // ── Dialogo de confirmacion de eliminacion ────────────────────────────────

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
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: const Text(
              'Esta accion no se puede deshacer.',
              style: TextStyle(color: AppColors.grisTexto, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.grisTexto),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/task/${task.idTask}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isUrgent
                ? AppColors.gum.withOpacity(0.35)
                : AppColors.lightBlue.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Barra de acento lateral ────────────────────────────
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft:    Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // ── Contenido principal ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono de estado / tap para completar
                      GestureDetector(
                        onTap: (task.isDone || task.isExpired)
                            ? null
                            : () async {
                                final ok = await context
                                    .read<TaskProvider>()
                                    .markAsDone(task.idTask);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'No se pudo marcar la tarea',
                                      ),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1, right: 12),
                          child: Icon(
                            _statusIcon,
                            color: _statusColor,
                            size: 26,
                          ),
                        ),
                      ),

                      // Texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre
                            Text(
                              task.name,
                              style: TextStyle(
                                color: task.isDone
                                    ? AppColors.grisTexto
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.grisTexto,
                              ),
                            ),

                            // Descripcion opcional
                            if (task.description != null &&
                                task.description!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                task.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.grisTexto,
                                  fontSize: 12,
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Chips de metadata
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // Hora
                                if (_formattedTime.isNotEmpty)
                                  _MetaChip(
                                    icon:  Icons.schedule_rounded,
                                    label: _formattedTime,
                                  ),

                                // Urgente
                                if (task.isUrgent)
                                  _MetaChip(
                                    icon:       Icons.bolt_rounded,
                                    label:      'Urgente',
                                    iconColor:  AppColors.gum,
                                    labelColor: AppColors.gum,
                                  ),

                                // Recurrente
                                if (task.isRecurrent)
                                  _MetaChip(
                                    icon:  Icons.repeat_rounded,
                                    label: task.recurrenceType,
                                  ),

                                // Candidata a Foints
                                if (task.isFointCandidate)
                                  _MetaChip(
                                    icon:       Icons.star_rounded,
                                    label:      'Foints',
                                    iconColor:  AppColors.blueberry,
                                    labelColor: AppColors.blueberry,
                                  ),

                                // Foints ganados (cuando ya esta realizada)
                                if (task.isDone &&
                                    task.fointsEarned != null &&
                                    task.fointsEarned! > 0)
                                  _MetaChip(
                                    icon:       Icons.add_circle_rounded,
                                    label:      '+${task.fointsEarned} F',
                                    iconColor:  const Color(0xFF34C759),
                                    labelColor: const Color(0xFF34C759),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Menu contextual ──────────────────────────
                      if (!task.isDone)
                        _TaskMenu(task: task, onDelete: _confirmDelete),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu contextual ───────────────────────────────────────────────────────────

class _TaskMenu extends StatelessWidget {
  final Task task;
  final Future<bool> Function(BuildContext) onDelete;

  const _TaskMenu({required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.grisTexto, size: 20),
      onSelected: (value) async {
        if (value == 'edit') {
          context.push('/edit-task/${task.idTask}');
        } else if (value == 'delete') {
          final confirmed = await onDelete(context);
          if (confirmed && context.mounted) {
            await context.read<TaskProvider>().deleteTask(task.idTask);
          }
        }
      },
      itemBuilder: (_) => [
        if (!task.isExpired)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: AppColors.blueberry, size: 18),
                SizedBox(width: 10),
                Text(
                  'Editar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
              SizedBox(width: 10),
              Text(
                'Eliminar',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Chip de metadata ──────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    iconColor;
  final Color    labelColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.iconColor  = AppColors.grisTexto,
    this.labelColor = AppColors.grisTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}