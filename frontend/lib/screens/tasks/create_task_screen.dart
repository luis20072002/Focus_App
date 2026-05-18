// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:go_router/go_router.dart';
// import '../../core/theme/app_colors.dart';
// import '../../providers/task_provider.dart';

// class CreateTaskScreen extends StatefulWidget {
//   const CreateTaskScreen({super.key});

//   @override
//   State<CreateTaskScreen> createState() => _CreateTaskScreenState();
// }

// class _CreateTaskScreenState extends State<CreateTaskScreen>
//     with SingleTickerProviderStateMixin {
//   // ── Controladores y estado ───────────────────────────────────────────────
//   final _formKey = GlobalKey<FormState>();
//   final _nameCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();

//   // Selección de origen de la tarea
//   bool _fromTemplate = false;
//   Map<String, dynamic>? _selectedTemplate;

//   // ¿Quiere Foints?
//   bool _wantFoints = false;

//   bool _isUrgent = false;
//   bool _isRecurrent = false;
//   String _notifType = 'push';
//   String _recurrenceType = 'ninguna';
//   DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
//   DateTime? _recurrenceEnd;
//   bool _loading = false;

//   final Set<int> _selectedDays = {};
//   final List<String> _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
//   final List<String> _notifTypes = ['push', 'email', 'ninguna'];
//   final List<Map<String, dynamic>> _recurrenceTypes = [
//     {'value': 'ninguna', 'label': 'No repetir'},
//     {'value': 'diaria', 'label': 'Todos los días'},
//     {'value': 'semanal', 'label': 'Semanal'},
//     {'value': 'personalizada', 'label': 'Personalizada'},
//   ];

//   // Cantidad máxima de tareas con Foints por día (regla de negocio)
//   static const int _maxFointsPerDay = 3;
//   final int _currentFointsToday = 1; // mock — en prod viene del provider

//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 350),
//     );
//     _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
//     _animController.forward();
//   }

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _descCtrl.dispose();
//     _animController.dispose();
//     super.dispose();
//   }

//   bool get _canAddFoints =>
//       !_isUrgent && _currentFointsToday < _maxFointsPerDay;

//   Future<void> _pickDateTime() async {
//     final date = await showDatePicker(
//       context: context,
//       initialDate: _scheduledDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
//       builder: (context, child) => Theme(
//         data: Theme.of(context).copyWith(
//           colorScheme: const ColorScheme.light(
//             primary: AppColors.blueberry,
//             onPrimary: Colors.white,
//             surface: Colors.white,
//           ),
//         ),
//         child: child!,
//       ),
//     );
//     if (date == null || !mounted) return;

//     final time = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.fromDateTime(_scheduledDate),
//       builder: (context, child) => Theme(
//         data: Theme.of(context).copyWith(
//           colorScheme: const ColorScheme.light(primary: AppColors.blueberry),
//         ),
//         child: child!,
//       ),
//     );
//     if (time == null) return;
//     setState(() {
//       _scheduledDate = DateTime(
//         date.year,
//         date.month,
//         date.day,
//         time.hour,
//         time.minute,
//       );
//     });
//   }

//   Future<void> _pickRecurrenceEnd() async {
//     final date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 30)),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
//       builder: (context, child) => Theme(
//         data: Theme.of(context).copyWith(
//           colorScheme: const ColorScheme.light(primary: AppColors.blueberry),
//         ),
//         child: child!,
//       ),
//     );
//     if (date != null) setState(() => _recurrenceEnd = date);
//   }

//   String _formatDateTime(DateTime dt) {
//     const meses = [
//       'ene',
//       'feb',
//       'mar',
//       'abr',
//       'may',
//       'jun',
//       'jul',
//       'ago',
//       'sep',
//       'oct',
//       'nov',
//       'dic',
//     ];
//     final h = dt.hour.toString().padLeft(2, '0');
//     final m = dt.minute.toString().padLeft(2, '0');
//     return '${dt.day} ${meses[dt.month - 1]} ${dt.year}  $h:$m';
//   }

//   void _onTemplateSelected(Map<String, dynamic> template) {
//     setState(() {
//       _selectedTemplate = template;
//       _nameCtrl.text = template['name'] as String;
//       _descCtrl.text = (template['description'] as String?) ?? '';
//     });
//     Navigator.of(context).pop();
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_isRecurrent &&
//         (_recurrenceType == 'semanal' || _recurrenceType == 'personalizada') &&
//         _selectedDays.isEmpty) {
//       _showError('Selecciona al menos un día');
//       return;
//     }

