import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _lastnameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _descCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;

    _nameCtrl     = TextEditingController(text: user?.name     ?? '');
    _lastnameCtrl = TextEditingController(text: user?.lastname ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _emailCtrl    = TextEditingController(text: user?.email    ?? '');
    _phoneCtrl    = TextEditingController(text: user?.phone    ?? '');
    _descCtrl     = TextEditingController(text: user?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastnameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Construye el Map con solo los campos que cambiaron ───────────────────
  Map<String, dynamic> _buildDiff() {
    final user   = context.read<UserProvider>().user;
    final fields = <String, dynamic>{};

    final name     = _nameCtrl.text.trim();
    final lastname = _lastnameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final desc     = _descCtrl.text.trim();

    if (name     != (user?.name     ?? '')) fields['name']        = name;
    if (lastname != (user?.lastname ?? '')) fields['lastname']     = lastname;
    if (username != (user?.username ?? '')) fields['username']     = username;
    if (email    != (user?.email    ?? '')) fields['email']        = email.isEmpty ? null : email;
    if (phone    != (user?.phone    ?? '')) fields['phone']        = phone.isEmpty ? null : phone;
    if (desc     != (user?.description ?? '')) fields['description'] = desc.isEmpty ? null : desc;

    return fields;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final diff = _buildDiff();
    if (diff.isEmpty) {
      // Nada cambió
      context.pop();
      return;
    }

    setState(() => _saving = true);

    final ok = await context.read<UserProvider>().updateMe(diff);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _showSnack('Perfil actualizado', isError: false);
      context.pop();
    } else {
      final err = context.read<UserProvider>().error ?? 'Error al guardar';
      _showSnack(err, isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? cs.error : cs.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _saving
                ? const SizedBox(
                    width:  20,
                    height: 20,
                    child:  CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _save,
                    child: Text(
                      'Guardar',
                      style: TextStyle(
                        color:      cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize:   15,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [

            // ── Avatar placeholder ───────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  _AvatarCircle(
                    initial: _nameCtrl.text.isNotEmpty
                        ? _nameCtrl.text[0].toUpperCase()
                        : '?',
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width:  28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:  cs.primary,
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size:  14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Sección: Información personal ────────────────────────────
            _SectionLabel(label: 'Información personal'),
            const SizedBox(height: 12),

            _Field(
              controller: _nameCtrl,
              label:      'Nombre',
              icon:       Icons.person_outline_rounded,
              validator:  (v) {
                if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                return null;
              },
              onChanged: (_) => setState(() {}), // refresca el avatar
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _lastnameCtrl,
              label:      'Apellido',
              icon:       Icons.person_outline_rounded,
              validator:  (v) {
                if (v == null || v.trim().isEmpty) return 'El apellido es obligatorio';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _descCtrl,
              label:      'Descripción',
              icon:       Icons.notes_rounded,
              maxLines:   3,
              hint:       'Cuéntale algo a la comunidad...',
              validator:  (v) {
                if (v != null && v.trim().length > 200) {
                  return 'Máximo 200 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Sección: Cuenta ──────────────────────────────────────────
            _SectionLabel(label: 'Cuenta'),
            const SizedBox(height: 12),

            _Field(
              controller:  _usernameCtrl,
              label:       'Nombre de usuario',
              icon:        Icons.alternate_email_rounded,
              hint:        'sin espacios ni caracteres especiales',
              keyboardType: TextInputType.text,
              validator:   (v) {
                if (v == null || v.trim().isEmpty) return 'El username es obligatorio';
                if (v.trim().contains(' ')) return 'Sin espacios';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _Field(
              controller:   _emailCtrl,
              label:        'Correo electrónico',
              icon:         Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              hint:         'Opcional si tienes teléfono',
              validator:    (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final valid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                  if (!valid) return 'Correo no válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            _Field(
              controller:   _phoneCtrl,
              label:        'Teléfono',
              icon:         Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              hint:         'Opcional si tienes correo',
            ),

            const SizedBox(height: 12),

            // Aviso de unicidad
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        cs.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: cs.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Username, correo y teléfono deben ser únicos. '
                      'Al menos uno de correo o teléfono es obligatorio.',
                      style: tt.bodySmall?.copyWith(color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Botón guardar ────────────────────────────────────────────
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width:  20,
                      height: 20,
                      child:  CircularProgressIndicator(
                        strokeWidth: 2,
                        color:       Colors.white,
                      ),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar circular ───────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String initial;
  const _AvatarCircle({required this.initial});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width:  88,
      height: 88,
      decoration: BoxDecoration(
        color:  cs.primary,
        shape:  BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:      cs.primary.withOpacity(0.3),
            blurRadius: 16,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Campo de formulario ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String                label;
  final IconData              icon;
  final String?               hint;
  final int                   maxLines;
  final TextInputType         keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines    = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      maxLines:     maxLines,
      onChanged:    onChanged,
      validator:    validator,
      decoration: InputDecoration(
        labelText:   label,
        hintText:    hint,
        prefixIcon:  Icon(icon),
      ),
    );
  }
}

// ── Etiqueta de sección ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Text(
      label.toUpperCase(),
      style: tt.labelSmall?.copyWith(
        color:         cs.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight:    FontWeight.w800,
      ),
    );
  }
}