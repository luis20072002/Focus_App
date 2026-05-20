import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final prov = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notificaciones'),
        actions: [
          if (prov.hasUnread)
            TextButton(
              onPressed: () => prov.markAllAsRead(),
              child: Text(
                'Marcar todas',
                style: TextStyle(
                  color:      cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, prov),
    );
  }

  Widget _buildBody(BuildContext context, NotificationProvider prov) {
    if (prov.loading && prov.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.error != null && prov.notifications.isEmpty) {
      return _ErrorState(
        message: prov.error!,
        onRetry: () => prov.loadNotifications(),
      );
    }

    if (prov.notifications.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => prov.loadNotifications(),
      child: ListView.separated(
        padding:          const EdgeInsets.symmetric(vertical: 8),
        itemCount:        prov.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (_, i) => _NotificationTile(
          notification: prov.notifications[i],
        ),
      ),
    );
  }
}

// ── Tile de notificación ──────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final tt   = Theme.of(context).textTheme;
    final prov = context.read<NotificationProvider>();
    final n    = notification;

    return Dismissible(
      key:            ValueKey(n.idNotification),
      direction:      DismissDirection.endToStart,
      background:     _DismissBackground(),
      confirmDismiss: (_) async {
        return await prov.deleteNotification(n.idNotification);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Material(
          color: n.read
              ? cs.surface
              : cs.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!n.read) prov.markAsRead(n.idNotification);
              _handleTap(context, n);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotifIcon(type: n.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.message,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: n.read
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(n.date),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!n.read) ...[
                    const SizedBox(width: 8),
                    Container(
                      width:  8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, NotificationModel n) {
    if (n.idReference == null) return;
    switch (n.type) {
      case NotificationType.taskReminder:
      case NotificationType.taskExpired:
      case NotificationType.urgentTask:
        context.push('/task/${n.idReference}');
        break;
      case NotificationType.newFollower:
      case NotificationType.suggestionResolved:
      case NotificationType.unknown:
        break;
    }
  }

  // n.date puede venir como String ISO desde el backend → parsear a DateTime
  String _formatDate(dynamic rawDate) {
    final DateTime date;
    if (rawDate is DateTime) {
      date = rawDate;
    } else {
      try {
        date = DateTime.parse(rawDate as String);
      } catch (_) {
        return '';
      }
    }

    final now  = DateTime.now();
    final diff = now.difference(date.toLocal());

    if (diff.inMinutes < 1)  return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays    < 7)  return 'Hace ${diff.inDays} días';

    final d = date.toLocal();
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${meses[d.month - 1]}';
  }
}

// ── Ícono por tipo ────────────────────────────────────────────────────────────

class _NotifIcon extends StatelessWidget {
  final NotificationType type;
  const _NotifIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (icon, color) = switch (type) {
      NotificationType.taskReminder       => (Icons.alarm_rounded,                  cs.primary),
      NotificationType.taskExpired        => (Icons.timer_off_rounded,               cs.error),
      NotificationType.urgentTask         => (Icons.priority_high_rounded,           cs.error),
      NotificationType.newFollower        => (Icons.person_add_outlined,             cs.primary),
      NotificationType.suggestionResolved => (Icons.check_circle_outline_rounded,    cs.secondary),
      NotificationType.unknown            => (Icons.notifications_none_rounded,      cs.onSurfaceVariant),
    };

    return Container(
      width:  40,
      height: 40,
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ── Fondo del swipe ───────────────────────────────────────────────────────────

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin:    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding:   const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color:        cs.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 22),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: cs.onSurfaceVariant,
                size:  32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin notificaciones',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Aquí aparecerán tus recordatorios, seguidores y avisos de tareas.',
              style:     tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                color: cs.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: cs.error, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar las notificaciones',
              style:     tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style:     tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
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