//     if (_wantFoints && _currentFointsToday >= _maxFointsPerDay) {
//       _showError('Ya tienes $_maxFointsPerDay tareas con Foints hoy');
//       return;
//     }

//     setState(() => _loading = true);

//     final recurrenceDays = _selectedDays.isNotEmpty
//         ? (_selectedDays.toList()..sort())
//         : null;

//     final ok = await context.read<TaskProvider>().createTask(
//       name: _nameCtrl.text.trim(),
//       description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
//       isUrgent: _isUrgent,
//       scheduledDate: _scheduledDate.toIso8601String(),
//       notificationType: _notifType,
//       isRecurrent: _isRecurrent,
//       recurrenceType: _isRecurrent ? _recurrenceType : 'ninguna',
//       recurrenceDays: recurrenceDays?.join(','),
//       recurrenceEndDate: _recurrenceEnd?.toIso8601String().split('T').first,
//       idTaskTemplate: _wantFoints && _selectedTemplate != null
//           ? _selectedTemplate!['id'] as int?
//           : null,
//     );

//     if (!mounted) return;
//     setState(() => _loading = false);

//     if (ok) {
//       context.go('/home');
//     } else {
//       final error = context.read<TaskProvider>().error;
//       _showError(error ?? 'Error al crear la tarea');
//     }
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: AppColors.error,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: FadeTransition(
//           opacity: _fadeAnim,
//           child: Column(
//             children: [
//               // ── Header ─────────────────────────────────────────────────
//               _buildHeader(),
//               // ── Body ───────────────────────────────────────────────────
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 20),

//                         // ── Origen de la tarea ──────────────────────────
//                         _TaskSourceSelector(
//                           fromTemplate: _fromTemplate,
//                           selectedTemplate: _selectedTemplate,
//                           onFromTemplateChanged: (val) {
//                             setState(() {
//                               _fromTemplate = val;
//                               if (!val) {
//                                 _selectedTemplate = null;
//                                 _wantFoints = false;
//                               }
//                             });
//                           },
//                           onSelectTemplate: () async {
//                             final result = await Navigator.of(context)
//                                 .push<Map<String, dynamic>>(
//                                   MaterialPageRoute(
//                                     builder: (_) => _TemplatePickerSheet(
//                                       onSelected: _onTemplateSelected,
//                                     ),
//                                   ),
//                                 );
//                             if (result != null) {
//                               _onTemplateSelected(result);
//                             }
//                           },
//                         ),

//                         const SizedBox(height: 20),

//                         // ── Nombre ─────────────────────────────────────
//                         _SectionLabel(
//                           label: 'Nombre de la tarea',
//                           icon: Icons.title_rounded,
//                         ),
//                         const SizedBox(height: 8),
//                         _StyledTextField(
//                           controller: _nameCtrl,
//                           hintText: 'Ej: Ir al gimnasio',
//                           validator: (v) => v == null || v.trim().isEmpty
//                               ? 'El nombre es obligatorio'
//                               : null,
//                         ),

//                         const SizedBox(height: 20),

//                         // ── Descripción ────────────────────────────────
//                         _SectionLabel(
//                           label: 'Descripción (opcional)',
//                           icon: Icons.notes_rounded,
//                         ),
//                         const SizedBox(height: 8),
//                         _StyledTextField(
//                           controller: _descCtrl,
//                           hintText: 'Agrega detalles...',
//                           maxLines: 3,
//                         ),

//                         const SizedBox(height: 20),

//                         // ── Fecha y hora ───────────────────────────────
//                         _SectionLabel(
//                           label: 'Fecha y hora',
//                           icon: Icons.calendar_today_rounded,
//                         ),
//                         const SizedBox(height: 8),
//                         _DateTimePicker(
//                           formattedValue: _formatDateTime(_scheduledDate),
//                           onTap: _pickDateTime,
//                         ),

//                         const SizedBox(height: 20),

//                         // ── Notificación ───────────────────────────────
//                         _SectionLabel(
//                           label: 'Tipo de notificación',
//                           icon: Icons.notifications_outlined,
//                         ),
//                         const SizedBox(height: 8),
//                         _NotifSelector(
//                           selected: _notifType,
//                           options: _notifTypes,
//                           onChanged: (v) => setState(() => _notifType = v),
//                         ),

//                         const SizedBox(height: 24),

