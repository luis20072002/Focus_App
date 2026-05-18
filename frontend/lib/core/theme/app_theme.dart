import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Tema claro ────────────────────────────────────────────────────────────
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness:           Brightness.light,
      primary:              AppColors.blueberry,
      onPrimary:            Colors.white,
      primaryContainer:     AppColors.lightBlue,
      onPrimaryContainer:   AppColors.midnight,
      secondary:            AppColors.gum,
      onSecondary:          Colors.white,
      secondaryContainer:   AppColors.neutralOrange,
      onSecondaryContainer: AppColors.midnight,
      error:                AppColors.gum,
      onError:              Colors.white,
      surface:              AppColors.surface,
      onSurface:            AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
      onSurfaceVariant:     AppColors.grisTexto,
      outline:              AppColors.lightBlue,
      shadow:               Color(0x1A0F2C98),
    );

    return ThemeData(
      useMaterial3:            true,
      colorScheme:             colorScheme,
      fontFamily:              'Inter',
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor:        AppColors.background,
        foregroundColor:        AppColors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        centerTitle:            false,
        titleTextStyle: TextStyle(
          fontFamily:    'Inter',
          fontSize:      18,
          fontWeight:    FontWeight.w700,
          color:         AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness:               Brightness.light,
          statusBarIconBrightness:           Brightness.dark,
          systemNavigationBarColor:          AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── BottomNavigationBar ───────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      AppColors.surface,
        selectedItemColor:    AppColors.blueberry,
        unselectedItemColor:  AppColors.grisTexto,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
        type:                 BottomNavigationBarType.fixed,
        elevation:            8,
        selectedLabelStyle:   TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     AppColors.surface,
        elevation: 0,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBlue, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColors.blueberry,
          foregroundColor:         Colors.white,
          disabledBackgroundColor: AppColors.lightBlue,
          disabledForegroundColor: AppColors.grisTexto,
          elevation:               0,
          shadowColor:             Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blueberry,
          side:            const BorderSide(color: AppColors.blueberry, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blueberry,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.lightBlue, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.lightBlue, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.blueberry, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.gum, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.gum, width: 2),
        ),
        labelStyle:      const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.grisTexto),
        hintStyle:       const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.grisTexto),
        errorStyle:      const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.gum),
        prefixIconColor: AppColors.grisTexto,
        suffixIconColor: AppColors.grisTexto,
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:    AppColors.background,
        selectedColor:      AppColors.blueberry,
        disabledColor:      AppColors.lightBlue,
        labelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBlue),
        ),
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blueberry,
        foregroundColor: Colors.white,
        elevation:       4,
        shape:           CircleBorder(),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.grisTexto;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.blueberry;
          return AppColors.lightBlue;
        }),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBlue, thickness: 1, space: 1,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor:      AppColors.blueberry,
        textColor:      AppColors.textPrimary,
        subtitleTextStyle: TextStyle(
          fontFamily: 'Inter', fontSize: 13, color: AppColors.grisTexto,
        ),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.midnight,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 14, color: Colors.white,
        ),
        actionTextColor: AppColors.gum,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            AppColors.blueberry,
        linearTrackColor: AppColors.lightBlue,
      ),

      // ── TextTheme ─────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Inter', fontSize: 57, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1),
        displayMedium:  TextStyle(fontFamily: 'Inter', fontSize: 45, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
        displaySmall:   TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineLarge:  TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3),
        headlineSmall:  TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge:     TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.2),
        titleMedium:    TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge:      TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodySmall:      TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.grisTexto),
        labelLarge:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelMedium:    TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grisTexto),
        labelSmall:     TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.grisTexto),
      ),
    );
  }

  // ── Tema oscuro ───────────────────────────────────────────────────────────
  static ThemeData get dark {
    const darkBackground  = Color(0xFF0A0E1A);
    const darkSurface     = Color(0xFF121829);
    const darkSurfaceAlt  = Color(0xFF1A2238);
    const darkOutline     = Color(0xFF2A3350);
    const darkTextPrimary = Color(0xFFE8EAFF);
    const darkTextSecond  = Color(0xFF8B93B8);

    const colorScheme = ColorScheme(
      brightness:           Brightness.dark,
      primary:              AppColors.blueberry,
      onPrimary:            Colors.white,
      primaryContainer:     Color(0xFF1E1B4B),
      onPrimaryContainer:   AppColors.lightBlue,
      secondary:            AppColors.gum,
      onSecondary:          Colors.white,
      secondaryContainer:   Color(0xFF3D1F2E),
      onSecondaryContainer: AppColors.neutralOrange,
      error:                AppColors.gum,
      onError:              Colors.white,
      surface:              darkSurface,
      onSurface:            darkTextPrimary,
      surfaceContainerHighest: darkSurfaceAlt,
      onSurfaceVariant:     darkTextSecond,
      outline:              darkOutline,
      shadow:               Color(0x33000000),
    );

    return ThemeData(
      useMaterial3:            true,
      colorScheme:             colorScheme,
      fontFamily:              'Inter',
      scaffoldBackgroundColor: darkBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor:        darkBackground,
        foregroundColor:        darkTextPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        centerTitle:            false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700,
          color: darkTextPrimary, letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness:               Brightness.dark,
          statusBarIconBrightness:           Brightness.light,
          systemNavigationBarColor:          darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      darkSurface,
        selectedItemColor:    AppColors.lightBlue,
        unselectedItemColor:  darkTextSecond,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
        type:                 BottomNavigationBarType.fixed,
        elevation:            8,
        selectedLabelStyle:   TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400),
      ),

      cardTheme: CardThemeData(
        color:     darkSurface,
        elevation: 0,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColors.blueberry,
          foregroundColor:         Colors.white,
          disabledBackgroundColor: darkOutline,
          disabledForegroundColor: darkTextSecond,
          elevation:               0,
          shadowColor:             Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightBlue,
          side:            const BorderSide(color: AppColors.lightBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightBlue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: darkOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: darkOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.blueberry, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.gum, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.gum, width: 2),
        ),
        labelStyle:      const TextStyle(fontFamily: 'Inter', fontSize: 14, color: darkTextSecond),
        hintStyle:       const TextStyle(fontFamily: 'Inter', fontSize: 14, color: darkTextSecond),
        errorStyle:      const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.gum),
        prefixIconColor: darkTextSecond,
        suffixIconColor: darkTextSecond,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:    darkSurfaceAlt,
        selectedColor:      AppColors.blueberry,
        disabledColor:      darkOutline,
        labelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkOutline),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blueberry,
        foregroundColor: Colors.white,
        elevation:       4,
        shape:           CircleBorder(),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return darkTextSecond;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.blueberry;
          return darkOutline;
        }),
      ),

      dividerTheme: const DividerThemeData(
        color: darkOutline, thickness: 1, space: 1,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor:      AppColors.lightBlue,
        textColor:      darkTextPrimary,
        subtitleTextStyle: TextStyle(
          fontFamily: 'Inter', fontSize: 13, color: darkTextSecond,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceAlt,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 14, color: darkTextPrimary,
        ),
        actionTextColor: AppColors.gum,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            AppColors.lightBlue,
        linearTrackColor: darkOutline,
      ),

      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Inter', fontSize: 57, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -1),
        displayMedium:  TextStyle(fontFamily: 'Inter', fontSize: 45, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -0.5),
        displaySmall:   TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineLarge:  TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -0.3),
        headlineSmall:  TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: darkTextPrimary),
        titleLarge:     TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary, letterSpacing: -0.2),
        titleMedium:    TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleSmall:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge:      TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: darkTextPrimary),
        bodyMedium:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: darkTextPrimary),
        bodySmall:      TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: darkTextSecond),
        labelLarge:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
        labelMedium:    TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecond),
        labelSmall:     TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: darkTextSecond),
      ),
    );
  }
}