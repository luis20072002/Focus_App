import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/follow_provider.dart';
import '../../models/users.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  // Debounce: espera 400 ms tras el último keystroke antes de buscar
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Carga el estado de following para saber a quién ya sigo
      context.read<FollowProvider>().loadFollowing();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      context.read<UserProvider>().clearSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<UserProvider>().searchUsers(query.trim());
    });
  }

  void _onClear() {
    _debounce?.cancel();
    _controller.clear();
    context.read<UserProvider>().clearSearch();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final userProv  = context.watch<UserProvider>();
    final results   = userProv.searchResults;
    final isLoading = userProv.loadingSearch;
    final hasQuery  = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            _debounce?.cancel();
            context.read<UserProvider>().clearSearch();
            context.pop();
          },
        ),
        title: _SearchBar(
          controller: _controller,
          focusNode:  _focusNode,
          onChanged:  _onSearch,
          onClear:    _onClear,
          hasQuery:   hasQuery,
        ),
        titleSpacing: 0,
      ),
      body: _buildBody(
        context:   context,
        cs:        cs,
        results:   results,
        isLoading: isLoading,
        hasQuery:  hasQuery,
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ColorScheme  cs,
    required List<User>   results,
    required bool         isLoading,
    required bool         hasQuery,
  }) {
    // Sin query todavía
    if (!hasQuery) {
      return const _EmptyPrompt(
        icon:    Icons.search_rounded,
        title:   'Busca personas',
        message: 'Encuentra usuarios por nombre, apellido o @username',
      );
    }

    // Cargando
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sin resultados
    if (results.isEmpty) {
      return _EmptyPrompt(
        icon:    Icons.person_off_outlined,
        title:   'Sin resultados',
        message: 'No encontramos usuarios para "${_controller.text.trim()}"',
      );
    }

    // Lista de resultados
    return ListView.separated(
      padding:          const EdgeInsets.symmetric(vertical: 8),
      itemCount:        results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder:      (_, i) => _UserTile(user: results[i]),
    );
  }
}

// ── Barra de búsqueda ─────────────────────────────────────────────────────────
// Usa InputBorder.none intencionalmente para integrarse en el AppBar.

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onClear;
  final bool                  hasQuery;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TextField(
      controller:      controller,
      focusNode:       focusNode,
      onChanged:       onChanged,
      textInputAction: TextInputAction.search,
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        hintText:       'Buscar usuarios...',
        // Bordes en none para que se vea limpia dentro del AppBar
        border:         InputBorder.none,
        enabledBorder:  InputBorder.none,
        focusedBorder:  InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        suffixIcon: hasQuery
            ? IconButton(
                icon:      Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }
}

// ── Tile de usuario ───────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final User user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final tt         = Theme.of(context).textTheme;
    final followProv = context.watch<FollowProvider>();
    final isFollowing = followProv.isFollowing(user.idUser);
    final isFriend    = followProv.isFriend(user.idUser);

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
                // Avatar
                _Avatar(name: user.name, size: 44),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${user.name} ${user.lastname}'.trim(),
                              style: tt.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFriend) ...[
                            const SizedBox(width: 6),
                            _Badge(label: 'Amigo', color: cs.primary),
                          ],
                        ],
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

                // Botón seguir / siguiendo
                _FollowButton(
                  userId:      user.idUser,
                  isFollowing: isFollowing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botón de seguir ───────────────────────────────────────────────────────────

class _FollowButton extends StatefulWidget {
  final int  userId;
  final bool isFollowing;

  const _FollowButton({required this.userId, required this.isFollowing});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    final prov = context.read<FollowProvider>();
    if (widget.isFollowing) {
      await prov.unfollowUser(widget.userId);
    } else {
      await prov.followUser(widget.userId);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final isFollowing = widget.isFollowing;

    if (_loading) {
      return SizedBox(
        width:  20,
        height: 20,
        child:  CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
      );
    }

    // Estilo compacto para caber en la fila — mínimos overrides del tema
    final compactShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    const compactPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    const compactText    = TextStyle(fontSize: 12);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isFollowing
          ? OutlinedButton(
              key:       const ValueKey('following'),
              onPressed: _toggle,
              style: OutlinedButton.styleFrom(
                padding:       compactPadding,
                minimumSize:   Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape:         compactShape,
              ),
              child: const Text('Siguiendo', style: compactText),
            )
          : ElevatedButton(
              key:       const ValueKey('follow'),
              onPressed: _toggle,
              style: ElevatedButton.styleFrom(
                padding:       compactPadding,
                minimumSize:   Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape:         compactShape,
              ),
              child: const Text('Seguir', style: compactText),
            ),
    );
  }
}

// ── Avatar genérico ───────────────────────────────────────────────────────────

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

// ── Badge pequeño ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontSize:   10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Prompt vacío ──────────────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   message;

  const _EmptyPrompt({
    required this.icon,
    required this.title,
    required this.message,
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
          ],
        ),
      ),
    );
  }
}