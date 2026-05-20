import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/follow_provider.dart';
import '../../models/users.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User?   _profileUser;
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    // Carga el perfil público y el estado de following en paralelo
    final results = await Future.wait([
      context.read<UserProvider>().getPublicProfile(widget.username),
      context.read<FollowProvider>().loadFollowing(),
    ]);

    if (!mounted) return;
    setState(() {
      _profileUser = results[0] as User?;
      _loading     = false;
      if (_profileUser == null) {
        _error = 'Usuario no encontrado';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _profileUser != null ? '@${_profileUser!.username}' : '',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(context, cs, tt),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme cs, TextTheme tt) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _profileUser == null) {
      return _ErrorState(
        message: _error ?? 'Error desconocido',
        onRetry: _load,
      );
    }

    return _ProfileContent(user: _profileUser!);
  }
}

// ── Contenido del perfil ──────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  final User user;
  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<UserProvider>().getPublicProfile(user.username),
          context.read<FollowProvider>().loadFollowing(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Tarjeta de perfil ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _ProfileCard(user: user),
                ),

                const SizedBox(height: 16),

                // ── Stats: seguidores / siguiendo / amigos ───────────────
                // Solo mostramos los conteos del propio User model.
                // Para un perfil público solo tenemos los Foints; los conteos
                // de follow no están en el endpoint GET /users/{username},
                // así que mostramos las métricas disponibles.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FointsStatsRow(user: user),
                ),

                const SizedBox(height: 24),

                // ── Botón seguir / siguiendo ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FollowActionButton(targetUserId: user.idUser),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de cabecera ───────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final User user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final fullName = '${user.name} ${user.lastname}'.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:      cs.primary.withOpacity(0.3),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width:  72,
            height: 72,
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
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre completo
                Text(
                  fullName.isNotEmpty ? fullName : user.username,
                  style: tt.titleLarge?.copyWith(
                    color:         Colors.white,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Username
                Text(
                  '@${user.username}',
                  style: tt.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                // Descripción si existe
                if (user.description != null &&
                    user.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.description!,
                    style: tt.bodySmall?.copyWith(
                      color:  Colors.white.withOpacity(0.8),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row de métricas (Foints) ──────────────────────────────────────────────────

class _FointsStatsRow extends StatelessWidget {
  final User user;
  const _FointsStatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon:      Icons.bolt_rounded,
            iconColor: cs.primary,
            iconBg:    cs.primary.withOpacity(0.1),
            label:     'Foints temporada',
            value:     '${user.fointsSeason}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon:      Icons.emoji_events_rounded,
            iconColor: cs.secondary,
            iconBg:    cs.secondary.withOpacity(0.12),
            label:     'Foints totales',
            value:     '${user.fointsTotal}',
          ),
        ),
      ],
    );
  }
}

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
            style: tt.headlineSmall?.copyWith(
              fontWeight:    FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: tt.labelSmall),
        ],
      ),
    );
  }
}

// ── Botón de seguir / dejar de seguir ─────────────────────────────────────────

class _FollowActionButton extends StatefulWidget {
  final int targetUserId;
  const _FollowActionButton({required this.targetUserId});

  @override
  State<_FollowActionButton> createState() => _FollowActionButtonState();
}

class _FollowActionButtonState extends State<_FollowActionButton> {
  bool _loading = false;

  Future<void> _toggle(bool currentlyFollowing) async {
    setState(() => _loading = true);
    final prov = context.read<FollowProvider>();
    if (currentlyFollowing) {
      await prov.unfollowUser(widget.targetUserId);
    } else {
      await prov.followUser(widget.targetUserId);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final followProv  = context.watch<FollowProvider>();
    final isFollowing = followProv.isFollowing(widget.targetUserId);
    final isFriend    = followProv.isFriend(widget.targetUserId);

    if (_loading) {
      return SizedBox(
        width:  double.infinity,
        height: 50,
        child: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    // Si son amigos, mostramos el estado especial
    if (isFriend) {
      return Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => _toggle(true),
            icon:  const Icon(Icons.people_rounded, size: 18),
            label: const Text('Amigos · Dejar de seguir'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Se siguen mutuamente',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (isFollowing) {
      return OutlinedButton.icon(
        onPressed: () => _toggle(true),
        icon:  const Icon(Icons.person_remove_outlined, size: 18),
        label: const Text('Siguiendo'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _toggle(false),
      icon:  const Icon(Icons.person_add_outlined, size: 18),
      label: const Text('Seguir'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
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

    // "Usuario no encontrado" tiene un estado vacío más amigable
    final isNotFound = message.toLowerCase().contains('no encontrado');

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
                color: isNotFound
                    ? cs.surfaceContainerHighest
                    : cs.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNotFound
                    ? Icons.person_off_outlined
                    : Icons.wifi_off_rounded,
                color: isNotFound ? cs.onSurfaceVariant : cs.error,
                size:  36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isNotFound ? 'Usuario no encontrado' : 'No se pudo cargar el perfil',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isNotFound
                  ? 'Este usuario no existe o fue eliminado.'
                  : message,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (!isNotFound) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon:  const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}