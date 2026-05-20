import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../profile/profile_screen.dart';
import '../calendar/calendar_screen.dart';
import 'widgets/foints_banner.dart';
import 'widgets/day_progress_card.dart';
import 'widgets/ranking_widget.dart';
import 'widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int  _selectedIndex = 0;
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTodayTasks();
      context.read<UserProvider>().loadMe();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _todayFormatted() {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    const dias = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
    ];
    final now = DateTime.now();
    return '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeTab(
              showCompleted:  _showCompleted,
              greeting:       _greeting(),
              todayFormatted: _todayFormatted(),
              onToggleFilter: () => setState(() => _showCompleted = !_showCompleted),
              onGoToProfile:  () => setState(() => _selectedIndex = 2),
            ),
            const CalendarBody(),
            const ProfileScreen(),   // ← antes era _ProfilePlaceholder
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed:       () => context.go('/create-task'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation:       4,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ── Tab de inicio ─────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final bool         showCompleted;
  final String       greeting;
  final String       todayFormatted;
  final VoidCallback onToggleFilter;
  final VoidCallback onGoToProfile;

  const _HomeTab({
    required this.showCompleted,
    required this.greeting,
    required this.todayFormatted,
    required this.onToggleFilter,
    required this.onGoToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final user     = context.watch<UserProvider>().user;
    final taskProv = context.watch<TaskProvider>();

    final allTasks       = taskProv.todayTasks;
    final completedCount = allTasks.where((t) => t.isDone).length;
    final totalCount     = allTasks.length;
    final visibleTasks   = showCompleted
        ? allTasks
        : allTasks.where((t) => !t.isDone).toList();

    return RefreshIndicator(
      color:           AppColors.blueberry,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await Future.wait([
          context.read<TaskProvider>().loadTodayTasks(),
          context.read<UserProvider>().loadMe(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              color:    AppColors.grisTexto,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name ?? '',
                            style: const TextStyle(
                              color:         AppColors.textPrimary,
                              fontSize:      24,
                              fontWeight:    FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            todayFormatted,
                            style: const TextStyle(
                              color:    AppColors.grisTexto,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Avatar — navega al perfil
                      GestureDetector(
                        onTap: onGoToProfile,
                        child: Container(
                          width:  46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.blueberry,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:      AppColors.blueberry.withOpacity(0.3),
                                blurRadius: 12,
                                offset:     const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize:   18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Foints banner ──────────────────────────────────────
                  FointsBanner(user: user),

                  const SizedBox(height: 20),

                  // ── Progreso del día ───────────────────────────────────
                  DayProgressCard(
                    completed: completedCount,
                    total:     totalCount,
                  ),

                  const SizedBox(height: 24),

                  // ── Ranking ────────────────────────────────────────────
                  const RankingWidget(),

                  const SizedBox(height: 24),

                  // ── Encabezado lista de tareas ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tareas de hoy',
                            style: TextStyle(
                              color:      AppColors.textPrimary,
                              fontSize:   18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$completedCount de $totalCount completadas',
                            style: const TextStyle(
                              color:    AppColors.grisTexto,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      _FilterToggle(
                        showCompleted: showCompleted,
                        onTap:         onToggleFilter,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Lista de tareas ────────────────────────────────────────────
          if (taskProv.loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.blueberry),
              ),
            )
          else if (taskProv.error != null)
            SliverFillRemaining(
              child: _ErrorState(
                message: taskProv.error!,
                onRetry: () => context.read<TaskProvider>().loadTodayTasks(),
              ),
            )
          else if (visibleTasks.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(showCompleted: showCompleted),
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
}

// ── Toggle de filtro ──────────────────────────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  final bool         showCompleted;
  final VoidCallback onTap;

  const _FilterToggle({required this.showCompleted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: showCompleted
              ? AppColors.blueberry.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: showCompleted
                ? AppColors.blueberry.withOpacity(0.3)
                : AppColors.grisTexto.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showCompleted
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size:  14,
              color: showCompleted ? AppColors.blueberry : AppColors.grisTexto,
            ),
            const SizedBox(width: 4),
            Text(
              showCompleted ? 'Todas' : 'Pendientes',
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: showCompleted ? AppColors.blueberry : AppColors.grisTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool showCompleted;
  const _EmptyState({required this.showCompleted});

  @override
  Widget build(BuildContext context) {
    final allDone = !showCompleted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.blueberry.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                allDone ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                color: AppColors.blueberry,
                size:  40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              allDone ? 'Todo completado' : 'Sin tareas para hoy',
              style: const TextStyle(
                color:      AppColors.textPrimary,
                fontSize:   18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              allDone
                  ? 'Has completado todas las tareas del día'
                  : 'Agrega una tarea para empezar el día',
              style: const TextStyle(
                color:    AppColors.grisTexto,
                fontSize: 14,
                height:   1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!allDone) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/create-task'),
                icon:      const Icon(Icons.add_rounded),
                label:     const Text('Nueva tarea'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueberry,
                  foregroundColor: Colors.white,
                  minimumSize:     const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Estado de error ───────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size:  36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar las tareas',
              style: TextStyle(
                color:      AppColors.textPrimary,
                fontSize:   16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                color:    AppColors.grisTexto,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon:      const Icon(Icons.refresh_rounded),
              label:     const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blueberry,
                side: const BorderSide(color: AppColors.blueberry),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int               selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset:     const Offset(0, -4),
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
                icon:     Icons.home_rounded,
                label:    'Inicio',
                selected: selectedIndex == 0,
                onTap:    () => onTap(0),
              ),
              _NavItem(
                icon:     Icons.calendar_month_rounded,
                label:    'Calendario',
                selected: selectedIndex == 1,
                onTap:    () => onTap(1),
              ),
              _NavItem(
                icon:     Icons.person_outline_rounded,
                label:    'Perfil',
                selected: selectedIndex == 2,
                onTap:    () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         selected;
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
              size:  24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color:      selected ? AppColors.blueberry : AppColors.grisTexto,
                fontSize:   11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}