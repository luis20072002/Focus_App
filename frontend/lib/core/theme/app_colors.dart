import 'package:flutter/material.dart';

class AppColors {
  // ── Paleta nueva ────────────────────────────────────────────
  static const Color midnight      = Color(0xFF0F2C98);
  static const Color blueberry     = Color(0xFF5A4EDB);
  static const Color neutralOrange = Color(0xFFE4AAA2);
  static const Color gum           = Color(0xFFEA88B9);
  static const Color lightBlue     = Color(0xFFBCBBF2);

  // Derivados utiles
  static const Color background    = Color(0xFFF4F3FF); // Blanco con tinte violeta suave
  static const Color surface       = Color(0xFFFFFFFF); // Blanco puro para tarjetas
  static const Color textPrimary   = Color(0xFF0F2C98); // Midnight para texto
  static const Color textSecondary = Color(0xFF5A4EDB); // Blueberry suavizado
  static const Color accent        = Color(0xFF5A4EDB); // Blueberry
  static const Color accentSoft    = Color(0xFFEA88B9); // Gum
  static const Color highlight     = Color(0xFFE4AAA2); // Neutral Orange

  // ── Aliases legacy (para no romper pantallas existentes) ────
  static const Color moradoOscuro = midnight;
  static const Color vinotinto    = midnight;
  static const Color rojo         = gum;
  static const Color naranja      = blueberry;
  static const Color amarillo     = lightBlue;
  static const Color blanco       = Color(0xFFFFFFFF);
  static const Color grisClaro    = lightBlue;
  static const Color grisTexto    = Color(0xFF8A8FAB);
  static const Color fondo        = background;
  static const Color tarjeta      = surface;
  static const Color error        = Color(0xFFEA88B9);
}