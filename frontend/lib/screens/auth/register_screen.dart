import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // Controladores
  final _nameCtrl     = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _passConfCtrl = TextEditingController();

  // Focus nodes
  final _nameFocus     = FocusNode();
  final _lastnameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus    = FocusNode();
  final _phoneFocus    = FocusNode();
  final _passFocus     = FocusNode();
  final _passConfFocus = FocusNode();

  bool _nameFocused     = false;
  bool _lastnameFocused = false;
  bool _usernameFocused = false;
  bool _emailFocused    = false;
  bool _phoneFocused    = false;
  bool _passFocused     = false;
  bool _passConfFocused = false;

  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _loading     = false;

  late final AnimationController _eyePass;
  late final AnimationController _eyeConf;
  late final Animation<double>   _eyePassAnim;
  late final Animation<double>   _eyeConfAnim;

  // Stepper
  int  _currentStep  = 0;
  bool _goingForward = true;

  // Fecha
  int _selectedMonth     = DateTime.now().month - 1;
  int _selectedDay       = DateTime.now().day - 1;
  int _selectedYearIndex = 13;

  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  int get _daysInMonth {
    final year  = _years[_selectedYearIndex];
    final month = _selectedMonth + 1;
    return DateTime(year, month + 1, 0).day;
  }

  List<int> get _years {
    final now = DateTime.now().year;
    return List.generate(100, (i) => now - 5 - i);
  }

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  static const _gradients = [
    [AppColors.blueberry, AppColors.midnight],
    [Color(0xFF7B6EE8), AppColors.midnight],
    [AppColors.gum, Color(0xFF8B1A6B)],
    [AppColors.neutralOrange, Color(0xFFB05A40)],
  ];

  static const _titles = [
    '¿Cómo te llamas?',
    '¿Dónde te encontramos?',
    'Crea tu contraseña',
    '¿Cuándo naciste?',
  ];

  static const _subtitles = [
    'Tu nombre aparecerá en tu perfil.',
    'Usa tu correo o teléfono para ingresar.',
    'Mínimo 6 caracteres, que sea segura.',
    '¡Nos gustaría felicitarte!',
  ];

  @override
  void initState() {
    super.initState();

    // FIX: duración reducida de 250ms a 200ms — mas snappy
    _eyePass     = AnimationController(vsync: this, duration: 200.ms);
    _eyeConf     = AnimationController(vsync: this, duration: 200.ms);
    _eyePassAnim = CurvedAnimation(parent: _eyePass, curve: Curves.easeInOut);
    _eyeConfAnim = CurvedAnimation(parent: _eyeConf, curve: Curves.easeInOut);

    _addFocusListener(_nameFocus,     (v) => setState(() => _nameFocused     = v));
    _addFocusListener(_lastnameFocus, (v) => setState(() => _lastnameFocused = v));
    _addFocusListener(_usernameFocus, (v) => setState(() => _usernameFocused = v));
    _addFocusListener(_emailFocus,    (v) => setState(() => _emailFocused    = v));
    _addFocusListener(_phoneFocus,    (v) => setState(() => _phoneFocused    = v));
    _addFocusListener(_passFocus,     (v) => setState(() => _passFocused     = v));
    _addFocusListener(_passConfFocus, (v) => setState(() => _passConfFocused = v));
  }

  void _addFocusListener(FocusNode node, void Function(bool) setter) {
    node.addListener(() => setter(node.hasFocus));
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _lastnameCtrl, _usernameCtrl,
      _emailCtrl, _phoneCtrl, _passCtrl, _passConfCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus, _lastnameFocus, _usernameFocus,
      _emailFocus, _phoneFocus, _passFocus, _passConfFocus,
    ]) {
      f.dispose();
    }
    _eyePass.dispose();
    _eyeConf.dispose();
    super.dispose();
  }

  void _nextStep() {
    final valid = switch (_currentStep) {
      0 => _step1Key.currentState?.validate() ?? false,
      1 => _step2Key.currentState?.validate() ?? false,
      2 => _step3Key.currentState?.validate() ?? false,
      _ => true,
    };

    if (!valid) return;

    if (_currentStep < 3) {
      setState(() {
        _goingForward = true;
        _currentStep++;
      });
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep == 0) {
      // Va a login destruyendo register del stack
      context.go('/login');
    } else {
      setState(() {
        _goingForward = false;
        _currentStep--;
      });
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debes ingresar correo o teléfono',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final day       = _selectedDay + 1;
    final month     = _selectedMonth + 1;
    final year      = _years[_selectedYearIndex];
    final birthDate =
        '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      name:      _nameCtrl.text.trim(),
      lastname:  _lastnameCtrl.text.trim(),
      username:  _usernameCtrl.text.trim(),
      password:  _passCtrl.text,
      email:     email.isEmpty ? null : email,
      phone:     phone.isEmpty ? null : phone,
      birthDate: birthDate,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Error al registrarse',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _RegisterHeader(
            step:           _currentStep,
            totalSteps:     4,
            gradientColors: _gradients[_currentStep].map((c) => c).toList(),
            title:          _titles[_currentStep],
            subtitle:       _subtitles[_currentStep],
            onBack:         _prevStep,
          ),

          // ── Contenido del paso ───────────────────────────────────
          // FIX: duración del switcher reducida de 320ms a 200ms.
          // Se eliminaron las animaciones .fadeIn/.slideY individuales
          // de cada campo dentro de los pasos — el switcher ya provee
          // la transición de entrada completa. Tener ambas corriendo
          // simultaneamente (switcher + flutter_animate por campo)
          // era la causa principal del lag perceptible.
          Expanded(
            child: AnimatedSwitcher(
              duration: 200.ms,
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
                key: ValueKey(_currentStep),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                  child: _buildStep(),
                ),
              ),
            ),
          ),

          // ── Botón siguiente ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              28, 0, 28, MediaQuery.of(context).padding.bottom + 20,
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
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gradients[_currentStep].first,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentStep == 3 ? 'Crear cuenta' : 'Siguiente',
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

  Widget _buildStep() {
    return switch (_currentStep) {
      0 => _Step1(
        formKey:         _step1Key,
        nameCtrl:        _nameCtrl,
        nameFocus:       _nameFocus,
        nameFocused:     _nameFocused,
        lastnameCtrl:    _lastnameCtrl,
        lastnameFocus:   _lastnameFocus,
        lastnameFocused: _lastnameFocused,
      ),
      1 => _Step2(
        formKey:         _step2Key,
        usernameCtrl:    _usernameCtrl,
        usernameFocus:   _usernameFocus,
        usernameFocused: _usernameFocused,
        emailCtrl:       _emailCtrl,
        emailFocus:      _emailFocus,
        emailFocused:    _emailFocused,
        phoneCtrl:       _phoneCtrl,
        phoneFocus:      _phoneFocus,
        phoneFocused:    _phoneFocused,
      ),
      2 => _Step3(
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
      3 => _Step4(
        months:            _months,
        daysInMonth:       _daysInMonth,
        years:             _years,
        selectedMonth:     _selectedMonth,
        selectedDay:       _selectedDay,
        selectedYearIndex: _selectedYearIndex,
        onMonthChanged: (i) => setState(() {
          _selectedMonth = i;
          if (_selectedDay >= _daysInMonth) _selectedDay = _daysInMonth - 1;
        }),
        onDayChanged:  (i) => setState(() => _selectedDay = i),
        onYearChanged: (i) => setState(() => _selectedYearIndex = i),
      ),
      _ => const SizedBox(),
    };
  }
}

