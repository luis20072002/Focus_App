import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_template.dart';

import '../../providers/task_provider.dart';
import '../../providers/template_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  final int? taskId;

  const CreateTaskScreen({super.key, this.taskId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Origen de la tarea
  bool           _fromTemplate    = false;
  TaskTemplate?  _selectedTemplate;

  // Opciones
  bool   _isFointCandidate = false;
  bool   _isUrgent         = false;
  bool   _isRecurrent      = false;
  String _notifType        = 'push';
  String _recurrenceType   = 'ninguna';

  DateTime  _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  DateTime? _recurrenceEnd;

  final Set<int>    _selectedDays = {};
  final List<String> _dayLabels   = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  bool _loading = false;

  static const int _maxFointsPerDay = 3;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<TemplateProvider>().loadAll();
    if (widget.taskId != null) _preloadTask();
  });
}

void _preloadTask() {
  final prov = context.read<TaskProvider>();
  final task = [
    ...prov.todayTasks,
    ...prov.calendarTasks,
  ].where((t) => t.idTask == widget.taskId).firstOrNull;

  if (task == null) return;

  _nameCtrl.text = task.name;
  _descCtrl.text = task.description ?? '';
  _isUrgent        = task.isUrgent;
  _isRecurrent     = task.isRecurrent;
  _notifType       = task.notificationType;
  _isFointCandidate = task.isFointCandidate;
  _scheduledDate   = DateTime.parse(task.scheduledDate).toLocal();
  _recurrenceType  = task.isRecurrent ? task.recurrenceType : 'ninguna';

  if (task.recurrenceDays != null) {
    _selectedDays.addAll(
      task.recurrenceDays!.split(',').map(int.parse),
    );
  }
  if (task.recurrenceEndDate != null) {
    _recurrenceEnd = DateTime.tryParse(task.recurrenceEndDate!);
  }
  if (task.idTaskTemplate != null) {
    _fromTemplate = true;
    context.read<TemplateProvider>()
        .getTemplateById(task.idTaskTemplate!)
        .then((t) {
      if (t != null && mounted) {
        setState(() => _selectedTemplate = t);
      }
    });
  }

  setState(() {});
}

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int get _fointsTodayCount =>
      context.read<TaskProvider>().todayTasks
          .where((t) => t.isFointCandidate)
          .length;

  bool get _canAddFoints =>
      !_isUrgent && _fointsTodayCount < _maxFointsPerDay;

  String _formatDateTime(DateTime dt) {
    const meses = [
      'ene','feb','mar','abr','may','jun',
      'jul','ago','sep','oct','nov','dic',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${meses[dt.month - 1]} ${dt.year}  $h:$m';
  }

  // ── Date / time pickers ───────────────────────────────────────────────────

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledDate),
    );
    if (time == null) return;

    setState(() {
      _scheduledDate = DateTime(
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
    });
  }

  Future<void> _pickRecurrenceEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _recurrenceEnd = date);
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  if (_isRecurrent &&
      (_recurrenceType == 'semanal' || _recurrenceType == 'personalizada') &&
      _selectedDays.isEmpty) {
    _showError('Selecciona al menos un día de recurrencia');
    return;
  }

  if (_isFointCandidate && _selectedTemplate == null) {
    _showError('Selecciona una plantilla para obtener Foints');
    return;
  }

  setState(() => _loading = true);

  final bool ok;

  if (widget.taskId != null) {
    // ── Modo edición — solo envía campos que pueden cambiar ──────────
    ok = await context.read<TaskProvider>().updateTask(
      widget.taskId!,
      {
        'name':              _nameCtrl.text.trim(),
        'description':       _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'is_urgent':         _isUrgent,
        'scheduled_date':    _scheduledDate.toUtc().toIso8601String(),
        'notification_type': _notifType,
        'is_foint_candidate': _isFointCandidate,
        'is_recurrent':      _isRecurrent,
        'recurrence_type':   _isRecurrent ? _recurrenceType : 'ninguna',
        'recurrence_days':   _selectedDays.isNotEmpty
            ? (_selectedDays.toList()..sort()).join(',')
            : null,
        'recurrence_end_date': _recurrenceEnd
            ?.toIso8601String()
            .split('T')
            .first,
        'id_task_template':  _selectedTemplate?.idTaskTemplate,
      },
    );
  } else {
    // ── Modo creación ────────────────────────────────────────────────
    ok = await context.read<TaskProvider>().createTask(
      name:              _nameCtrl.text.trim(),
      description:       _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      isUrgent:          _isUrgent,
      scheduledDate:     _scheduledDate.toUtc().toIso8601String(),
      notificationType:  _notifType,
      isFointCandidate:  _isFointCandidate,
      isRecurrent:       _isRecurrent,
      recurrenceType:    _isRecurrent ? _recurrenceType : 'ninguna',
      recurrenceDays:    _selectedDays.isNotEmpty
          ? (_selectedDays.toList()..sort()).join(',')
          : null,
      recurrenceEndDate: _recurrenceEnd
          ?.toIso8601String()
          .split('T')
          .first,
      idTaskTemplate:    _selectedTemplate?.idTaskTemplate,
    );
  }

  if (!mounted) return;
  setState(() => _loading = false);

  if (ok) {
    context.go('/home');
  } else {
    _showError(
      context.read<TaskProvider>().error ??
          (widget.taskId != null
              ? 'Error al editar la tarea'
              : 'Error al crear la tarea'),
    );
  }
}
void _showError(String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            _buildHeader(context),

            // ── Formulario ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── Tipo de tarea ─────────────────────────────
                      _SectionLabel(
                        label: 'Tipo de tarea',
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 10),
                      _SourceSelector(
                        fromTemplate:   _fromTemplate,
                        selectedTemplate: _selectedTemplate,
                        onFromTemplateChanged: (val) {
                          setState(() {
                            _fromTemplate      = val;
                            _selectedTemplate  = null;
                            _isFointCandidate  = false;
                          });
                          if (val) {
                            context.read<TemplateProvider>().loadAll();
                          }
                        },
                        onSelectTemplate: _openTemplatePicker,
                      ),

                      const SizedBox(height: 20),

                      // ── Nombre ────────────────────────────────────
                      _SectionLabel(
                        label: 'Nombre de la tarea',
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ej: Ir al gimnasio',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'El nombre es obligatorio'
                            : null,
                      ),

                      const SizedBox(height: 20),

                      // ── Descripción ───────────────────────────────
                      _SectionLabel(
                        label: 'Descripción (opcional)',
                        icon: Icons.notes_rounded,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Agrega detalles...',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Fecha y hora ──────────────────────────────
                      _SectionLabel(
                        label: 'Fecha y hora',
                        icon: Icons.calendar_today_rounded,
                      ),
                      const SizedBox(height: 8),
                      _DateTimeTile(
                        value: _formatDateTime(_scheduledDate),
                        onTap:  _pickDateTime,
                      ),

                      const SizedBox(height: 20),

                      // ── Notificación ──────────────────────────────
                      _SectionLabel(
                        label: 'Notificación',
                        icon: Icons.notifications_outlined,
                      ),
                      const SizedBox(height: 8),
                      _NotifSelector(
                        selected:  _notifType,
                        onChanged: (v) => setState(() => _notifType = v),
                      ),

                      const SizedBox(height: 24),

                      // ── Opciones ──────────────────────────────────
                      _SectionLabel(
                        label: 'Opciones',
                        icon: Icons.tune_rounded,
                      ),
                      const SizedBox(height: 12),

                      // Urgente
                      _OptionTile(
                        icon:      Icons.priority_high_rounded,
                        iconColor: colors.error,
                        title:     'Urgente',
                        subtitle:  'No puede tener Foints ni ser recurrente',
                        value:     _isUrgent,
                        onChanged: (v) => setState(() {
                          _isUrgent = v;
                          if (v) {
                            _isRecurrent      = false;
                            _isFointCandidate = false;
                          }
                        }),
                      ),

                      const SizedBox(height: 10),

                      // Foints — solo si viene de plantilla
                      if (_fromTemplate && _selectedTemplate != null) ...[
                        _FointsTile(
                          canAdd:        _canAddFoints,
                          isActive:      _isFointCandidate,
                          fointsBase:    _selectedTemplate!.fointsBase,
                          countToday:    _fointsTodayCount,
                          maxPerDay:     _maxFointsPerDay,
                          onChanged: (v) => setState(() => _isFointCandidate = v),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Recurrente
                      if (!_isUrgent)
                        _OptionTile(
                          icon:      Icons.repeat_rounded,
                          iconColor: colors.primary,
                          title:     'Recurrente',
                          subtitle:  'Se repetirá según la frecuencia elegida',
                          value:     _isRecurrent,
                          onChanged: (v) => setState(() {
                            _isRecurrent = v;
                            if (!v) {
                              _recurrenceType = 'ninguna';
                              _selectedDays.clear();
                              _recurrenceEnd = null;
                            } else {
                              _recurrenceType = 'diaria';
                            }
                          }),
                        ),

                      // Detalle de recurrencia
                      if (_isRecurrent) ...[
                        const SizedBox(height: 20),
                        _RecurrenceDetail(
                          recurrenceType: _recurrenceType,
                          selectedDays:   _selectedDays,
                          recurrenceEnd:  _recurrenceEnd,
                          dayLabels:      _dayLabels,
                          onTypeChanged:  (v) => setState(() {
                            _recurrenceType = v;
                            _selectedDays.clear();
                          }),
                          onDayToggled:   (day) => setState(() {
                            if (_selectedDays.contains(day)) {
                              _selectedDays.remove(day);
                            } else {
                              _selectedDays.add(day);
                            }
                          }),
                          onPickEnd:  _pickRecurrenceEnd,
                          onClearEnd: () => setState(() => _recurrenceEnd = null),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Botón crear ───────────────────────────────
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _submit,
                                icon:  const Icon(Icons.add_circle_outline_rounded),
                                label: const Text('Crear tarea'),
                              ),
                            ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.onSurface,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.taskId != null ? 'Editar tarea' : 'Nueva tarea',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                widget.taskId != null
                    ? 'Modifica los detalles de tu actividad'
                    : 'Configura los detalles de tu actividad',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Template picker ─────────────────────────────────────────────────────────

  void _openTemplatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TemplateProvider>(),
        child: _TemplatePickerSheet(
          onSelected: (template) {
            setState(() {
              _selectedTemplate = template;
              _nameCtrl.text    = template.name;
              _descCtrl.text    = template.description ?? '';
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

// ── Selector de origen ────────────────────────────────────────────────────────

class _SourceSelector extends StatelessWidget {
  final bool fromTemplate;
  final TaskTemplate? selectedTemplate;
  final ValueChanged<bool> onFromTemplateChanged;
  final VoidCallback onSelectTemplate;

  const _SourceSelector({
    required this.fromTemplate,
    required this.selectedTemplate,
    required this.onFromTemplateChanged,
    required this.onSelectTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SourceChip(
                label:    'Personalizada',
                sublabel: 'Sin Foints',
                icon:     Icons.edit_note_rounded,
                selected: !fromTemplate,
                color:    AppColors.grisTexto,
                onTap:    () => onFromTemplateChanged(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceChip(
                label:    'De plantilla',
                sublabel: 'Gana Foints ⚡',
                icon:     Icons.auto_awesome_rounded,
                selected: fromTemplate,
                color:    colors.primary,
                onTap:    () => onFromTemplateChanged(true),
              ),
            ),
          ],
        ),
        if (fromTemplate) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onSelectTemplate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedTemplate != null
                      ? colors.primary.withOpacity(0.3)
                      : colors.primary.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.list_alt_rounded,
                        color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedTemplate?.name ?? 'Seleccionar plantilla',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selectedTemplate != null
                                ? null
                                : AppColors.grisTexto,
                          ),
                        ),
                        if (selectedTemplate != null)
                          Text(
                            '${selectedTemplate!.fointsBase} Foints base',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                            ),
                          )
                        else
                          Text(
                            'Elige una actividad de la lista',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.primary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.4)
                : theme.colorScheme.outline.withOpacity(0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? color : AppColors.grisTexto, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? null : AppColors.grisTexto,
              ),
            ),
            Text(
              sublabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? color : AppColors.grisTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de Foints ────────────────────────────────────────────────────────────

class _FointsTile extends StatelessWidget {
  final bool canAdd;
  final bool isActive;
  final int fointsBase;
  final int countToday;
  final int maxPerDay;
  final ValueChanged<bool> onChanged;

  const _FointsTile({
    required this.canAdd,
    required this.isActive,
    required this.fointsBase,
    required this.countToday,
    required this.maxPerDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme  = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive && canAdd
            ? colors.primary.withOpacity(0.06)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive && canAdd
              ? colors.primary.withOpacity(0.25)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isActive && canAdd
                  ? colors.primary.withOpacity(0.1)
                  : AppColors.grisTexto.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: isActive && canAdd ? colors.primary : AppColors.grisTexto,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Obtener Foints',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$fointsBase F',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  canAdd
                      ? '$countToday/$maxPerDay usadas hoy'
                      : 'Límite de $maxPerDay tareas con Foints alcanzado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: canAdd ? null : colors.error,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value:     isActive && canAdd,
            onChanged: canAdd ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

// ── Option tile ───────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final bool     value;
  final ValueChanged<bool> onChanged;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value
            ? iconColor.withOpacity(0.06)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? iconColor.withOpacity(0.25)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: value
                ? iconColor.withOpacity(0.1)
                : AppColors.grisTexto.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: value ? iconColor : AppColors.grisTexto,
            size: 20,
          ),
        ),
        title: Text(title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        value:     value,
        onChanged: onChanged,
      ),
    );
  }
}

// ── Date time tile ────────────────────────────────────────────────────────────

class _DateTimeTile extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _DateTimeTile({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 12),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.grisTexto, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Notif selector ────────────────────────────────────────────────────────────

class _NotifSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _NotifSelector({required this.selected, required this.onChanged});

  static const _options = ['push', 'ninguna'];

  IconData _iconFor(String type) => type == 'push'
      ? Icons.notifications_active_outlined
      : Icons.notifications_off_outlined;

  String _labelFor(String type) => type == 'push' ? 'Push' : 'Ninguna';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: _options.map((opt) {
        final sel = selected == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                  right: opt != _options.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel
                    ? colors.primary.withOpacity(0.08)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? colors.primary.withOpacity(0.4)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _iconFor(opt),
                    color: sel ? colors.primary : AppColors.grisTexto,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labelFor(opt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: sel ? colors.primary : AppColors.grisTexto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Recurrence detail ─────────────────────────────────────────────────────────

class _RecurrenceDetail extends StatelessWidget {
  final String recurrenceType;
  final Set<int> selectedDays;
  final DateTime? recurrenceEnd;
  final List<String> dayLabels;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onDayToggled;
  final VoidCallback onPickEnd;
  final VoidCallback onClearEnd;

  const _RecurrenceDetail({
    required this.recurrenceType,
    required this.selectedDays,
    required this.recurrenceEnd,
    required this.dayLabels,
    required this.onTypeChanged,
    required this.onDayToggled,
    required this.onPickEnd,
    required this.onClearEnd,
  });

  static const _types = [
    {'value': 'diaria',        'label': 'Todos los días'},
    {'value': 'semanal',       'label': 'Semanal'},
    {'value': 'personalizada', 'label': 'Personalizada'},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme  = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frecuencia', style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 10),

          // Chips de frecuencia
          Wrap(
            spacing: 8,
            children: _types.map((r) {
              final sel = recurrenceType == r['value'];
              return GestureDetector(
                onTap: () => onTypeChanged(r['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? colors.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    r['label']!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: sel ? Colors.white : AppColors.grisTexto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Selector de días
          if (recurrenceType == 'semanal' ||
              recurrenceType == 'personalizada') ...[
            const SizedBox(height: 14),
            Text('Días', style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final day = i + 1;
                final sel = selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => onDayToggled(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? colors.primary : Colors.transparent,
                      border: Border.all(
                        color: sel
                            ? colors.primary
                            : theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabels[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: sel ? Colors.white : AppColors.grisTexto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 14),

          // Fecha fin
          GestureDetector(
            onTap: onPickEnd,
            child: Row(
              children: [
                Icon(Icons.event_busy_outlined,
                    color: AppColors.grisTexto, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recurrenceEnd == null
                        ? 'Sin fecha de fin (opcional)'
                        : 'Hasta: ${recurrenceEnd!.day}/${recurrenceEnd!.month}/${recurrenceEnd!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: recurrenceEnd == null
                          ? AppColors.grisTexto
                          : null,
                    ),
                  ),
                ),
                if (recurrenceEnd != null)
                  GestureDetector(
                    onTap: onClearEnd,
                    child: const Icon(Icons.close,
                        color: AppColors.grisTexto, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _SectionLabel({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
        ],
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

// ── Template picker sheet ─────────────────────────────────────────────────────

class _TemplatePickerSheet extends StatelessWidget {
  final ValueChanged<TaskTemplate> onSelected;

  const _TemplatePickerSheet({required this.onSelected});

  static const _categoryIcons = {
    'Salud':    '💊',
    'Deporte':  '🏋️',
    'Mente':    '🧠',
    'Social':   '🤝',
    'Vida':     '🌱',
  };

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final colors   = theme.colorScheme;
    final provider = context.watch<TemplateProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grisTexto.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plantillas de tareas',
                          style: theme.textTheme.titleLarge),
                      Text('Elige una actividad y gana Foints ⚡',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Categorías
          if (provider.loadingCategories)
            const LinearProgressIndicator()
          else
            SizedBox(
              height: 90,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: provider.categories.length,
                itemBuilder: (_, i) {
                  final cat = provider.categories[i];
                  final sel = provider.selectedCategory == cat.idCategory;
                  return GestureDetector(
                    onTap: () => provider.selectCategory(cat.idCategory),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? colors.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel
                              ? colors.primary
                              : theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _categoryIcons[cat.categoryName] ?? '📋',
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.categoryName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: sel ? Colors.white : null,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Plantillas
          Expanded(
            child: provider.loadingTemplates
                ? const Center(child: CircularProgressIndicator())
                : provider.selectedCategory == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('👆',
                                style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text('Selecciona una categoría',
                                style: theme.textTheme.titleSmall),
                            Text('para ver las tareas disponibles',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      )
                    : provider.filteredTemplates.isEmpty
                        ? Center(
                            child: Text('Sin plantillas disponibles',
                                style: theme.textTheme.bodySmall),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: provider.filteredTemplates.length,
                            itemBuilder: (_, i) {
                              final t = provider.filteredTemplates[i];
                              return GestureDetector(
                                onTap: () => onSelected(t),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46, height: 46,
                                        decoration: BoxDecoration(
                                          color: colors.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.fitness_center_rounded,
                                            color: colors.primary, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(t.name,
                                                style: theme.textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                )),
                                            if (t.description != null)
                                              Text(t.description!,
                                                  style:
                                                      theme.textTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              colors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('⚡',
                                                style:
                                                    TextStyle(fontSize: 14)),
                                            Text('${t.fointsBase}F',
                                                style: theme.textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: colors.primary,
                                                  fontWeight: FontWeight.w800,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}