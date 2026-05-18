import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import 'widgets/task_card.dart';
import '../calendar/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showCompleted = true;
  late TabController _rankingTabController;

  // Datos mock de ranking (en producción vendrían del backend)
  final List<Map<String, dynamic>> _globalRanking = [
    {
      'name': 'María García',
      'foints': 1240,
      'initials': 'MG',
      'color': 0xFFEA88B9,
    },
    {
      'name': 'Carlos López',
      'foints': 1180,
      'initials': 'CL',
      'color': 0xFF5A4EDB,
    },
    {
      'name': 'Ana Martínez',
      'foints': 1050,
      'initials': 'AM',
      'color': 0xFFBCBBF2,
    },
    {
      'name': 'Juan Pérez',
      'foints': 980,
      'initials': 'JP',
      'color': 0xFFE4AAA2,
    },
    {
      'name': 'Sofía Ruiz',
      'foints': 920,
      'initials': 'SR',
      'color': 0xFF0F2C98,
    },
  ];

  @override
  void initState() {
    super.initState();
    _rankingTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTodayTasks();
    });
  }

  @override
  void dispose() {
    _rankingTabController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _todayFormatted() {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final now = DateTime.now();
    return '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProv = context.watch<TaskProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // ── Pantalla Inicio ──────────────────────────────────────────
            _buildHomeTab(user, taskProv),

            // ── Calendario ───────────────────────────────────────────────
            //const CalendarBody(),

            // ── Perfil ───────────────────────────────────────────────────
            _ProfileTab(
              onLogout: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/create-task'),
              backgroundColor: AppColors.blueberry,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Nueva tarea',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab(user, TaskProvider taskProv) {
    final allTasks = taskProv.todayTasks;
    final pendingTasks = allTasks.where((t) => !t.isDone).toList();
    final doneTasks = allTasks.where((t) => t.isDone).toList();
    final visibleTasks = _showCompleted ? allTasks : pendingTasks;
    final completedCount = doneTasks.length;
    final totalCount = allTasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return RefreshIndicator(
      color: AppColors.blueberry,
      backgroundColor: AppColors.surface,
      onRefresh: () => taskProv.loadTodayTasks(),
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              color: AppColors.grisTexto,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            _todayFormatted(),
                            style: const TextStyle(
                              color: AppColors.grisTexto,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 2),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.blueberry,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blueberry.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Foints banner ────────────────────────────────────
                  _FointsBanner(user: user),

                  const SizedBox(height: 20),

                  // ── Progreso del día ─────────────────────────────────
                  _DayProgressCard(
                    completed: completedCount,
                    total: totalCount,
                    progress: progress,
                  ),

                  const SizedBox(height: 24),

                  // ── Ranking ──────────────────────────────────────────
                  _RankingSection(
                    tabController: _rankingTabController,
                    globalRanking: _globalRanking,
                    currentUserFoints: user?.fointsSeason ?? 0,
                  ),

                  const SizedBox(height: 24),

                  // ── Título tareas ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tareas de hoy',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$completedCount de $totalCount completadas',
                            style: const TextStyle(
                              color: AppColors.grisTexto,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Toggle mostrar completadas
                          GestureDetector(
                            onTap: () => setState(
                              () => _showCompleted = !_showCompleted,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _showCompleted
                                    ? AppColors.blueberry.withOpacity(0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _showCompleted
                                      ? AppColors.blueberry.withOpacity(0.3)
                                      : AppColors.grisTexto.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _showCompleted
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 14,
                                    color: _showCompleted
                                        ? AppColors.blueberry
                                        : AppColors.grisTexto,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showCompleted ? 'Todas' : 'Pendientes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _showCompleted
                                          ? AppColors.blueberry
                                          : AppColors.grisTexto,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Lista de tareas ──────────────────────────────────────────
          if (taskProv.loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.blueberry),
              ),
            )
          else if (visibleTasks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.blueberry.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.blueberry,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showCompleted
                          ? '¡Sin tareas para hoy!'
                          : '¡Todo completado!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showCompleted
                          ? 'Agrega una tarea para comenzar'
                          : 'Has completado todas tus tareas del día',
                      style: const TextStyle(
                        color: AppColors.grisTexto,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_showCompleted) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/create-task'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva tarea'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blueberry,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(180, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => TaskCard(task: visibleTasks[i]),
                  childCount: visibleTasks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                selected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Calendario',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                selected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Foints Banner ─────────────────────────────────────────────────────────────

class _FointsBanner extends StatelessWidget {
  final dynamic user;
  const _FointsBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blueberry, AppColors.midnight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueberry.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foints esta temporada',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.fointsSeason ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '⚡ Temporada activa',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.15),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foints totales',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.fointsTotal ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🏆 Acumulado',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
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

// ── Day Progress Card ─────────────────────────────────────────────────────────

class _DayProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _DayProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.lightBlue.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.blueberry,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0
                ? '🎉 ¡Completaste todas tus tareas!'
                : total == 0
                ? 'Sin tareas programadas'
                : '${(progress * 100).toInt()}% completado',
            style: TextStyle(
              color: progress == 1.0
                  ? AppColors.blueberry
                  : AppColors.grisTexto,
              fontSize: 12,
              fontWeight: progress == 1.0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ranking Section ───────────────────────────────────────────────────────────

class _RankingSection extends StatelessWidget {
  final TabController tabController;
  final List<Map<String, dynamic>> globalRanking;
  final int currentUserFoints;

  const _RankingSection({
    required this.tabController,
    required this.globalRanking,
    required this.currentUserFoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ranking',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(
                  width: 148,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: tabController,
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
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: tabController,
              children: [
                _RankingList(
                  items: globalRanking,
                  currentUserFoints: currentUserFoints,
                ),
                _RankingList(
                  items: globalRanking.take(3).toList(),
                  currentUserFoints: currentUserFoints,
                  isFriends: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int currentUserFoints;
  final bool isFriends;

  const _RankingList({
    required this.items,
    required this.currentUserFoints,
    this.isFriends = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFriends && items.isEmpty) {
      return const Center(
        child: Text(
          'Aún no sigues a nadie',
          style: TextStyle(color: AppColors.grisTexto),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final rank = i + 1;
        final isTop3 = rank <= 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isTop3
                ? Color(item['color'] as int).withOpacity(0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: isTop3
                ? Border.all(
                    color: Color(item['color'] as int).withOpacity(0.2),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Rank badge
              SizedBox(
                width: 32,
                child: isTop3
                    ? Text(
                        rank == 1
                            ? '🥇'
                            : rank == 2
                            ? '🥈'
                            : '🥉',
                        style: const TextStyle(fontSize: 20),
                      )
                    : Text(
                        '#$rank',
                        style: const TextStyle(
                          color: AppColors.grisTexto,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color(item['color'] as int).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item['initials'] as String,
                    style: TextStyle(
                      color: Color(item['color'] as int),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nombre
              Expanded(
                child: Text(
                  item['name'] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Foints
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueberry.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item['foints']} F',
                  style: const TextStyle(
                    color: AppColors.blueberry,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blueberry.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.blueberry : AppColors.grisTexto,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.blueberry : AppColors.grisTexto,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blueberry, AppColors.midnight],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueberry.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: const TextStyle(color: AppColors.grisTexto, fontSize: 14),
          ),
          if (user.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                label: 'Foints\ntemporada',
                value: '${user.fointsSeason}',
              ),
              _StatCard(label: 'Foints\ntotales', value: '${user.fointsTotal}'),
            ],
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.blueberry,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.grisTexto, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
