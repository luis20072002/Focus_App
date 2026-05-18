import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  Color get _statusColor {
    if (task.isDone)    return Colors.green;
    if (task.isExpired) return AppColors.error;
    if (task.isUrgent)  return AppColors.rojo;
    return AppColors.naranja;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isUrgent ? AppColors.rojo.withOpacity(0.4) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: task.isDone
              ? null
              : () async {
                  final ok = await context.read<TaskProvider>().markAsDone(task.idTask);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo marcar la tarea'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
          child: Icon(_statusIcon, color: _statusColor, size: 28),
        ),
        title: Text(
          task.name,
          style: TextStyle(
            color: task.isDone ? AppColors.grisTexto : AppColors.blanco,
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description!,
                  style: const TextStyle(color: AppColors.grisTexto, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (_formattedTime.isNotEmpty) ...[
                  const Icon(Icons.schedule, size: 12, color: AppColors.grisTexto),
                  const SizedBox(width: 4),
                  Text(_formattedTime, style: const TextStyle(color: AppColors.grisTexto, fontSize: 11)),
                  const SizedBox(width: 10),
                ],
                if (task.isRecurrent) ...[
                  const Icon(Icons.repeat, size: 12, color: AppColors.amarillo),
                  const SizedBox(width: 4),
                  Text(task.recurrenceType, style: const TextStyle(color: AppColors.amarillo, fontSize: 11)),
                ],
                if (task.idTaskTemplate != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.star_rounded, size: 12, color: AppColors.amarillo),
                  const SizedBox(width: 4),
                  const Text('Foints', style: TextStyle(color: AppColors.amarillo, fontSize: 11)),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.tarjeta,
          icon: const Icon(Icons.more_vert, color: AppColors.grisTexto),
          onSelected: (value) async {
            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.tarjeta,
                  title: const Text('Eliminar tarea', style: TextStyle(color: AppColors.blanco)),
                  content: const Text('Esta accion no se puede deshacer.', style: TextStyle(color: AppColors.grisTexto)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.grisTexto))),
                    TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Eliminar',  style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<TaskProvider>().deleteTask(task.idTask);
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ),
    );
  }
}