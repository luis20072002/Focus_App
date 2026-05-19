import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ForgotPasswordScreen — flujo de 3 pasos:
//   Paso 1: ingresar correo o teléfono  → POST /auth/password-recovery/request
//   Paso 2: ingresar código de 6 dígitos → POST /auth/password-recovery/verify
//   Paso 3: ingresar nueva contraseña   → POST /auth/password-recovery/confirm
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {

  // ── Estado general ──────────────────────────────────────────────────────
  int  _step        = 0; // 0 = identifier, 1 = código, 2 = nueva contraseña
  bool _loading     = false;
  bool _goingForward = true;

  // ── Paso 1 ──────────────────────────────────────────────────────────────
  final _step1Key        = GlobalKey<FormState>();
  final _identifierCtrl  = TextEditingController();
  final _identifierFocus = FocusNode();
  bool  _identifierFocused = false;

  // ── Paso 2 ──────────────────────────────────────────────────────────────
  // 6 campos individuales para el código
  final List<TextEditingController> _codeCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocus =
      List.generate(6, (_) => FocusNode());
  String _resetToken = ''; // guardado del verify para usarlo en confirm

  // ── Paso 3 ──────────────────────────────────────────────────────────────
  final _step3Key       = GlobalKey<FormState>();
  final _passCtrl       = TextEditingController();
  final _passConfCtrl   = TextEditingController();
  final _passFocus      = FocusNode();
  final _passConfFocus  = FocusNode();
  bool  _passFocused     = false;
  bool  _passConfFocused = false;
  bool  _obscurePass     = true;
  bool  _obscureConf     = true;

  late final AnimationController _eyePass;
  late final AnimationController _eyeConf;
  late final Animation<double>   _eyePassAnim;
  late final Animation<double>   _eyeConfAnim;

  // ── Metadatos por paso ──────────────────────────────────────────────────
  static const _gradients = [
    [Color(0xFF5A4EDB), Color(0xFF0F2C98)], // azul — solicitar
    [Color(0xFF7B6EE8), Color(0xFF0F2C98)], // violeta — verificar
    [Color(0xFF2196F3), Color(0xFF0D47A1)], // azul claro — nueva contraseña
  ];

  static const _titles = [
    '¿Olvidaste tu\ncontraseña?',
    'Revisa tu\ncorreo',
    'Nueva\ncontraseña',
  ];

  static const _subtitles = [
    'Te enviaremos un código de verificación.',
    'Ingresa el código de 6 dígitos que te enviamos.',
    'Elige una contraseña segura de mínimo 8 caracteres.',
  ];

  @override
  void initState() {
    super.initState();

    _eyePass     = AnimationController(vsync: this, duration: 200.ms);
    _eyeConf     = AnimationController(vsync: this, duration: 200.ms);
    _eyePassAnim = CurvedAnimation(parent: _eyePass, curve: Curves.easeInOut);
    _eyeConfAnim = CurvedAnimation(parent: _eyeConf, curve: Curves.easeInOut);

    _identifierFocus.addListener(
      () => setState(() => _identifierFocused = _identifierFocus.hasFocus),
    );
    _passFocus.addListener(
      () => setState(() => _passFocused = _passFocus.hasFocus),
    );
    _passConfFocus.addListener(
      () => setState(() => _passConfFocused = _passConfFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _identifierFocus.dispose();
    for (final c in _codeCtrl) c.dispose();
    for (final f in _codeFocus) f.dispose();
    _passCtrl.dispose();
    _passConfCtrl.dispose();
    _passFocus.dispose();
    _passConfFocus.dispose();
    _eyePass.dispose();
    _eyeConf.dispose();
    super.dispose();
  }

  // ── Navegación entre pasos ──────────────────────────────────────────────

  void _back() {
    if (_step == 0) {
      context.go('/login');
    } else {
      setState(() {
        _goingForward = false;
        _step--;
      });
    }
  }

  Future<void> _next() async {
    switch (_step) {
      case 0: await _requestCode();   break;
      case 1: await _verifyCode();    break;
      case 2: await _confirmPassword(); break;
    }
  }

  // ── Paso 1: solicitar código ────────────────────────────────────────────

  Future<void> _requestCode() async {
    if (!(_step1Key.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.recoveryRequest),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': _identifierCtrl.text.trim()}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _goingForward = true;
          _step = 1;
        });
      } else {
        _showError(_parseError(res.body));
      }
    } catch (_) {
      _showError('Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Paso 2: verificar código ────────────────────────────────────────────

  Future<void> _verifyCode() async {
    final code = _codeCtrl.map((c) => c.text).join();
    if (code.length < 6) {
      _showError('Ingresa el código completo de 6 dígitos.');
      return;
    }
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.recoveryVerify),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': code}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _resetToken = data['reset_token']?.toString() ?? code;
        setState(() {
          _goingForward = true;
          _step = 2;
        });
      } else {
        _showError(_parseError(res.body));
      }
    } catch (_) {
      _showError('Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Paso 3: confirmar nueva contraseña ──────────────────────────────────

  Future<void> _confirmPassword() async {
    if (!(_step3Key.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.recoveryConfirm),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token':        _resetToken,
          'new_password': _passCtrl.text,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        // Éxito — mostrar diálogo y redirigir a login
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.blueberry.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.blueberry,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Contraseña actualizada!',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ya puedes iniciar sesión con tu nueva contraseña.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.grisTexto,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueberry,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Iniciar sesión',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        _showError(_parseError(res.body));
      }
    } catch (_) {
      _showError('Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['detail']?.toString() ?? 'Error inesperado';
    } catch (_) {
      return 'Error inesperado';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.nunito(color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header con gradiente ─────────────────────────────────────
          _ForgotHeader(
            step:           _step,
            gradientColors: _gradients[_step].cast<Color>(),
            title:          _titles[_step],
            subtitle:       _subtitles[_step],
            onBack:         _back,
          ),

          // ── Contenido animado del paso ───────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                final offset = _goingForward
                    ? const Offset(1.0, 0)
                    : const Offset(-1.0, 0);
                return SlideTransition(
                  position: Tween<Offset>(begin: offset, end: Offset.zero)
                      .animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ),

          // ── Botón de acción ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              28, 0, 28, MediaQuery.of(context).padding.bottom + 24,
            ),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.blueberry,
                      strokeWidth: 2.5,
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gradients[_step].first,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _step == 2 ? 'Actualizar contraseña' : 'Continuar',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _Step1Identifier(
          formKey:         _step1Key,
          ctrl:            _identifierCtrl,
          focus:           _identifierFocus,
          isFocused:       _identifierFocused,
        ),
      1 => _Step2Code(
          controllers: _codeCtrl,
          focusNodes:  _codeFocus,
        ),
      2 => _Step3Password(
          formKey:         _step3Key,
          passCtrl:        _passCtrl,
          passFocus:       _passFocus,
          passFocused:     _passFocused,
          passConfCtrl:    _passConfCtrl,
          passConfFocus:   _passConfFocus,
          passConfFocused: _passConfFocused,
          obscurePass:     _obscurePass,
          obscureConf:     _obscureConf,
          eyePassAnim:     _eyePassAnim,
          eyeConfAnim:     _eyeConfAnim,
          onTogglePass: () => setState(() {
            _obscurePass = !_obscurePass;
            _obscurePass ? _eyePass.reverse() : _eyePass.forward();
          }),
          onToggleConf: () => setState(() {
            _obscureConf = !_obscureConf;
            _obscureConf ? _eyeConf.reverse() : _eyeConf.forward();
          }),
        ),
      _ => const SizedBox(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotHeader extends StatelessWidget {
  final int step;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _ForgotHeader({
    required this.step,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flecha atrás
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Indicadores de paso
          Row(
            children: List.generate(3, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? Colors.white
                      : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),

          const SizedBox(height: 20),

          // Ícono del paso
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(step),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                [
                  Icons.lock_reset_rounded,
                  Icons.mark_email_read_outlined,
                  Icons.lock_outline_rounded,
                ][step],
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Título
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              title,
              key: ValueKey('title_$step'),
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Subtítulo
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              subtitle,
              key: ValueKey('sub_$step'),
              style: GoogleFonts.nunito(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 1 — Identificador (correo o teléfono)
// ─────────────────────────────────────────────────────────────────────────────

class _Step1Identifier extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool isFocused;

  const _Step1Identifier({
    required this.formKey,
    required this.ctrl,
    required this.focus,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'Correo electrónico o teléfono'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller:   ctrl,
            focusNode:    focus,
            isFocused:    isFocused,
            hintText:     'tucorreo@gmail.com o +573001234567',
            prefixIcon:   Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Nota informativa
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blueberry.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.blueberry.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.blueberry,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solo puedes usar el medio con el que te registraste.',
                    style: GoogleFonts.nunito(
                      color: AppColors.blueberry,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 2 — Código de 6 dígitos
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Code extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const _Step2Code({
    required this.controllers,
    required this.focusNodes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: 'Código de verificación'),
        const SizedBox(height: 20),

        // 6 cajas para el código
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _CodeBox(
            controller: controllers[i],
            focusNode:  focusNodes[i],
            onChanged: (val) {
              if (val.isNotEmpty && i < 5) {
                focusNodes[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                focusNodes[i - 1].requestFocus();
              }
            },
          )),
        ),

        const SizedBox(height: 24),

        // Nota sobre expiración
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.blueberry.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.blueberry.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: AppColors.blueberry,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El código expira en 15 minutos.',
                  style: GoogleFonts.nunito(
                    color: AppColors.blueberry,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextFormField(
        controller:     controller,
        focusNode:      focusNode,
        textAlign:      TextAlign.center,
        maxLength:      1,
        keyboardType:   TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged:      onChanged,
        style: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.midnight,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled:      true,
          fillColor:   AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.blueberry.withOpacity(0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.grisTexto.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.blueberry,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso 3 — Nueva contraseña
// ─────────────────────────────────────────────────────────────────────────────

class _Step3Password extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passCtrl;
  final FocusNode passFocus;
  final bool passFocused;
  final TextEditingController passConfCtrl;
  final FocusNode passConfFocus;
  final bool passConfFocused;
  final bool obscurePass;
  final bool obscureConf;
  final Animation<double> eyePassAnim;
  final Animation<double> eyeConfAnim;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConf;

  const _Step3Password({
    required this.formKey,
    required this.passCtrl,
    required this.passFocus,
    required this.passFocused,
    required this.passConfCtrl,
    required this.passConfFocus,
    required this.passConfFocused,
    required this.obscurePass,
    required this.obscureConf,
    required this.eyePassAnim,
    required this.eyeConfAnim,
    required this.onTogglePass,
    required this.onToggleConf,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'Nueva contraseña'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller:  passCtrl,
            focusNode:   passFocus,
            isFocused:   passFocused,
            hintText:    '••••••••',
            prefixIcon:  Icons.lock_outline_rounded,
            obscureText: obscurePass,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (v.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
            suffix: _EyeButton(animation: eyePassAnim, onTap: onTogglePass),
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Confirmar contraseña'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller:  passConfCtrl,
            focusNode:   passConfFocus,
            isFocused:   passConfFocused,
            hintText:    '••••••••',
            prefixIcon:  Icons.lock_outline_rounded,
            obscureText: obscureConf,
            validator: (v) {
              if (v != passCtrl.text) return 'Las contraseñas no coinciden';
              return null;
            },
            suffix: _EyeButton(animation: eyeConfAnim, onTap: onToggleConf),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets compartidos
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        color: AppColors.midnight,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AnimatedField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _AnimatedField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText   = false,
    this.keyboardType  = TextInputType.text,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? AppColors.blueberry : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? AppColors.blueberry.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: isFocused ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller:   controller,
        focusNode:    focusNode,
        obscureText:  obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.nunito(
          color: AppColors.midnight,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.nunito(
            color: AppColors.grisTexto.withOpacity(0.5),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: isFocused ? AppColors.blueberry : AppColors.grisTexto,
            size: 20,
          ),
          suffixIcon:         suffix,
          filled:             false,
          border:             InputBorder.none,
          enabledBorder:      InputBorder.none,
          focusedBorder:      InputBorder.none,
          errorBorder:        InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16,
          ),
          errorStyle: GoogleFonts.nunito(
            color: AppColors.error,
            fontSize: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onTap;

  const _EyeButton({required this.animation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: animation.value,
                child: Transform.scale(
                  scale: 0.85 + (animation.value * 0.15),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.blueberry,
                    size: 21,
                  ),
                ),
              ),
              Opacity(
                opacity: 1 - animation.value,
                child: Transform.scale(
                  scale: 0.85 + ((1 - animation.value) * 0.15),
                  child: Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.grisTexto.withOpacity(0.5),
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}