//                         // ── Opciones: Urgente / Foints / Recurrente ────
//                         _OptionsSection(
//                           isUrgent: _isUrgent,
//                           isRecurrent: _isRecurrent,
//                           wantFoints: _wantFoints,
//                           canAddFoints: _canAddFoints,
//                           fromTemplate: _fromTemplate,
//                           selectedTemplate: _selectedTemplate,
//                           currentFointsToday: _currentFointsToday,
//                           maxFoints: _maxFointsPerDay,
//                           onUrgentChanged: (v) {
//                             setState(() {
//                               _isUrgent = v;
//                               if (v) {
//                                 _isRecurrent = false;
//                                 _wantFoints = false;
//                               }
//                             });
//                           },
//                           onFointsChanged: (v) {
//                             setState(() => _wantFoints = v);
//                           },
//                           onRecurrentChanged: (v) {
//                             setState(() {
//                               _isRecurrent = v;
//                               if (!v) {
//                                 _recurrenceType = 'ninguna';
//                                 _selectedDays.clear();
//                                 _recurrenceEnd = null;
//                               } else {
//                                 _recurrenceType = 'diaria';
//                               }
//                             });
//                           },
//                         ),

//                         // ── Recurrencia detail ─────────────────────────
//                         if (_isRecurrent) ...[
//                           const SizedBox(height: 20),
//                           _RecurrenceDetail(
//                             recurrenceType: _recurrenceType,
//                             selectedDays: _selectedDays,
//                             recurrenceEnd: _recurrenceEnd,
//                             recurrenceTypes: _recurrenceTypes,
//                             dayLabels: _dayLabels,
//                             onTypeChanged: (v) {
//                               setState(() {
//                                 _recurrenceType = v;
//                                 _selectedDays.clear();
//                               });
//                             },
//                             onDayToggled: (day) {
//                               setState(() {
//                                 if (_selectedDays.contains(day)) {
//                                   _selectedDays.remove(day);
//                                 } else {
//                                   _selectedDays.add(day);
//                                 }
//                               });
//                             },
//                             onPickEnd: _pickRecurrenceEnd,
//                             onClearEnd: () =>
//                                 setState(() => _recurrenceEnd = null),
//                           ),
//                         ],

//                         const SizedBox(height: 32),

//                         // ── Botón crear ────────────────────────────────
//                         _loading
//                             ? const Center(
//                                 child: CircularProgressIndicator(
//                                   color: AppColors.blueberry,
//                                 ),
//                               )
//                             : _CreateButton(onTap: _submit),

//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () => context.go('/home'),
//             child: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: AppColors.surface,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
//               ),
//               child: const Icon(
//                 Icons.arrow_back_ios_new_rounded,
//                 color: AppColors.textPrimary,
//                 size: 18,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           const Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Nueva tarea',
//                 style: TextStyle(
//                   color: AppColors.textPrimary,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w900,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               Text(
//                 'Configura los detalles de tu actividad',
//                 style: TextStyle(color: AppColors.grisTexto, fontSize: 12),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Task Source Selector ──────────────────────────────────────────────────────

// class _TaskSourceSelector extends StatelessWidget {
//   final bool fromTemplate;
//   final Map<String, dynamic>? selectedTemplate;
//   final ValueChanged<bool> onFromTemplateChanged;
//   final VoidCallback onSelectTemplate;