// ── Header del registro ────────────────────────────────────────────────────

class _RegisterHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _RegisterHeader({
    required this.step,
    required this.totalSteps,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnimatedContainer(
      // FIX: duración del header reducida de 400ms a 250ms
      duration: 250.ms,
      curve: Curves.easeInOut,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 24),
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
            children: List.generate(totalSteps, (i) => Expanded(
              child: AnimatedContainer(
                // FIX: reducido de 300ms a 200ms
                duration: 200.ms,
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
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

          // FIX: titulo y subtitulo usan animate() con key para que
          // solo se animen cuando cambia el paso, no en cada rebuild.
          // Duración reducida de 300ms a 200ms.
          Text(
            title,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ).animate(key: ValueKey('title_$step'))
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.08, end: 0, duration: 200.ms),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: GoogleFonts.nunito(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ).animate(key: ValueKey('sub_$step'))
              .fadeIn(delay: 60.ms, duration: 200.ms),
        ],
      ),
    );
  }
}

// ── Paso 1: Nombre y apellido ──────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final FocusNode nameFocus;
  final bool nameFocused;
  final TextEditingController lastnameCtrl;
  final FocusNode lastnameFocus;
  final bool lastnameFocused;

  const _Step1({
    required this.formKey,
    required this.nameCtrl,
    required this.nameFocus,
    required this.nameFocused,
    required this.lastnameCtrl,
    required this.lastnameFocus,
    required this.lastnameFocused,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: sin .animate() en los campos individuales.
    // El AnimatedSwitcher padre ya anima la entrada del paso completo.
    // Agregar animaciones por campo encima causaba el lag.
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'Nombre'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller: nameCtrl,
            focusNode:  nameFocus,
            isFocused:  nameFocused,
            hintText:   'Juan',
            prefixIcon: Icons.badge_outlined,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Apellido'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller: lastnameCtrl,
            focusNode:  lastnameFocus,
            isFocused:  lastnameFocused,
            hintText:   'Pérez',
            prefixIcon: Icons.badge_outlined,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Paso 2: Usuario, correo y teléfono ────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final FocusNode usernameFocus;
  final bool usernameFocused;
  final TextEditingController emailCtrl;
  final FocusNode emailFocus;
  final bool emailFocused;
  final TextEditingController phoneCtrl;
  final FocusNode phoneFocus;
  final bool phoneFocused;

  const _Step2({
    required this.formKey,
    required this.usernameCtrl,
    required this.usernameFocus,
    required this.usernameFocused,
    required this.emailCtrl,
    required this.emailFocus,
    required this.emailFocused,
    required this.phoneCtrl,
    required this.phoneFocus,
    required this.phoneFocused,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'Nombre de usuario'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller: usernameCtrl,
            focusNode:  usernameFocus,
            isFocused:  usernameFocused,
            hintText:   '@juanperez',
            prefixIcon: Icons.alternate_email_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
              if (v.trim().length < 3) return 'Mínimo 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Correo electrónico (opcional si pones teléfono)'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller:   emailCtrl,
            focusNode:    emailFocus,
            isFocused:    emailFocused,
            hintText:     'juan@gmail.com',
            prefixIcon:   Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                final r = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!r.hasMatch(v)) return 'Correo inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.grisTexto.withOpacity(0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o',
                  style: GoogleFonts.nunito(
                    color: AppColors.grisTexto,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.grisTexto.withOpacity(0.2))),
            ],
          ),
          const SizedBox(height: 16),
          _FieldLabel(text: 'Teléfono (opcional si pones correo)'),
          const SizedBox(height: 8),
          _AnimatedField(
            controller:   phoneCtrl,
            focusNode:    phoneFocus,
            isFocused:    phoneFocused,
            hintText:     '+573001234567',
            prefixIcon:   Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Paso 3: Contraseña ─────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
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

  const _Step3({
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
          _FieldLabel(text: 'Contraseña'),
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
              if (v.length < 6) return 'Mínimo 6 caracteres';
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

// ── Paso 4: Fecha de nacimiento ────────────────────────────────────────────

class _Step4 extends StatelessWidget {
  final List<String> months;
  final int daysInMonth;
  final List<int> years;
  final int selectedMonth;
  final int selectedDay;
  final int selectedYearIndex;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onYearChanged;

  const _Step4({
    required this.months,
    required this.daysInMonth,
    required this.years,
    required this.selectedMonth,
    required this.selectedDay,
    required this.selectedYearIndex,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedYear = years[selectedYearIndex];

    return Column(
      children: [
        const SizedBox(height: 8),

        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 88, left: 0, right: 0,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blueberry.withOpacity(0.08),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.blueberry.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  // Mes
                  Expanded(
                    flex: 3,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedMonth,
                      ),
                      itemExtent: 44,
                      onSelectedItemChanged: onMonthChanged,
                      selectionOverlay: const SizedBox(),
                      children: months.map((m) => Center(
                        child: Text(
                          m,
                          style: GoogleFonts.nunito(
                            color: AppColors.midnight,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),

                  // Día
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedDay.clamp(0, daysInMonth - 1),
                      ),
                      itemExtent: 44,
                      onSelectedItemChanged: onDayChanged,
                      selectionOverlay: const SizedBox(),
                      children: List.generate(daysInMonth, (i) => Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.nunito(
                            color: AppColors.midnight,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )),
                    ),
                  ),

                  // Año
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedYearIndex,
                      ),
                      itemExtent: 44,
                      onSelectedItemChanged: onYearChanged,
                      selectionOverlay: const SizedBox(),
                      children: years.map((y) => Center(
                        child: Text(
                          '$y',
                          style: GoogleFonts.nunito(
                            color: AppColors.midnight,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.blueberry.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.blueberry.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cake_outlined,
                  color: AppColors.blueberry, size: 18),
              const SizedBox(width: 10),
              Text(
                '${months[selectedMonth]} ${selectedDay + 1}, $selectedYear',
                style: GoogleFonts.nunito(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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

// ── Widgets compartidos ────────────────────────────────────────────────────

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
      duration: 180.ms,
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
                  child: const Icon(Icons.visibility_outlined,
                      color: AppColors.blueberry, size: 21),
                ),
              ),
              Opacity(
                opacity: 1 - animation.value,
                child: Transform.scale(
                  scale: 0.85 + ((1 - animation.value) * 0.15),
                  child: Icon(Icons.visibility_off_outlined,
                      color: AppColors.grisTexto.withOpacity(0.5), size: 21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}