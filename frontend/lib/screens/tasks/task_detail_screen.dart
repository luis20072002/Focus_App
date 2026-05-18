import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

class TaskDetailScreen extends StatelessWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final Task? task = taskProv.todayTasks.where((t) => t.idTask == taskId).isNotEmpty
        ? taskProv.todayTasks.firstWhere((t) => t.idTask == taskId)
        : null;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanco),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: const Center(
          child: Text('Tarea no encontrada', style: TextStyle(color: AppColors.blanco)),
        ),
      );
    }

    String formatDate(String iso) {
      try {
        final dt = DateTime.parse(iso);
        const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '${dt.day} ${meses[dt.month - 1]} ${dt.year} a las $h:$m';
      } catch (_) {
        return iso;
      }
    }

    Color statusColor() {
      if (task.isDone)    return Colors.green;
      if (task.isExpired) return AppColors.error;
      if (task.isUrgent)  return AppColors.rojo;
      return AppColors.naranja;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanco),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Detalle de tarea', style: TextStyle(color: AppColors.blanco)),
        actions: [
          if (!task.isDone)
            PopupMenuButton<String>(
              color: AppColors.tarjeta,
              icon: const Icon(Icons.more_vert, color: AppColors.blanco),
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
                    if (context.mounted) context.go('/home');
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor().withOpacity(0.4)),
              ),
              child: Text(
                task.status,
                style: TextStyle(color: statusColor(), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // Nombre
            Text(task.name, style: const TextStyle(color: AppColors.blanco, fontSize: 26, fontWeight: FontWeight.bold)),

            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(task.description!, style: const TextStyle(color: AppColors.grisTexto, fontSize: 15, height: 1.5)),
            ],

            const SizedBox(height: 24),
            const Divider(color: AppColors.tarjeta),
            const SizedBox(height: 16),

            // Detalles
            _DetailRow(icon: Icons.schedule, label: 'Programada para', value: formatDate(task.scheduledDate)),
            if (task.isUrgent)
              const _DetailRow(icon: Icons.priority_high_rounded, label: 'Urgente', value: 'Si', valueColor: AppColors.rojo),
            if (task.isRecurrent) ...[
              _DetailRow(icon: Icons.repeat, label: 'Recurrencia', value: task.recurrenceType),
              if (task.recurrenceDays != null)
                _DetailRow(icon: Icons.calendar_view_week, label: 'Dias', value: task.recurrenceDays!),
              if (task.recurrenceEndDate != null)
                _DetailRow(icon: Icons.event_busy, label: 'Hasta', value: task.recurrenceEndDate!),
            ],
            _DetailRow(icon: Icons.notifications_outlined, label: 'Notificacion', value: task.notificationType),

            const Spacer(),

            // Boton marcar como realizada
            if (!task.isDone && !task.isExpired)
              ElevatedButton.icon(
                onPressed: () async {
                  final ok = await context.read<TaskProvider>().markAsDone(task.idTask);
                  if (context.mounted) {
                    if (ok) {
                      context.go('/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se pudo actualizar la tarea'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar como realizada', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.blanco,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grisTexto, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: AppColors.grisTexto)),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}