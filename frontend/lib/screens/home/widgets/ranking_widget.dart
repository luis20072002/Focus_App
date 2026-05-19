import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ranking_entry.dart';
import '../../../providers/ranking_provider.dart';

class RankingWidget extends StatefulWidget {
  const RankingWidget({super.key});

  @override
  State<RankingWidget> createState() => _RankingWidgetState();
}

class _RankingWidgetState extends State<RankingWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankingProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankProv = context.watch<RankingProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          // ── Header con tabs ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Título + posición del usuario actual
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ranking',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (rankProv.myPosition != null)
                      Text(
                        'Tu posición: #${rankProv.myPosition!.position}',
                        style: const TextStyle(
                          color: AppColors.grisTexto,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (!rankProv.loadingMe)
                      const Text(
                        'Completa tareas para aparecer',
                        style: TextStyle(
                          color: AppColors.grisTexto,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),

                // Selector Global / Amigos
                SizedBox(
                  width: 148,
                  height: 34,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.blueberry,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.grisTexto,
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Global'),
                        Tab(text: 'Amigos'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido de los tabs ─────────────────────────────────────
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab global
                _RankingList(
                  entries:   rankProv.globalRanking,
                  loading:   rankProv.loadingGlobal,
                  myEntry:   rankProv.myPosition,
                  emptyText: 'Aun no hay usuarios en el ranking',
                ),
                // Tab amigos
                _RankingList(
                  entries:   rankProv.friendsRanking,
                  loading:   rankProv.loadingFriends,
                  myEntry:   rankProv.myPosition,
                  isFriends: true,
                  emptyText: 'Sigue a alguien para ver el ranking de amigos',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lista de entradas ─────────────────────────────────────────────────────────

class _RankingList extends StatelessWidget {
  final List<RankingEntry> entries;
  final bool loading;
  final RankingEntry? myEntry;
  final bool isFriends;
  final String emptyText;

  const _RankingList({
    required this.entries,
    required this.loading,
    required this.emptyText,
    this.myEntry,
    this.isFriends = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.blueberry,
          strokeWidth: 2,
        ),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFriends
                    ? Icons.people_outline_rounded
                    : Icons.leaderboard_outlined,
                color: AppColors.grisTexto.withOpacity(0.5),
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grisTexto,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (_, i) => _RankingRow(
        entry:   entries[i],
        isMe:    myEntry != null && entries[i].idUser == myEntry!.idUser,
      ),
    );
  }
}

// ── Fila individual ───────────────────────────────────────────────────────────

class _RankingRow extends StatelessWidget {
  final RankingEntry entry;
  final bool isMe;

  const _RankingRow({required this.entry, required this.isMe});

  // Genera un color determinista a partir del id del usuario
  Color _avatarColor() {
    final palette = [
      AppColors.blueberry,
      AppColors.gum,
      AppColors.neutralOrange,
      AppColors.lightBlue,
      AppColors.midnight,
    ];
    return palette[entry.idUser % palette.length];
  }

  String _initials() {
    final parts = entry.username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return entry.username.substring(0, entry.username.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isTop3  = entry.position <= 3;
    final color   = _avatarColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.blueberry.withOpacity(0.07)
            : isTop3
                ? color.withOpacity(0.05)
                : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.blueberry.withOpacity(0.3)
              : isTop3
                  ? color.withOpacity(0.15)
                  : Colors.transparent,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // ── Posicion ────────────────────────────────────────────────
          SizedBox(
            width: 30,
            child: isTop3
                ? Text(
                    entry.position == 1
                        ? '1'
                        : entry.position == 2
                            ? '2'
                            : '3',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  )
                : Text(
                    '#${entry.position}',
                    style: const TextStyle(
                      color: AppColors.grisTexto,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
          ),

          // ── Avatar ───────────────────────────────────────────────────
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: isMe
                  ? Border.all(color: AppColors.blueberry, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                _initials(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Nombre de usuario ─────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.username,
                    style: TextStyle(
                      color: isMe
                          ? AppColors.blueberry
                          : AppColors.textPrimary,
                      fontWeight: isMe
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueberry,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Tu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Foints ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.blueberry.withOpacity(0.12)
                  : AppColors.blueberry.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.fointsSeason} F',
              style: TextStyle(
                color: isMe
                    ? AppColors.blueberry
                    : AppColors.blueberry.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}