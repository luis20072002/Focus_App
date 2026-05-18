// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../providers/task_provider.dart';

// class CalendarScreen extends StatelessWidget {
//   const CalendarScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(child: CalendarBody()),
//     );
//   }
// }

// class CalendarBody extends StatefulWidget {
//   const CalendarBody({super.key});

//   @override
//   State<CalendarBody> createState() => _CalendarBodyState();
// }

// class _CalendarBodyState extends State<CalendarBody>
//     with SingleTickerProviderStateMixin {
//   DateTime _focusedMonth = DateTime.now();
//   DateTime? _selectedDay;
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _selectedDay = DateTime.now();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<TaskProvider>().loadAllTasks();
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   List<DateTime> _daysInMonth(DateTime month) {
//     final lastDay = DateTime(month.year, month.month + 1, 0);
//     return List.generate(lastDay.day, (i) => DateTime(month.year, month.month, i + 1));
//   }

//   int _firstWeekdayOfMonth(DateTime month) {
//     final firstDay = DateTime(month.year, month.month, 1);
//     return (firstDay.weekday - 1) % 7;
//   }

//   String _monthName(DateTime date) {
//     const months = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
//     return months[date.month - 1];
//   }

//   void _changeMonth(int delta) {
//     setState(() {
//       _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
//     });
//     // Recargar tareas al cambiar de mes por si hay nuevas
//     context.read<TaskProvider>().loadAllTasks();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final taskProv = context.watch<TaskProvider>();

//     return Column(
//       children: [
//         // ── Header ──────────────────────────────────────────────────────────
//         Padding(
//           padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Calendario',
//                 style: TextStyle(
//                   color: AppColors.textPrimary,
//                   fontSize: 28,
//                   fontWeight: FontWeight.w900,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               SizedBox(
//                 width: 160,
//                 height: 38,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
//                   ),
//                   child: TabBar(
//                     controller: _tabController,
//                     indicator: BoxDecoration(
//                       color: AppColors.blueberry,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     indicatorSize: TabBarIndicatorSize.tab,
//                     dividerColor: Colors.transparent,
//                     labelColor: Colors.white,
//                     unselectedLabelColor: AppColors.grisTexto,
//                     labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
//                     tabs: const [
//                       Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_view_month_rounded, size: 14), SizedBox(width: 4), Text('Mes')])),
//                       Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(Icons.view_agenda_rounded, size: 14), SizedBox(width: 4), Text('Agenda')])),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 16),

//         // ── Leyenda ──────────────────────────────────────────────────────────
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Row(
//             children: [
//               _LegendDot(color: AppColors.blueberry, label: 'Completado'),
//               const SizedBox(width: 16),
//               _LegendDot(color: AppColors.error, label: 'Sin completar'),
//               const SizedBox(width: 16),
//               _LegendDot(color: AppColors.grisTexto, label: 'Programado'),
//             ],
//           ),
//         ),

//         const SizedBox(height: 12),

//         // ── Loading indicator ─────────────────────────────────────────────
//         if (taskProv.loadingAll)
//           const LinearProgressIndicator(
//             color: AppColors.blueberry,
//             backgroundColor: Colors.transparent,
//             minHeight: 2,
//           ),

//         // ── Contenido ────────────────────────────────────────────────────────
//         Expanded(
//           child: TabBarView(
//             controller: _tabController,
//             children: [
//               _buildMonthView(taskProv),
//               _buildAgendaView(taskProv),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Vista Mes ──────────────────────────────────────────────────────────────

//   Widget _buildMonthView(TaskProvider taskProv) {
//     final days      = _daysInMonth(_focusedMonth);
//     final offset    = _firstWeekdayOfMonth(_focusedMonth);
//     final today     = DateTime.now();
//     final isCurrentMonth = _focusedMonth.year == today.year && _focusedMonth.month == today.month;

//     final completedDays = taskProv.completedDaysInMonth(_focusedMonth.year, _focusedMonth.month);
//     final failedDays    = taskProv.failedDaysInMonth(_focusedMonth.year, _focusedMonth.month);
//     final scheduledDays = taskProv.scheduledDaysInMonth(_focusedMonth.year, _focusedMonth.month);

//     return Column(
//       children: [
//         // Navegación mes
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               IconButton(
//                 onPressed: () => _changeMonth(-1),
//                 icon: const Icon(Icons.chevron_left_rounded),
//                 color: AppColors.textPrimary,
//               ),
//               Text(
//                 '${_monthName(_focusedMonth)} ${_focusedMonth.year}',
//                 style: const TextStyle(
//                   color: AppColors.textPrimary,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 16,
//                 ),
//               ),
//               IconButton(
//                 onPressed: () => _changeMonth(1),
//                 icon: const Icon(Icons.chevron_right_rounded),
//                 color: AppColors.textPrimary,
//               ),
//             ],
//           ),
//         ),

//         // Encabezados días
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             children: ['L','M','X','J','V','S','D'].map((d) => Expanded(
//               child: Center(
//                 child: Text(d, style: const TextStyle(color: AppColors.grisTexto, fontSize: 12, fontWeight: FontWeight.w700)),
//               ),
//             )).toList(),
//           ),
//         ),

//         const SizedBox(height: 8),

//         // Grid días
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 7,
//               childAspectRatio: 1,
//             ),
//             itemCount: days.length + offset,
//             itemBuilder: (_, index) {
//               if (index < offset) return const SizedBox();
//               final day    = days[index - offset];
//               final dayNum = day.day;
//               final isToday    = isCurrentMonth && dayNum == today.day;
//               final isSelected = _selectedDay != null &&
//                   _selectedDay!.day == dayNum &&
//                   _selectedDay!.month == _focusedMonth.month &&
//                   _selectedDay!.year == _focusedMonth.year;
//               final isCompleted = completedDays.contains(dayNum);
//               final isFailed    = failedDays.contains(dayNum);
//               final isScheduled = scheduledDays.contains(dayNum);

//               Color? dotColor;
//               if (isCompleted) dotColor = AppColors.blueberry;
//               if (isFailed)    dotColor = AppColors.error;
//               if (isScheduled) dotColor = AppColors.grisTexto;

//               return GestureDetector(
//                 onTap: () => setState(() => _selectedDay = day),
//                 child: Container(
//                   margin: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? AppColors.blueberry
//                         : isToday
//                         ? AppColors.blueberry.withOpacity(0.12)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         '$dayNum',
//                         style: TextStyle(
//                           color: isSelected ? Colors.white : isToday ? AppColors.blueberry : AppColors.textPrimary,
//                           fontWeight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w500,
//                           fontSize: 13,
//                         ),
//                       ),
//                       if (dotColor != null)
//                         Container(
//                           width: 4,
//                           height: 4,
//                           margin: const EdgeInsets.only(top: 2),
//                           decoration: BoxDecoration(
//                             color: isSelected ? Colors.white70 : dotColor,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),

//         const SizedBox(height: 16),

//         if (_selectedDay != null)
//           Expanded(
//             child: _DayTasksPanel(
//               day: _selectedDay!,
//               tasks: taskProv.tasksForDay(
//                 _selectedDay!.year,
//                 _selectedDay!.month,
//                 _selectedDay!.day,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   // ── Vista Agenda ───────────────────────────────────────────────────────────

//   Widget _buildAgendaView(TaskProvider taskProv) {
//     // Agrupar todas las tareas del mes enfocado por día, ordenadas
//     final Map<int, List<Map<String, dynamic>>> byDay = {};
//     for (final task in taskProv.allTasks) {
//       try {
//         final dt = DateTime.parse(task.scheduledDate);
//         if (dt.year == _focusedMonth.year && dt.month == _focusedMonth.month) {
//           final tasks = taskProv.tasksForDay(dt.year, dt.month, dt.day);
//           byDay[dt.day] = tasks;
//         }
//       } catch (_) {}
//     }

//     final allEntries = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

//     if (allEntries.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.event_available_rounded, color: AppColors.grisTexto, size: 48),
//             const SizedBox(height: 12),
//             Text(
//               taskProv.loadingAll ? 'Cargando tareas...' : 'Sin tareas programadas',
//               style: const TextStyle(color: AppColors.grisTexto, fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
//       itemCount: allEntries.length,
//       itemBuilder: (_, i) {
//         final entry  = allEntries[i];
//         final dayNum = entry.key;
//         final tasks  = entry.value;

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       color: AppColors.blueberry,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Center(
//                       child: Text(
//                         '$dayNum',
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     '${_monthName(_focusedMonth)} ${_focusedMonth.year}',
//                     style: const TextStyle(color: AppColors.grisTexto, fontSize: 13, fontWeight: FontWeight.w500),
//                   ),
//                 ],
//               ),
//             ),
//             ...tasks.map((t) => _AgendaTaskTile(task: t)),
//           ],
//         );
//       },
//     );
//   }
// }

// // ── Day Tasks Panel ────────────────────────────────────────────────────────────

// class _DayTasksPanel extends StatelessWidget {
//   final DateTime day;
//   final List<Map<String, dynamic>> tasks;

//   const _DayTasksPanel({required this.day, required this.tasks});

//   String _dayLabel(DateTime d) {
//     const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
//     return '${d.day} ${meses[d.month - 1]} ${d.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//         border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -4)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//               width: 36,
//               height: 4,
//               margin: const EdgeInsets.only(top: 10, bottom: 16),
//               decoration: BoxDecoration(
//                 color: AppColors.lightBlue.withOpacity(0.4),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _dayLabel(day),
//                   style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: AppColors.blueberry.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     '${tasks.length} tarea${tasks.length == 1 ? '' : 's'}',
//                     style: const TextStyle(color: AppColors.blueberry, fontSize: 12, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           if (tasks.isEmpty)
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: Text(
//                 'No hay tareas para este día.\nToca el botón + para agregar una.',
//                 style: TextStyle(color: AppColors.grisTexto, fontSize: 14),
//               ),
//             )
//           else
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//                 itemCount: tasks.length,
//                 itemBuilder: (_, i) => _DayTaskTile(task: tasks[i]),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ── Day Task Tile ──────────────────────────────────────────────────────────────

// class _DayTaskTile extends StatelessWidget {
//   final Map<String, dynamic> task;
//   const _DayTaskTile({required this.task});

//   @override
//   Widget build(BuildContext context) {
//     final done  = task['done'] as bool;
//     final color = Color(task['color'] as int);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: done ? color.withOpacity(0.05) : AppColors.background,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: done ? color.withOpacity(0.2) : AppColors.lightBlue.withOpacity(0.3),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 8,
//             height: 40,
//             decoration: BoxDecoration(
//               color: done ? color : AppColors.grisTexto.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   task['name'] as String,
//                   style: TextStyle(
//                     color: AppColors.textPrimary,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 14,
//                     decoration: done ? TextDecoration.lineThrough : null,
//                     decorationColor: AppColors.grisTexto,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Row(
//                   children: [
//                     const Icon(Icons.schedule, size: 11, color: AppColors.grisTexto),
//                     const SizedBox(width: 3),
//                     Text(task['time'] as String, style: const TextStyle(color: AppColors.grisTexto, fontSize: 11)),
//                     if (task['foints'] == true) ...[
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: AppColors.blueberry.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: const Text('Foints', style: TextStyle(color: AppColors.blueberry, fontSize: 10, fontWeight: FontWeight.w600)),
//                       ),
//                     ],
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Icon(
//             done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
//             color: done ? color : AppColors.grisTexto.withOpacity(0.4),
//             size: 22,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Agenda Task Tile ───────────────────────────────────────────────────────────

// class _AgendaTaskTile extends StatelessWidget {
//   final Map<String, dynamic> task;
//   const _AgendaTaskTile({required this.task});

//   @override
//   Widget build(BuildContext context) {
//     final color = Color(task['color'] as int);
//     final done  = task['done'] as bool;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 6,
//             height: 34,
//             decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   task['name'] as String,
//                   style: TextStyle(
//                     color: AppColors.textPrimary,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                     decoration: done ? TextDecoration.lineThrough : null,
//                   ),
//                 ),
//                 Text(task['time'] as String, style: const TextStyle(color: AppColors.grisTexto, fontSize: 11)),
//               ],
//             ),
//           ),
//           if (task['foints'] == true)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: AppColors.blueberry.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: const Text('Foints', style: TextStyle(color: AppColors.blueberry, fontSize: 10, fontWeight: FontWeight.w600)),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ── Legend Dot ─────────────────────────────────────────────────────────────────

// class _LegendDot extends StatelessWidget {
//   final Color color;
//   final String label;
//   const _LegendDot({required this.color, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//         const SizedBox(width: 4),
//         Text(label, style: const TextStyle(color: AppColors.grisTexto, fontSize: 11)),
//       ],
//     );
//   }
// }