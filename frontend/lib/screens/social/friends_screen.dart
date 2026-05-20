import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/follow_provider.dart';
import '../../models/users.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Amigos y seguidores'),
        bottom: TabBar(
          controller: _tabController,
          labelStyle:   tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: tt.labelMedium,
          indicatorColor: cs.primary,
          labelColor:     cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Amigos'),
            Tab(text: 'Seguidores'),
            Tab(text: 'Siguiendo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendsTab(),
          _FollowersTab(),
          _FollowingTab(),
        ],
      ),
    );
  }
}

// ── Tab: Amigos mutuos ────────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    final followProv = context.watch<FollowProvider>();

    if (followProv.loadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (followProv.friends.isEmpty) {
      return const _EmptyState(
        icon:    Icons.people_outline_rounded,
        title:   'Sin amigos todavía',
        message: 'Cuando alguien te siga de vuelta, aparecerá aquí como amigo.',
      );
    }

    return _UserList(
      users: followProv.friends,
      itemBuilder: (user) => _FriendTile(user: user),
    );
  }
}

// ── Tab: Seguidores ───────────────────────────────────────────────────────────

class _FollowersTab extends StatelessWidget {
  const _FollowersTab();

  @override
  Widget build(BuildContext context) {
    final followProv = context.watch<FollowProvider>();

    if (followProv.loadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (followProv.followers.isEmpty) {
      return const _EmptyState(
        icon:    Icons.person_add_outlined,
        title:   'Aún no tienes seguidores',
        message: 'Cuando alguien empiece a seguirte, aparecerá aquí.',
      );
    }

    return _UserList(
      users: followProv.followers,
      itemBuilder: (user) => _FollowerTile(user: user),
    );
  }
}

// ── Tab: Siguiendo ────────────────────────────────────────────────────────────

class _FollowingTab extends StatelessWidget {
  const _FollowingTab();

  @override
  Widget build(BuildContext context) {
    final followProv = context.watch<FollowProvider>();

    if (followProv.loadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (followProv.following.isEmpty) {
      return const _EmptyState(
        icon:    Icons.person_search_rounded,
        title:   'No sigues a nadie',
        message: 'Busca usuarios y empieza a seguirlos.',
        actionLabel: 'Buscar usuarios',
        actionRoute: '/search',
      );
    }

    return _UserList(
      users: followProv.following,
      itemBuilder: (user) => _FollowingTile(user: user),
    );
  }
}

// ── Lista genérica ────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final List<User>           users;
  final Widget Function(User) itemBuilder;

  const _UserList({required this.users, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FollowProvider>().loadAll(),
      child: ListView.separated(
        padding:          const EdgeInsets.symmetric(vertical: 8),
        itemCount:        users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder:      (_, i) => itemBuilder(users[i]),
      ),
    );
  }
}

// ── Tile: Amigo (seguimiento mutuo) ──────────────────────────────────────────

class _FriendTile extends StatelessWidget {
  final User user;
  const _FriendTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _BaseTile(
      user: user,
      trailing: _UnfollowButton(
        userId: user.idUser,
        label:  'Amigo',
        isAmigo: true,
      ),
    );
  }
}

// ── Tile: Seguidor ────────────────────────────────────────────────────────────

class _FollowerTile extends StatelessWidget {
  final User user;
  const _FollowerTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final followProv  = context.watch<FollowProvider>();
    final isFollowing = followProv.isFollowing(user.idUser);

    return _BaseTile(
      user: user,
      trailing: _RemoveOrFollowBackButton(
        userId:      user.idUser,
        isFollowing: isFollowing,
      ),
    );
  }
}

// ── Tile: Siguiendo ───────────────────────────────────────────────────────────

class _FollowingTile extends StatelessWidget {
  final User user;
  const _FollowingTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      user: user,
      trailing: _UnfollowButton(
        userId:  user.idUser,
        label:   'Siguiendo',
        isAmigo: false,
      ),
    );
  }
}

// ── Tile base ─────────────────────────────────────────────────────────────────

class _BaseTile extends StatelessWidget {
  final User    user;
  final Widget  trailing;

