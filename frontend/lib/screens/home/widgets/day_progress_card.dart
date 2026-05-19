import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DayProgressCard extends StatelessWidget {
  /// Número de tareas completadas hoy.
  final int completed;

  /// Total de tareas del día (completadas + pendientes + vencidas).
  final int total;

  const DayProgressCard({
    super.key,
    required this.completed,
    required this.total,
  });

  double get _progress => total > 0 ? completed / total : 0.0;

  bool get _allDone => total > 0 && completed == total;

  String get _progressLabel {
    if (total == 0) return 'Sin tareas programadas';
    if (_allDone)   return '¡Completaste todas tus tareas!';
    return '${(_progress * 100).toInt()}% completado';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso del día',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '$completed / $total tareas',
                style: const TextStyle(
                  color: AppColors.grisTexto,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Barra de progreso ─────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.lightBlue.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _allDone ? AppColors.blueberry : AppColors.blueberry,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Etiqueta de estado ────────────────────────────────────────
          Row(
            children: [
              if (_allDone) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.blueberry,
                  size: 14,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                _progressLabel,
                style: TextStyle(
                  color: _allDone
                      ? AppColors.blueberry
                      : AppColors.grisTexto,
                  fontSize: 12,
                  fontWeight: _allDone
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}