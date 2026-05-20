import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: CalendarBody()),
    );
  }
}

class CalendarBody extends StatefulWidget {
  const CalendarBody({super.key});

  @override
  State<CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<CalendarBody>
    with SingleTickerProviderStateMixin {
  DateTime  _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay   = DateTime.now();
    _loadMonth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Carga del mes actual ──────────────────────────────────────────────────

  void _loadMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadCalendarTasks(
        year:  _focusedMonth.year,
        month: _focusedMonth.month,
      );
    });
  }

  // ── Cambio de mes ─────────────────────────────────────────────────────────

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
        1,
      );
      _selectedDay = null;
    });
    context.read<TaskProvider>().loadCalendarTasks(
      year:  _focusedMonth.year,
      month: _focusedMonth.month,
    );
  }

  // ── Helpers de calendario ─────────────────────────────────────────────────

  List<DateTime> _daysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      lastDay.day,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  // Offset lunes=0 … domingo=6
  int _firstWeekdayOffset(DateTime month) {
    return (DateTime(month.year, month.month, 1).weekday - 1) % 7;
  }

  String _monthName(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return months[date.month - 1];
  }

  String _dayLabel(DateTime day) {
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo',
    ];
    final today    = DateTime.now();
    final isToday  = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final label = '${dias[day.weekday - 1]} ${day.day}';
    return isToday ? 'Hoy — $label' : label;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();

    return Column(
      children: [
        // ── Header ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calendario',
                style: TextStyle(
                  color:         AppColors.textPrimary,
                  fontSize:      28,
                  fontWeight:    FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              // Toggle Mes / Agenda
              SizedBox(
                width:  180,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color:        AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.lightBlue.withOpacity(0.3),
                    ),
                  ),
                  child: TabBar(
                    controller:      _tabController,
                    indicator: BoxDecoration(
                      color:        AppColors.blueberry,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize:        TabBarIndicatorSize.tab,
                    dividerColor:         Colors.transparent,
                    labelColor:           Colors.white,
                    unselectedLabelColor: AppColors.grisTexto,
                    labelStyle: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize:      MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_view_month_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Mes'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize:      MainAxisSize.min,
                          children: [
                            Icon(Icons.view_agenda_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Agenda'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Leyenda ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _LegendDot(color: AppColors.blueberry, label: 'Completado'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.error,     label: 'Sin completar'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.grisTexto, label: 'Programado'),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // ── Indicador de carga ────────────────────────────────────────────
        if (taskProv.loadingAll)
          const LinearProgressIndicator(
            color:           AppColors.blueberry,
            backgroundColor: Colors.transparent,
            minHeight:       2,
          )
        else
          const SizedBox(height: 2),

        // ── Vistas ────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MonthView(
                focusedMonth: _focusedMonth,
                selectedDay:  _selectedDay,
                taskProv:     taskProv,
                daysInMonth:  _daysInMonth(_focusedMonth),
                offset:       _firstWeekdayOffset(_focusedMonth),
                monthName:    _monthName(_focusedMonth),
                onChangeMonth: _changeMonth,
                onSelectDay:  (day) => setState(() => _selectedDay = day),
              ),
              _AgendaView(
                focusedMonth: _focusedMonth,
                taskProv:     taskProv,
                daysInMonth:  _daysInMonth(_focusedMonth),
                monthName:    _monthName(_focusedMonth),
                dayLabel:     _dayLabel,
                onChangeMonth: _changeMonth,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Vista de mes ──────────────────────────────────────────────────────────────

class _MonthView extends StatelessWidget {
  final DateTime         focusedMonth;
  final DateTime?        selectedDay;
  final TaskProvider     taskProv;
  final List<DateTime>   daysInMonth;
  final int              offset;
  final String           monthName;
  final ValueChanged<int>      onChangeMonth;
  final ValueChanged<DateTime> onSelectDay;

  const _MonthView({
    required this.focusedMonth,
    required this.selectedDay,
    required this.taskProv,
    required this.daysInMonth,
    required this.offset,
    required this.monthName,
    required this.onChangeMonth,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final completedDays = taskProv.completedDaysInMonth(
        focusedMonth.year, focusedMonth.month);
    final failedDays = taskProv.failedDaysInMonth(
        focusedMonth.year, focusedMonth.month);
    final scheduledDays = taskProv.scheduledDaysInMonth(
        focusedMonth.year, focusedMonth.month);

    return Column(
      children: [
        // ── Navegacion de mes ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onChangeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textPrimary,
              ),
              Text(
                '$monthName ${focusedMonth.year}',
                style: const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize:   16,
                ),
              ),
              IconButton(
                onPressed: () => onChangeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),

        // ── Encabezados días de semana ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color:      AppColors.grisTexto,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // ── Grid de dias ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:     7,
              mainAxisSpacing:    4,
              crossAxisSpacing:   4,
              childAspectRatio:   1,
            ),
            itemCount: offset + daysInMonth.length,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox();

              final day       = daysInMonth[i - offset];
              final isToday   = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final isSelected = selectedDay != null &&
                  day.year  == selectedDay!.year &&
                  day.month == selectedDay!.month &&
                  day.day   == selectedDay!.day;
              final isCompleted = completedDays.contains(day.day);
              final isFailed    = failedDays.contains(day.day);
              final isScheduled = scheduledDays.contains(day.day);

              Color? dotColor;
              if (isCompleted)      dotColor = AppColors.blueberry;
              else if (isFailed)    dotColor = AppColors.error;
              else if (isScheduled) dotColor = AppColors.grisTexto;

              return GestureDetector(
                onTap: () => onSelectDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blueberry
                        : isToday
                            ? AppColors.blueberry.withOpacity(0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.blueberry.withOpacity(0.4),
                          )
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.blueberry
                                  : AppColors.textPrimary,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w800
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                      // Punto de estado en la esquina inferior
                      if (dotColor != null && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width:  5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1),

        // ── Panel de tareas del día seleccionado ─────────────────────
        if (selectedDay != null)
          Expanded(
            child: _DayPanel(
              day:      selectedDay!,
              taskProv: taskProv,
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Selecciona un día para ver sus tareas',
                style: TextStyle(color: AppColors.grisTexto, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Panel de tareas del día seleccionado ──────────────────────────────────────

class _DayPanel extends StatelessWidget {
  final DateTime     day;
  final TaskProvider taskProv;

  const _DayPanel({required this.day, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final tasks = taskProv.tasksForDay(day.year, day.month, day.day);
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del panel
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isToday ? 'Hoy' : '${day.day}/${day.month}/${day.year}',
                style: const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize:   15,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        AppColors.blueberry.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tasks.length} tarea${tasks.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color:      AppColors.blueberry,
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Boton agregar tarea en ese día
                  GestureDetector(
                    onTap: () => context.push('/create-task'),
                    child: Container(
                      width:  32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:        AppColors.blueberry,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size:  18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de tareas
        if (tasks.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Sin tareas para este día',
                style: TextStyle(color: AppColors.grisTexto, fontSize: 14),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: tasks.length,
              itemBuilder: (_, i) => _DayTaskTile(task: tasks[i]),
            ),
          ),
      ],
    );
  }
}

// ── Vista agenda ──────────────────────────────────────────────────────────────

class _AgendaView extends StatelessWidget {
  final DateTime       focusedMonth;
  final TaskProvider   taskProv;
  final List<DateTime> daysInMonth;
  final String         monthName;
  final String Function(DateTime) dayLabel;
  final ValueChanged<int> onChangeMonth;

  const _AgendaView({
    required this.focusedMonth,
    required this.taskProv,
    required this.daysInMonth,
    required this.monthName,
    required this.dayLabel,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Solo días que tienen al menos una tarea
    final daysWithTasks = daysInMonth.where((day) {
      return taskProv
          .tasksForDay(day.year, day.month, day.day)
          .isNotEmpty;
    }).toList();

    return Column(
      children: [
        // ── Navegacion de mes ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onChangeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textPrimary,
              ),
              Text(
                '$monthName ${focusedMonth.year}',
                style: const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize:   16,
                ),
              ),
              IconButton(
                onPressed: () => onChangeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),

        // ── Lista de días con tareas ──────────────────────────────────
        Expanded(
          child: daysWithTasks.isEmpty
              ? const Center(
                  child: Text(
                    'Sin tareas este mes',
                    style: TextStyle(
                      color:    AppColors.grisTexto,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: daysWithTasks.length,
                  itemBuilder: (_, i) {
                    final day   = daysWithTasks[i];
                    final tasks = taskProv.tasksForDay(
                        day.year, day.month, day.day);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            dayLabel(day),
                            style: const TextStyle(
                              color:      AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize:   14,
                            ),
                          ),
                        ),
                        ...tasks.map((t) => _AgendaTaskTile(task: t)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Tile de tarea en vista día ────────────────────────────────────────────────

class _DayTaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  const _DayTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final done  = task['done']   as bool;
    final color = Color(task['color'] as int);
    final name  = task['name']   as String;
    final time  = task['time']   as String;
    final foints = task['foints'] as bool;

    return GestureDetector(
      onTap: () {
        final id = task['id'] as int?;
        if (id != null) context.push('/task/$id');
      },
      child: Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done
              ? color.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done
                ? color.withOpacity(0.2)
                : AppColors.lightBlue.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Barra de acento
            Container(
              width:  6,
              height: 40,
              decoration: BoxDecoration(
                color:        done ? color : AppColors.grisTexto.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color:          AppColors.textPrimary,
                      fontWeight:     FontWeight.w700,
                      fontSize:       14,
                      decoration:     done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.grisTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 11, color: AppColors.grisTexto),
                      const SizedBox(width: 3),
                      Text(
                        time,
                        style: const TextStyle(
                          color:    AppColors.grisTexto,
                          fontSize: 11,
                        ),
                      ),
                      if (foints) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:        AppColors.blueberry.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Foints',
                            style: TextStyle(
                              color:      AppColors.blueberry,
                              fontSize:   10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: done ? color : AppColors.grisTexto.withOpacity(0.4),
              size:  22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de tarea en vista agenda ─────────────────────────────────────────────

class _AgendaTaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  const _AgendaTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final done   = task['done']   as bool;
    final color  = Color(task['color'] as int);
    final name   = task['name']   as String;
    final time   = task['time']   as String;
    final foints = task['foints'] as bool;

    return GestureDetector(
      onTap: () {
        final id = task['id'] as int?;
        if (id != null) context.push('/task/$id');
      },
      child: Container(
        margin:  const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width:  5,
              height: 34,
              decoration: BoxDecoration(
                color:        color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color:      AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize:   13,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.grisTexto,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color:    AppColors.grisTexto,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (foints)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:        AppColors.blueberry.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Foints',
                  style: TextStyle(
                    color:      AppColors.blueberry,
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Punto de leyenda ──────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.grisTexto, fontSize: 11),
        ),
      ],
    );
  }
}