  const _BaseTile({required this.user, required this.trailing});

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
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/user/${user.username}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _Avatar(name: user.name, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name} ${user.lastname}'.trim(),
                        style: tt.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botón: Dejar de seguir (usado en Amigos y Siguiendo) ──────────────────────

class _UnfollowButton extends StatefulWidget {
  final int    userId;
  final String label;
  final bool   isAmigo;

  const _UnfollowButton({
    required this.userId,
    required this.label,
    required this.isAmigo,
  });

  @override
  State<_UnfollowButton> createState() => _UnfollowButtonState();
}

class _UnfollowButtonState extends State<_UnfollowButton> {
  bool _loading = false;

  Future<void> _unfollow() async {
    // Confirmación antes de dejar de seguir
    final confirmed = await _showConfirm();
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    await context.read<FollowProvider>().unfollowUser(widget.userId);
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _showConfirm() async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return await showModalBottomSheet<bool>(
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
                Text(
                  widget.isAmigo
                      ? 'Dejar de seguir a esta persona también eliminará la amistad.'
                      : '¿Dejar de seguir a @${_getUsernameFromContext()}?',
                  style: tt.bodyMedium?.copyWith(
                    color:  cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        ),
                        child: const Text('Dejar de seguir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  // Busca el username del usuario en la lista del provider para el mensaje
  String _getUsernameFromContext() {
    final prov = context.read<FollowProvider>();
    final match = [
      ...prov.following,
      ...prov.friends,
    ].where((u) => u.idUser == widget.userId).firstOrNull;
    return match?.username ?? 'este usuario';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return SizedBox(
        width:  20,
        height: 20,
        child:  CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
      );
    }

    return OutlinedButton(
      onPressed: _unfollow,
      style: OutlinedButton.styleFrom(
        padding:       const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize:   Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(widget.label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ── Botón: Eliminar seguidor o seguir de vuelta (tab Seguidores) ──────────────

class _RemoveOrFollowBackButton extends StatefulWidget {
  final int  userId;
  final bool isFollowing;

  const _RemoveOrFollowBackButton({
    required this.userId,
    required this.isFollowing,
  });

  @override
  State<_RemoveOrFollowBackButton> createState() =>
      _RemoveOrFollowBackButtonState();
}

class _RemoveOrFollowBackButtonState
    extends State<_RemoveOrFollowBackButton> {
  bool _loading = false;

  Future<void> _followBack() async {
    setState(() => _loading = true);
    await context.read<FollowProvider>().followUser(widget.userId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _remove() async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final confirmed = await showModalBottomSheet<bool>(
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
                Text(
                  'Esta persona dejará de seguirte. No se le notificará.',
                  style: tt.bodyMedium?.copyWith(
                    color:  cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;
    setState(() => _loading = true);
    await context.read<FollowProvider>().removeFollower(widget.userId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return SizedBox(
        width:  20,
        height: 20,
        child:  CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
      );
    }

    const compactStyle = OutlinedButton.styleFrom;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

    if (widget.isFollowing) {
      // Ya lo sigo de vuelta → es amigo, mostrar solo "Amigo"
      return OutlinedButton(
        onPressed: null, // acción de dejar de seguir está en el tab Amigos
        style: OutlinedButton.styleFrom(
          padding:       const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize:   Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:         shape,
        ),
        child: const Text('Amigo', style: TextStyle(fontSize: 12)),
      );
    }

    // No lo sigo → mostrar "Seguir" y opción de eliminar con menú
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _followBack,
          style: ElevatedButton.styleFrom(
            padding:       const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize:   Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:         shape,
          ),
          child: const Text('Seguir', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 6),
        // Menú de 3 puntos para "Eliminar seguidor"
        SizedBox(
          width:  32,
          height: 32,
          child: PopupMenuButton<String>(
            iconSize:  18,
            padding:   EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              if (v == 'remove') _remove();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_outlined,
                        size: 16, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      'Eliminar seguidor',
                      style: TextStyle(
                        color:    Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color:      cs.onPrimaryContainer,
            fontSize:   size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   message;
  final String?  actionLabel;
  final String?  actionRoute;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
  });

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
              child: Icon(icon, color: cs.onSurfaceVariant, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && actionRoute != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push(actionRoute!),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}