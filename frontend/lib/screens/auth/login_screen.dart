import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl   = TextEditingController();

  bool _obscurePassword   = true;
  bool _loading           = false;
  bool _identifierFocused = false;
  bool _passwordFocused   = false;

  late final AnimationController _eyeController;
  late final Animation<double>   _eyeAnimation;

  final FocusNode _identifierFocus = FocusNode();
  final FocusNode _passwordFocus   = FocusNode();

  @override
  void initState() {
    super.initState();

    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _eyeAnimation = CurvedAnimation(
      parent: _eyeController,
      curve: Curves.easeInOut,
    );

    _identifierFocus.addListener(() {
      setState(() => _identifierFocused = _identifierFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _eyeController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    setState(() => _obscurePassword = !_obscurePassword);
    _obscurePassword ? _eyeController.reverse() : _eyeController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(
      _identifierCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Error al iniciar sesión',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _Header(
              height: size.height * 0.30,
              onBack: () => context.go('/welcome'),
            ),

            // ── Formulario ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titulo
                    Text(
                      'Bienvenido',
                      style: GoogleFonts.nunito(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnight,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 350.ms).slideY(
                          begin: 0.15,
                          end: 0,
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 4),

                    Text(
                      'Inicia sesión para continuar',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.grisTexto,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 80.ms, duration: 350.ms),

                    const SizedBox(height: 28),

                    // Campo identificador
                    _FieldLabel(text: 'Correo, teléfono o usuario')
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 300.ms),

                    const SizedBox(height: 8),

                    _AnimatedField(
                      controller: _identifierCtrl,
                      focusNode: _identifierFocus,
                      isFocused: _identifierFocused,
                      hintText: 'tucorreo@gmail.com',
                      prefixIcon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Este campo es obligatorio'
                          : null,
                    ).animate().fadeIn(delay: 160.ms, duration: 300.ms),

                    const SizedBox(height: 18),

                    // Campo contraseña
                    _FieldLabel(text: 'Contraseña')
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 300.ms),

                    const SizedBox(height: 8),

                    _AnimatedField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      isFocused: _passwordFocused,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                      suffix: _EyeButton(
                        animation: _eyeAnimation,
                        onTap: _toggleObscure,
                      ),
                    ).animate().fadeIn(delay: 240.ms, duration: 300.ms),

                    // Olvidaste contraseña
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.nunito(
                            color: AppColors.blueberry,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 280.ms, duration: 300.ms),

                    const SizedBox(height: 4),

                    // Botón login
                    _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.midnight,
                              strokeWidth: 2.5,
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.midnight,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Iniciar sesión',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 320.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Ir a registro
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text.rich(
                          TextSpan(
                            text: '¿No tienes cuenta? ',
                            style: GoogleFonts.nunito(
                              color: AppColors.grisTexto,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Regístrate',
                                style: GoogleFonts.nunito(
                                  color: AppColors.midnight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 360.ms, duration: 300.ms),

                    const SizedBox(height: 32),
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

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double height;
  final VoidCallback onBack;
  const _Header({required this.height, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blueberry, AppColors.midnight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Círculos decorativos
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 55,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gum.withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            left: -18,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightBlue.withOpacity(0.12),
              ),
            ),
          ),

          // Botón de regreso
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),

          // Logo y nombre
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ).animate().scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 10),
                Text(
                  'Focus App',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wave clipper ───────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.25, size.height,
      size.width * 0.5, size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height - 40,
      size.width, size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

// ── Campo animado ──────────────────────────────────────────────────────────

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
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
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
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
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
          suffixIcon: suffix,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
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

// ── Label ──────────────────────────────────────────────────────────────────

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

// ── Ojito ──────────────────────────────────────────────────────────────────

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
          builder: (_, _) => Stack(
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