//   const _TaskSourceSelector({
//     required this.fromTemplate,
//     required this.selectedTemplate,
//     required this.onFromTemplateChanged,
//     required this.onSelectTemplate,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _SectionLabel(
//           label: 'Tipo de tarea',
//           icon: Icons.category_outlined,
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: _SourceChip(
//                 label: 'Personalizada',
//                 sublabel: 'Sin Foints',
//                 icon: Icons.edit_note_rounded,
//                 selected: !fromTemplate,
//                 color: AppColors.grisTexto,
//                 onTap: () => onFromTemplateChanged(false),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _SourceChip(
//                 label: 'De plantilla',
//                 sublabel: 'Gana Foints ⚡',
//                 icon: Icons.auto_awesome_rounded,
//                 selected: fromTemplate,
//                 color: AppColors.blueberry,
//                 onTap: () => onFromTemplateChanged(true),
//               ),
//             ),
//           ],
//         ),
//         if (fromTemplate) ...[
//           const SizedBox(height: 12),
//           GestureDetector(
//             onTap: onSelectTemplate,
//             child: Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: AppColors.blueberry.withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: selectedTemplate != null
//                       ? AppColors.blueberry.withOpacity(0.3)
//                       : AppColors.blueberry.withOpacity(0.2),
//                   width: 1.5,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       color: AppColors.blueberry.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Icon(
//                       Icons.list_alt_rounded,
//                       color: AppColors.blueberry,
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           selectedTemplate != null
//                               ? selectedTemplate!['name'] as String
//                               : 'Seleccionar plantilla',
//                           style: TextStyle(
//                             color: selectedTemplate != null
//                                 ? AppColors.textPrimary
//                                 : AppColors.grisTexto,
//                             fontWeight: FontWeight.w700,
//                             fontSize: 14,
//                           ),
//                         ),
//                         if (selectedTemplate != null)
//                           Text(
//                             '${selectedTemplate!['foints_base']} Foints base',
//                             style: const TextStyle(
//                               color: AppColors.blueberry,
//                               fontSize: 11,
//                             ),
//                           )
//                         else
//                           const Text(
//                             'Elige una actividad de la lista',
//                             style: TextStyle(
//                               color: AppColors.grisTexto,
//                               fontSize: 11,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   const Icon(
//                     Icons.chevron_right_rounded,
//                     color: AppColors.blueberry,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }

// class _SourceChip extends StatelessWidget {
//   final String label;
//   final String sublabel;
//   final IconData icon;
//   final bool selected;
//   final Color color;
//   final VoidCallback onTap;

//   const _SourceChip({
//     required this.label,
//     required this.sublabel,
//     required this.icon,
//     required this.selected,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: selected ? color.withOpacity(0.08) : AppColors.surface,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: selected
//                 ? color.withOpacity(0.4)
//                 : AppColors.lightBlue.withOpacity(0.3),
//             width: selected ? 1.5 : 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: selected ? color : AppColors.grisTexto, size: 22),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 color: selected ? AppColors.textPrimary : AppColors.grisTexto,
//                 fontWeight: FontWeight.w700,
//                 fontSize: 13,
//               ),
//             ),
//             Text(
//               sublabel,
//               style: TextStyle(
//                 color: selected ? color : AppColors.grisTexto,
//                 fontSize: 11,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Options Section ───────────────────────────────────────────────────────────

// class _OptionsSection extends StatelessWidget {
//   final bool isUrgent;
//   final bool isRecurrent;
//   final bool wantFoints;
//   final bool canAddFoints;
//   final bool fromTemplate;
//   final Map<String, dynamic>? selectedTemplate;
//   final int currentFointsToday;
//   final int maxFoints;
//   final ValueChanged<bool> onUrgentChanged;
//   final ValueChanged<bool> onFointsChanged;
//   final ValueChanged<bool> onRecurrentChanged;

//   const _OptionsSection({
//     required this.isUrgent,
//     required this.isRecurrent,
//     required this.wantFoints,
//     required this.canAddFoints,
//     required this.fromTemplate,
//     required this.selectedTemplate,
//     required this.currentFointsToday,
//     required this.maxFoints,
//     required this.onUrgentChanged,
//     required this.onFointsChanged,
//     required this.onRecurrentChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _SectionLabel(
//           label: 'Configuración adicional',
//           icon: Icons.tune_rounded,
//         ),
//         const SizedBox(height: 12),

//         // Urgente
//         _OptionTile(
//           icon: Icons.priority_high_rounded,
//           iconColor: AppColors.error,
//           title: 'Tarea urgente',
//           subtitle: 'No puede tener Foints ni ser recurrente',
//           value: isUrgent,
//           onChanged: onUrgentChanged,
//           activeColor: AppColors.error,
//         ),

//         const SizedBox(height: 10),

//         // Foints — solo si viene de plantilla y tiene plantilla seleccionada
//         if (fromTemplate && selectedTemplate != null) ...[
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: wantFoints && canAddFoints
//                   ? AppColors.blueberry.withOpacity(0.06)
//                   : !canAddFoints
//                   ? AppColors.grisTexto.withOpacity(0.05)
//                   : AppColors.surface,
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: wantFoints && canAddFoints
//                     ? AppColors.blueberry.withOpacity(0.25)
//                     : AppColors.lightBlue.withOpacity(0.3),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 38,
//                   height: 38,
//                   decoration: BoxDecoration(
//                     color: wantFoints && canAddFoints
//                         ? AppColors.blueberry.withOpacity(0.1)
//                         : AppColors.grisTexto.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     Icons.bolt_rounded,
//                     color: wantFoints && canAddFoints
//                         ? AppColors.blueberry
//                         : AppColors.grisTexto,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           const Text(
//                             'Obtener Foints',
//                             style: TextStyle(
//                               color: AppColors.textPrimary,
//                               fontWeight: FontWeight.w700,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: AppColors.blueberry.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: Text(
//                               '${selectedTemplate!['foints_base']} F',
//                               style: const TextStyle(
//                                 color: AppColors.blueberry,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       Text(
//                         canAddFoints
//                             ? 'Requerirá foto de confirmación ($currentFointsToday/$maxFoints hoy)'
//                             : 'Límite de $maxFoints tareas con Foints alcanzado hoy',
//                         style: TextStyle(
//                           color: canAddFoints
//                               ? AppColors.grisTexto
//                               : AppColors.error,
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Switch(
//                   value: wantFoints && canAddFoints,
//                   onChanged: canAddFoints && !isUrgent ? onFointsChanged : null,
//                   activeThumbColor: AppColors.blueberry,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//         ],

//         // Recurrente
//         if (!isUrgent)
//           _OptionTile(
//             icon: Icons.repeat_rounded,
//             iconColor: AppColors.accent,
//             title: 'Tarea recurrente',
//             subtitle: 'Se repetirá según la frecuencia elegida',
//             value: isRecurrent,
//             onChanged: onRecurrentChanged,
//             activeColor: AppColors.accent,
//           ),
//       ],
//     );
//   }
// }

// class _OptionTile extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final String title;
//   final String subtitle;
//   final bool value;
//   final ValueChanged<bool> onChanged;
//   final Color activeColor;

//   const _OptionTile({
//     required this.icon,
//     required this.iconColor,
//     required this.title,
//     required this.subtitle,
//     required this.value,
//     required this.onChanged,
//     required this.activeColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       decoration: BoxDecoration(
//         color: value ? iconColor.withOpacity(0.06) : AppColors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: value
//               ? iconColor.withOpacity(0.25)
//               : AppColors.lightBlue.withOpacity(0.3),
//         ),
//       ),
//       child: SwitchListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
//         secondary: Container(
//           width: 38,
//           height: 38,
//           decoration: BoxDecoration(
//             color: value
//                 ? iconColor.withOpacity(0.1)
//                 : AppColors.grisTexto.withOpacity(0.08),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(
//             icon,
//             color: value ? iconColor : AppColors.grisTexto,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(
//             color: AppColors.textPrimary,
//             fontWeight: FontWeight.w700,
//             fontSize: 14,
//           ),
//         ),
//         subtitle: Text(
//           subtitle,
//           style: const TextStyle(color: AppColors.grisTexto, fontSize: 11),
//         ),
//         value: value,
//         activeThumbColor: activeColor,
//         onChanged: onChanged,
//       ),
//     );
//   }
// }

// // ── Recurrence Detail ─────────────────────────────────────────────────────────

// class _RecurrenceDetail extends StatelessWidget {
//   final String recurrenceType;
//   final Set<int> selectedDays;
//   final DateTime? recurrenceEnd;
//   final List<Map<String, dynamic>> recurrenceTypes;
//   final List<String> dayLabels;
//   final ValueChanged<String> onTypeChanged;
//   final ValueChanged<int> onDayToggled;
//   final VoidCallback onPickEnd;
//   final VoidCallback onClearEnd;

//   const _RecurrenceDetail({
//     required this.recurrenceType,
//     required this.selectedDays,
//     required this.recurrenceEnd,
//     required this.recurrenceTypes,
//     required this.dayLabels,
//     required this.onTypeChanged,
//     required this.onDayToggled,
//     required this.onPickEnd,
//     required this.onClearEnd,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Frecuencia',
//             style: TextStyle(
//               color: AppColors.textPrimary,
//               fontWeight: FontWeight.w700,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 10),
//           // Chips de frecuencia
//           Wrap(
//             spacing: 8,
//             children: recurrenceTypes.where((r) => r['value'] != 'ninguna').map(
//               (r) {
//                 final selected = recurrenceType == r['value'];
//                 return GestureDetector(
//                   onTap: () => onTypeChanged(r['value'] as String),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 150),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: selected
//                           ? AppColors.blueberry
//                           : AppColors.background,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: selected
//                             ? AppColors.blueberry
//                             : AppColors.lightBlue.withOpacity(0.3),
//                       ),
//                     ),
//                     child: Text(
//                       r['label'] as String,
//                       style: TextStyle(
//                         color: selected ? Colors.white : AppColors.grisTexto,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ).toList(),
//           ),

//           // Selector de días
//           if (recurrenceType == 'semanal' ||
//               recurrenceType == 'personalizada') ...[
//             const SizedBox(height: 14),
//             const Text(
//               'Días',
//               style: TextStyle(
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(7, (i) {
//                 final day = i + 1;
//                 final selected = selectedDays.contains(day);
//                 return GestureDetector(
//                   onTap: () => onDayToggled(day),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 150),
//                     width: 38,
//                     height: 38,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: selected
//                           ? AppColors.blueberry
//                           : AppColors.background,
//                       border: Border.all(
//                         color: selected
//                             ? AppColors.blueberry
//                             : AppColors.lightBlue.withOpacity(0.3),
//                       ),
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                       dayLabels[i],
//                       style: TextStyle(
//                         color: selected ? Colors.white : AppColors.grisTexto,
//                         fontWeight: FontWeight.w700,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           ],

//           const SizedBox(height: 14),

//           // Fecha fin
//           GestureDetector(
//             onTap: onPickEnd,
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.event_busy_outlined,
//                   color: AppColors.grisTexto,
//                   size: 18,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     recurrenceEnd == null
//                         ? 'Sin fecha de fin (opcional)'
//                         : 'Hasta: ${recurrenceEnd!.day}/${recurrenceEnd!.month}/${recurrenceEnd!.year}',
//                     style: TextStyle(
//                       color: recurrenceEnd == null
//                           ? AppColors.grisTexto
//                           : AppColors.textPrimary,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//                 if (recurrenceEnd != null)
//                   GestureDetector(
//                     onTap: onClearEnd,
//                     child: const Icon(
//                       Icons.close,
//                       color: AppColors.grisTexto,
//                       size: 18,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Create Button ─────────────────────────────────────────────────────────────

// class _CreateButton extends StatelessWidget {
//   final VoidCallback onTap;
//   const _CreateButton({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         height: 54,
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [AppColors.blueberry, AppColors.midnight],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.blueberry.withOpacity(0.35),
//               blurRadius: 16,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.add_circle_outline_rounded,
//               color: Colors.white,
//               size: 20,
//             ),
//             SizedBox(width: 8),
//             Text(
//               'Crear tarea',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w800,
//                 fontSize: 16,
//                 letterSpacing: 0.2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Shared Widgets ────────────────────────────────────────────────────────────

// class _SectionLabel extends StatelessWidget {
//   final String label;
//   final IconData? icon;

//   const _SectionLabel({required this.label, this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: 16, color: AppColors.blueberry),
//           const SizedBox(width: 6),
//         ],
//         Text(
//           label,
//           style: const TextStyle(
//             color: AppColors.textPrimary,
//             fontWeight: FontWeight.w700,
//             fontSize: 13,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _StyledTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String hintText;
//   final int maxLines;
//   final String? Function(String?)? validator;

//   const _StyledTextField({
//     required this.controller,
//     required this.hintText,
//     this.maxLines = 1,
//     this.validator,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: controller,
//       maxLines: maxLines,
//       style: const TextStyle(
//         color: AppColors.textPrimary,
//         fontWeight: FontWeight.w500,
//       ),
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: TextStyle(
//           color: AppColors.grisTexto.withOpacity(0.6),
//           fontSize: 14,
//         ),
//         filled: true,
//         fillColor: AppColors.surface,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 14,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: AppColors.lightBlue.withOpacity(0.3)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: AppColors.lightBlue.withOpacity(0.3)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.blueberry, width: 1.5),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.error, width: 1.5),
//         ),
//       ),
//       validator: validator,
//     );
//   }
// }

// class _DateTimePicker extends StatelessWidget {
//   final String formattedValue;
//   final VoidCallback onTap;

//   const _DateTimePicker({required this.formattedValue, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
//         ),
//         child: Row(
//           children: [
//             const Icon(
//               Icons.calendar_today_outlined,
//               color: AppColors.blueberry,
//               size: 18,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               formattedValue,
//               style: const TextStyle(
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//             const Spacer(),
//             const Icon(
//               Icons.chevron_right_rounded,
//               color: AppColors.grisTexto,
//               size: 18,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NotifSelector extends StatelessWidget {
//   final String selected;
//   final List<String> options;
//   final ValueChanged<String> onChanged;

//   const _NotifSelector({
//     required this.selected,
//     required this.options,
//     required this.onChanged,
//   });

//   IconData _iconFor(String type) {
//     switch (type) {
//       case 'push':
//         return Icons.notifications_active_outlined;
//       case 'email':
//         return Icons.email_outlined;
//       default:
//         return Icons.notifications_off_outlined;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: options.map((opt) {
//         final sel = selected == opt;
//         return Expanded(
//           child: GestureDetector(
//             onTap: () => onChanged(opt),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 150),
//               margin: EdgeInsets.only(right: opt != options.last ? 8 : 0),
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: sel
//                     ? AppColors.blueberry.withOpacity(0.08)
//                     : AppColors.surface,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: sel
//                       ? AppColors.blueberry.withOpacity(0.4)
//                       : AppColors.lightBlue.withOpacity(0.3),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Icon(
//                     _iconFor(opt),
//                     color: sel ? AppColors.blueberry : AppColors.grisTexto,
//                     size: 20,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     opt.capitalize(),
//                     style: TextStyle(
//                       color: sel ? AppColors.blueberry : AppColors.grisTexto,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// extension _StringExt on String {
//   String capitalize() =>
//       isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
// }

// // ── Template Picker Sheet (pantalla modal) ────────────────────────────────────

// class _TemplatePickerSheet extends StatefulWidget {
//   final void Function(Map<String, dynamic>) onSelected;

//   const _TemplatePickerSheet({required this.onSelected});

//   @override
//   State<_TemplatePickerSheet> createState() => _TemplatePickerSheetState();
// }

// class _TemplatePickerSheetState extends State<_TemplatePickerSheet> {
//   String? _selectedCategory;

//   // Mock data — en prod viene del backend
//   final List<Map<String, dynamic>> _categories = [
//     {'id': 1, 'name': 'Salud', 'icon': '💊', 'color': 0xFFEA88B9},
//     {'id': 2, 'name': 'Deporte', 'icon': '🏋️', 'color': 0xFF5A4EDB},
//     {'id': 3, 'name': 'Mente', 'icon': '🧠', 'color': 0xFFBCBBF2},
//     {'id': 4, 'name': 'Social', 'icon': '🤝', 'color': 0xFFE4AAA2},
//     {'id': 5, 'name': 'Vida', 'icon': '🌱', 'color': 0xFF0F2C98},
//   ];

//   final Map<String, List<Map<String, dynamic>>> _templatesByCategory = {
//     'Salud': [
//       {
//         'id': 101,
//         'name': 'Beber 2L de agua',
//         'description': 'Hidratación diaria',
//         'foints_base': 50,
//       },
//       {
//         'id': 102,
//         'name': 'Tomar vitaminas',
//         'description': 'Suplementación diaria',
//         'foints_base': 30,
//       },
//       {
//         'id': 103,
//         'name': 'Dormir 8 horas',
//         'description': 'Descanso adecuado',
//         'foints_base': 80,
//       },
//     ],
//     'Deporte': [
//       {
//         'id': 201,
//         'name': 'Correr 5km',
//         'description': 'Cardio al aire libre',
//         'foints_base': 120,
//       },
//       {
//         'id': 202,
//         'name': 'Ir al gimnasio',
//         'description': 'Entrenamiento de fuerza',
//         'foints_base': 100,
//       },
//       {
//         'id': 203,
//         'name': 'Yoga 30 min',
//         'description': 'Flexibilidad y relajación',
//         'foints_base': 70,
//       },
//       {
//         'id': 204,
//         'name': 'Ciclismo',
//         'description': 'Cardio en bicicleta',
//         'foints_base': 110,
//       },
//     ],
//     'Mente': [
//       {
//         'id': 301,
//         'name': 'Meditar 10 min',
//         'description': 'Mindfulness diario',
//         'foints_base': 60,
//       },
//       {
//         'id': 302,
//         'name': 'Leer 30 min',
//         'description': 'Lectura habitual',
//         'foints_base': 50,
//       },
//       {
//         'id': 303,
//         'name': 'Aprender algo nuevo',
//         'description': 'Curso o tutorial',
//         'foints_base': 90,
//       },
//     ],
//     'Social': [
//       {
//         'id': 401,
//         'name': 'Llamar a un amigo',
//         'description': 'Mantener conexiones',
//         'foints_base': 40,
//       },
//       {
//         'id': 402,
//         'name': 'Ayudar a alguien',
//         'description': 'Voluntariado o apoyo',
//         'foints_base': 80,
//       },
//     ],
//     'Vida': [
//       {
//         'id': 501,
//         'name': 'Cocinar en casa',
//         'description': 'Alimentación saludable',
//         'foints_base': 60,
//       },
//       {
//         'id': 502,
//         'name': 'Ordenar habitación',
//         'description': 'Hábito de organización',
//         'foints_base': 40,
//       },
//       {
//         'id': 503,
//         'name': 'Practicar gratitud',
//         'description': 'Escribir 3 cosas positivas',
//         'foints_base': 30,
//       },
//     ],
//   };

//   @override
//   Widget build(BuildContext context) {
//     final templates = _selectedCategory != null
//         ? (_templatesByCategory[_selectedCategory] ?? [])
//         : [];

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.of(context).pop(),
//                     child: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: AppColors.surface,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: AppColors.lightBlue.withOpacity(0.3),
//                         ),
//                       ),
//                       child: const Icon(
//                         Icons.arrow_back_ios_new_rounded,
//                         color: AppColors.textPrimary,
//                         size: 18,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Plantillas de tareas',
//                         style: TextStyle(
//                           color: AppColors.textPrimary,
//                           fontSize: 20,
//                           fontWeight: FontWeight.w900,
//                         ),
//                       ),
//                       Text(
//                         'Elige una actividad y gana Foints ⚡',
//                         style: TextStyle(
//                           color: AppColors.grisTexto,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Categorías horizontales
//             SizedBox(
//               height: 100,
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _categories.length,
//                 itemBuilder: (_, i) {
//                   final cat = _categories[i];
//                   final sel = _selectedCategory == cat['name'];
//                   final color = Color(cat['color'] as int);
//                   return GestureDetector(
//                     onTap: () => setState(
//                       () => _selectedCategory = cat['name'] as String,
//                     ),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       width: 80,
//                       margin: const EdgeInsets.only(right: 12),
//                       decoration: BoxDecoration(
//                         color: sel ? color : AppColors.surface,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: sel
//                               ? color
//                               : AppColors.lightBlue.withOpacity(0.3),
//                           width: sel ? 0 : 1,
//                         ),
//                         boxShadow: sel
//                             ? [
//                                 BoxShadow(
//                                   color: color.withOpacity(0.3),
//                                   blurRadius: 12,
//                                   offset: const Offset(0, 4),
//                                 ),
//                               ]
//                             : null,
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             cat['icon'] as String,
//                             style: const TextStyle(fontSize: 26),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             cat['name'] as String,
//                             style: TextStyle(
//                               color: sel ? Colors.white : AppColors.textPrimary,
//                               fontWeight: FontWeight.w700,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Lista de plantillas
//             Expanded(
//               child: _selectedCategory == null
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text('👆', style: TextStyle(fontSize: 40)),
//                           const SizedBox(height: 12),
//                           const Text(
//                             'Selecciona una categoría',
//                             style: TextStyle(
//                               color: AppColors.textPrimary,
//                               fontWeight: FontWeight.w700,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           const Text(
//                             'para ver las tareas disponibles',
//                             style: TextStyle(
//                               color: AppColors.grisTexto,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.builder(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//                       itemCount: templates.length,
//                       itemBuilder: (_, i) {
//                         final t = templates[i];
//                         return GestureDetector(
//                           onTap: () => widget.onSelected(t),
//                           child: Container(
//                             margin: const EdgeInsets.only(bottom: 12),
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: AppColors.surface,
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(
//                                 color: AppColors.lightBlue.withOpacity(0.3),
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 46,
//                                   height: 46,
//                                   decoration: BoxDecoration(
//                                     color: AppColors.blueberry.withOpacity(
//                                       0.08,
//                                     ),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: const Icon(
//                                     Icons.fitness_center_rounded,
//                                     color: AppColors.blueberry,
//                                     size: 22,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 14),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         t['name'] as String,
//                                         style: const TextStyle(
//                                           color: AppColors.textPrimary,
//                                           fontWeight: FontWeight.w700,
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 2),
//                                       Text(
//                                         t['description'] as String,
//                                         style: const TextStyle(
//                                           color: AppColors.grisTexto,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 6,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.blueberry.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       const Text(
//                                         '⚡',
//                                         style: TextStyle(fontSize: 14),
//                                       ),
//                                       Text(
//                                         '${t['foints_base']}F',
//                                         style: const TextStyle(
//                                           color: AppColors.blueberry,
//                                           fontWeight: FontWeight.w800,
//                                           fontSize: 11,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
