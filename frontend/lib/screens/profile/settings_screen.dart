import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final settings     = settingsProv.settings;
    final cs           = Theme.of(context).colorScheme;
    final tt           = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsProv.loading && settings == null
          ? const Center(child: CircularProgressIndicator())
          : settings == null
              ? _ErrorState(
                  message: settingsProv.error ?? 'No se pudo cargar la configuración',
                  onRetry: () => context.read<SettingsProvider>().loadSettings(),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 48),
                  children: [

                    // ── Sección: Entorno (RF-F25) ──────────────────────
                    _SectionLabel(label: 'Entorno'),

                    // Tema
                    _OptionTile(
                      icon:  Icons.palette_outlined,
                      label: 'Tema',
                      trailing: _ThemeToggle(
                        isDark:   settings.isDarkTheme,
                        onToggle: (isDark) {
                          context.read<SettingsProvider>().setTheme(
                            isDark ? 'oscuro' : 'claro',
                          );
                        },
                      ),
                    ),

                    // Idioma
                    _OptionTile(
                      icon:  Icons.language_rounded,
                      label: 'Idioma',
                      trailing: _LanguageChip(language: settings.language ?? 'es'),
                      onTap: () => _showLanguagePicker(context, settings.language ?? 'es'),
                    ),

                    const SizedBox(height: 8),

                    // ── Sección: Notificaciones (RF-F23) ───────────────
                    _SectionLabel(label: 'Notificaciones'),

                    // Master toggle — si está OFF, los demás quedan deshabilitados
                    _SwitchTile(
                      icon:     Icons.notifications_rounded,
                      label:    'Notificaciones push',
                      subtitle: 'Activar o desactivar todas las notificaciones',
                      value:    settings.notifPush,
                      onChanged: (v) =>
                          context.read<SettingsProvider>().setNotifPush(v),
                    ),

                    // Separador visual cuando están deshabilitadas
                    AnimatedOpacity(
                      opacity:  settings.notifPush ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 200),
                      child: AbsorbPointer(
                        absorbing: !settings.notifPush,
                        child: Column(
                          children: [
                            _SwitchTile(
                              icon:     Icons.alarm_rounded,
                              label:    'Recordatorio de tarea',
                              subtitle: 'Aviso antes de que empiece una tarea',
                              value:    settings.notifTaskReminder,
                              onChanged: (v) => context
                                  .read<SettingsProvider>()
                                  .updateSettings({'notif_task_reminder': v}),
                            ),

                            // Anticipación en minutos — solo si recordatorio activo
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: settings.notifTaskReminder
                                  ? _ReminderMinutesTile(
                                      minutes: settings.notifReminderMinutes,
                                      onChanged: (mins) => context
                                          .read<SettingsProvider>()
                                          .setReminderMinutes(mins),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            _SwitchTile(
                              icon:     Icons.timer_off_rounded,
                              label:    'Tarea vencida',
                              subtitle: 'Aviso cuando una tarea caduca sin completar',
                              value:    settings.notifTaskExpired,
                              onChanged: (v) => context
                                  .read<SettingsProvider>()
                                  .updateSettings({'notif_task_expired': v}),
                            ),

                            _SwitchTile(
                              icon:     Icons.priority_high_rounded,
                              label:    'Tarea urgente',
                              subtitle: 'Aviso cuando creas una tarea marcada como urgente',
                              value:    settings.notifUrgentTask,
                              onChanged: (v) => context
                                  .read<SettingsProvider>()
                                  .updateSettings({'notif_urgent_task': v}),
                            ),

                            _SwitchTile(
                              icon:     Icons.person_add_outlined,
                              label:    'Nuevo seguidor',
                              subtitle: 'Aviso cuando alguien empieza a seguirte',
                              value:    settings.notifNewFollower,
                              onChanged: (v) => context
                                  .read<SettingsProvider>()
                                  .updateSettings({'notif_new_follower': v}),
                            ),

                            _SwitchTile(
                              icon:     Icons.check_circle_outline_rounded,
                              label:    'Sugerencia resuelta',
                              subtitle: 'Aviso cuando tu sugerencia es aprobada o rechazada',
                              value:    settings.notifSuggestionResolved,
                              onChanged: (v) => context
                                  .read<SettingsProvider>()
                                  .updateSettings({'notif_suggestion_resolved': v}),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Aviso si hay error (no bloquea la UI — optimistic update revierte solo)
                    if (settingsProv.error != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _ErrorBanner(message: settingsProv.error!),
                      ),
                    ],
                  ],
                ),
    );
  }

  // ── Selector de idioma ───────────────────────────────────────────────────

  void _showLanguagePicker(BuildContext context, String current) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const languages = [
      ('es', 'Español'),
      ('en', 'English'),
    ];

    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin:  const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selecciona idioma', style: tt.titleMedium),
            const SizedBox(height: 16),
            ...languages.map(
              (lang) => ListTile(
                title: Text(lang.$2, style: tt.bodyMedium),
                trailing: current == lang.$1
                    ? Icon(Icons.check_rounded, color: cs.primary)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  context
                      .read<SettingsProvider>()
                      .updateSettings({'language': lang.$1});
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color:         cs.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight:    FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Tile genérico con trailing personalizable ─────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final Widget?   trailing;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width:  36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:        cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: cs.primary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: tt.titleSmall),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Switch tile ───────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   subtitle;
  final bool     value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color:        cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: tt.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile de minutos de anticipación ──────────────────────────────────────────

class _ReminderMinutesTile extends StatelessWidget {
  final int    minutes;
  final ValueChanged<int> onChanged;

  const _ReminderMinutesTile({
    required this.minutes,
    required this.onChanged,
  });

  // Opciones predefinidas: 5, 10, 15, 30, 60 minutos
  static const _options = [5, 10, 15, 30, 60];

  String _label(int m) =>
      m < 60 ? '$m min antes' : '${m ~/ 60} h antes';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      child: Container(
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anticipación del recordatorio',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _options.map((opt) {
                  final selected = opt == minutes;
                  return ChoiceChip(
                    label:    Text(_label(opt)),
                    selected: selected,
                    onSelected: (_) => onChanged(opt),
                    selectedColor:    cs.primary,
                    labelStyle: TextStyle(
                      color:      selected ? cs.onPrimary : cs.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle de tema ────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  final bool   isDark;
  final ValueChanged<bool> onToggle;

  const _ThemeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onToggle(!isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve:    Curves.easeInOut,
        width:    56,
        height:   30,
        decoration: BoxDecoration(
          color:        isDark ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: cs.outline.withOpacity(0.3),
          ),
        ),
        child: Stack(
          children: [
            // Icono sol
            Positioned(
              left: 6,
              top:  5,
              child: Icon(
                Icons.wb_sunny_rounded,
                size:  18,
                color: isDark
                    ? cs.onPrimary.withOpacity(0.4)
                    : Colors.amber,
              ),
            ),
            // Icono luna
            Positioned(
              right: 6,
              top:   5,
              child: Icon(
                Icons.nightlight_round,
                size:  18,
                color: isDark
                    ? cs.onPrimary
                    : cs.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
            // Píldora deslizante
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve:    Curves.easeInOut,
              left:     isDark ? 28 : 2,
              top:      2,
              child: Container(
                width:  26,
                height: 26,
                decoration: BoxDecoration(
                  color:        cs.surface,
                  shape:        BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset:     const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de idioma ────────────────────────────────────────────────────────────

class _LanguageChip extends StatelessWidget {
  final String language;
  const _LanguageChip({required this.language});

  static const _labels = {'es': '🇪🇸 Español', 'en': '🇬🇧 English'};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _labels[language] ?? language.toUpperCase(),
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded,
            size: 18, color: cs.onSurfaceVariant),
      ],
    );
  }
}

// ── Banner de error ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        cs.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No se pudo guardar: $message',
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado de error de carga ──────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: cs.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la configuración',
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}