import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/follow_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadMe();
      context.read<FollowProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: _ProfileBody()),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final userProv   = context.watch<UserProvider>();
    final followProv = context.watch<FollowProvider>();
    final cs         = Theme.of(context).colorScheme;
    final tt         = Theme.of(context).textTheme;
    final user       = userProv.user;

    final fullName = user != null
        ? '${user.name} ${user.lastname}'.trim()
        : '';
    final username = user?.username ?? '';

    return RefreshIndicator(
      color:           cs.primary,
      backgroundColor: cs.surface,
      onRefresh: () async {
        await Future.wait([
          context.read<UserProvider>().loadMe(),
          context.read<FollowProvider>().loadAll(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Perfil',
                        style: tt.headlineLarge,
                      ),
                      Row(
                        children: [
                          _IconChip(
                            icon:  Icons.settings_outlined,
                            onTap: () => context.push('/settings'),
                          ),
                          const SizedBox(width: 8),
                          _IconChip(
                            icon:  Icons.edit_outlined,
                            onTap: () => context.push('/edit-profile'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Tarjeta principal ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _ProfileCard(
                    user:     user,
                    fullName: fullName,
                    username: username,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Stats de seguidores ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FollowStatsRow(followProv: followProv),
                ),

                const SizedBox(height: 16),

                // ── Stats de Foints ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon:      Icons.bolt_rounded,
                          iconColor: cs.primary,
                          iconBg:    cs.primary.withOpacity(0.1),
                          label:     'Foints temporada',
                          value:     '${user?.fointsSeason ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon:      Icons.emoji_events_rounded,
                          iconColor: AppColors.neutralOrange,
                          iconBg:    AppColors.neutralOrange.withOpacity(0.12),
                          label:     'Foints totales',
                          value:     '${user?.fointsTotal ?? 0}',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Sección: Cuenta ──────────────────────────────────────
                _SectionLabel(label: 'Cuenta'),
                _OptionTile(
                  icon:  Icons.person_outline_rounded,
                  label: 'Editar perfil',
                  onTap: () => context.push('/edit-profile'),
                ),
                _OptionTile(
                  icon:  Icons.people_outline_rounded,
                  label: 'Amigos y seguidores',
                  onTap: () => context.push('/friends'),
                ),
                _OptionTile(
                  icon:  Icons.search_rounded,
                  label: 'Buscar usuarios',
                  onTap: () => context.push('/search'),
                ),

                const SizedBox(height: 8),

                // ── Sección: Preferencias ────────────────────────────────
                _SectionLabel(label: 'Preferencias'),
                _OptionTile(
                  icon:  Icons.settings_outlined,
                  label: 'Configuración',
                  onTap: () => context.push('/settings'),
                ),
                _OptionTile(
                  icon:  Icons.notifications_none_rounded,
                  label: 'Notificaciones',
                  onTap: () => context.push('/notifications'),
                ),

                const SizedBox(height: 8),

                // ── Sección: Soporte ─────────────────────────────────────
                _SectionLabel(label: 'Soporte'),
                _OptionTile(
                  icon:  Icons.help_outline_rounded,
                  label: 'Ayuda',
                  onTap: () {},
                ),
                _OptionTile(
                  icon:  Icons.info_outline_rounded,
                  label: 'Acerca de',
                  onTap: () {},
                ),

                const SizedBox(height: 16),

                // ── Eliminar cuenta (RF-F28) ─────────────────────────────
                _OptionTile(
                  icon:      Icons.delete_outline_rounded,
                  label:     'Eliminar cuenta',
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap:     () => _confirmDeleteAccount(context),
                ),

                const SizedBox(height: 12),

                // ── Cerrar sesión (RF-F27) ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _LogoutButton(),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Diálogo: Eliminar cuenta (RF-F28) ────────────────────────────────────

  void _confirmDeleteAccount(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin:  const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: cs.error,
                size:  26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Eliminar cuenta',
              style: tt.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción es irreversible. Se eliminarán todos tus datos, tareas y Foints.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color:  cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final ok = await context
                          .read<UserProvider>()
                          .deleteAccount();
                      if (ok && context.mounted) {
                        await context.read<AuthProvider>().logout();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    ),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de perfil ─────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final String  fullName;
  final String  username;

  const _ProfileCard({
    required this.user,
    required this.fullName,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, AppColors.midnight],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:      cs.primary.withOpacity(0.35),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              color:  Colors.white.withOpacity(0.2),
              shape:  BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                user?.name?.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre completo
                Text(
                  fullName.isNotEmpty ? fullName : username,
                  style: tt.titleLarge?.copyWith(
                    color:         Colors.white,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Username
                Text(
                  '@$username',
                  style: tt.bodySmall?.copyWith(
                    color:      Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Descripción si existe
                if (user?.description != null &&
                    (user!.description as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    user!.description!,
                    style: tt.bodySmall?.copyWith(
                      color:  Colors.white.withOpacity(0.65),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Foints badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.lightBlue,
                        size:  13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user?.fointsTotal ?? 0} Foints totales',
                        style: TextStyle(
                          color:      Colors.white.withOpacity(0.9),
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

// ── Fila de stats de seguimiento (RF-F12) ────────────────────────────────────

class _FollowStatsRow extends StatelessWidget {
  final FollowProvider followProv;

  const _FollowStatsRow({required this.followProv});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _FollowStat(
            label: 'Seguidores',
            count: followProv.loadingFollowers
                ? null
                : followProv.followers.length,
            onTap: () => context.push('/friends'),
          ),
          _VerticalDivider(),
          _FollowStat(
            label: 'Siguiendo',
            count: followProv.loadingFollowing
                ? null
                : followProv.following.length,
            onTap: () => context.push('/friends'),
          ),
          _VerticalDivider(),
          _FollowStat(
            label: 'Amigos',
            count: followProv.loadingFriends
                ? null
                : followProv.friends.length,
            onTap: () => context.push('/friends'),
          ),
        ],
      ),
    );
  }
}

class _FollowStat extends StatelessWidget {
  final String onTap_label = '';
  final String  label;
  final int?    count;
  final VoidCallback onTap;

  const _FollowStat({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            count == null
                ? SizedBox(
                    width:  18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       cs.primary,
                    ),
                  )
                : Text(
                    '$count',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color:      cs.primary,
                    ),
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:  1,
      height: 32,
      color:  Theme.of(context).colorScheme.outline.withOpacity(0.4),
    );
  }
}

// ── Stat card de Foints ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   label;
  final String   value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              color:        iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: tt.displaySmall?.copyWith(
              fontWeight:    FontWeight.w900,
              letterSpacing: -0.5,
              fontSize:      22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ── Botón de cierre de sesión (RF-F27) ───────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  const _LogoutButton();

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _loading = false;

  Future<void> _logout() async {
    setState(() => _loading = true);
    await context.read<AuthProvider>().logout();
    if (mounted) setState(() => _loading = false);
  }

  void _confirmLogout() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin:  const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gum.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.gum,
                size:  26,
              ),
            ),
            const SizedBox(height: 16),
            Text('Cerrar sesión', style: tt.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Serás redirigido a la pantalla de bienvenida.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color:  cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gum,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _confirmLogout,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:        AppColors.gum.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gum.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width:  18,
                height: 18,
                child:  CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       AppColors.gum,
                ),
              )
            else
              const Icon(Icons.logout_rounded, color: AppColors.gum, size: 20),
            const SizedBox(width: 10),
            Text(
              _loading ? 'Cerrando sesión...' : 'Cerrar sesión',
              style: const TextStyle(
                color:      AppColors.gum,
                fontSize:   15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _IconChip extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;

  const _IconChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  40,
        height: 40,
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: cs.onSurface, size: 18),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
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

class _OptionTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final Widget?      trailing;
  final Color?       iconColor;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final tt          = Theme.of(context).textTheme;
    final resolvedColor = iconColor ?? cs.primary;

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
                  child: Icon(icon, color: resolvedColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: tt.titleSmall,
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                      size:  20,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}