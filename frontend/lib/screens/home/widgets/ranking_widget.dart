import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/users.dart';

class RankingWidget extends StatelessWidget {
  final User user;

  const RankingWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.vinotinto, AppColors.moradoOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Foints de la temporada
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foints esta temporada',
                  style: TextStyle(color: AppColors.blanco, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.fointsSeason}',
                  style: const TextStyle(
                    color: AppColors.amarillo,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Separador
          Container(
            width: 1,
            height: 48,
            color: AppColors.blanco.withOpacity(0.2),
          ),
          const SizedBox(width: 16),
          // Foints totales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foints totales',
                  style: TextStyle(color: AppColors.blanco, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.fointsTotal}',
                  style: const TextStyle(
                    color: AppColors.blanco,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events_rounded, color: AppColors.amarillo, size: 36),
        ],
      ),
    );
  }
}