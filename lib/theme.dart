import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════
//  PALETTE  —  Obsidian + Amber  (Dark Luxury)
// ══════════════════════════════════════════════════

const Color kBg       = Color(0xFF0C0C0E);
const Color kBgNav    = Color(0xFF111114);
const Color kBgCard   = Color(0xFF18181C);
const Color kBgCard2  = Color(0xFF111114);
const Color kBgDeep   = Color(0xFF0E0E11);
const Color kBorder   = Color(0xFF2A2A32);
const Color kBorderLt = Color(0xFF3A3A46);

const Color kAmber     = Color(0xFFF59E0B);
const Color kAmberHov  = Color(0xFFD97706);
const Color kAmberDim  = Color(0xFF92400E);
const Color kAmberGlow = Color(0xFFFBBF24);

const Color kRose    = Color(0xFFFB7185);
const Color kRoseHov = Color(0xFFF43F5E);
const Color kRoseDim = Color(0xFF4C0519);

const Color kTeal    = Color(0xFF2DD4BF);
const Color kTealHov = Color(0xFF14B8A6);
const Color kTealDim = Color(0xFF042F2E);

const Color kText      = Color(0xFFF0F0F4);
const Color kTextDim   = Color(0xFFB0B0C0);
const Color kTextMuted = Color(0xFF808090);

const Color kBtnSec    = Color(0xFF1E1E24);
const Color kBtnSecHov = Color(0xFF2A2A34);

// ── Font helpers ──────────────────────────────────
const String kFontMono  = 'Courier New';
const String kFontCode  = 'Consolas';

TextStyle monoStyle({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = kText,
}) =>
    TextStyle(fontFamily: kFontMono, fontSize: size, fontWeight: weight, color: color);

TextStyle codeStyle({
  double size = 13,
  FontWeight weight = FontWeight.normal,
  Color color = kText,
}) =>
    TextStyle(fontFamily: kFontCode, fontSize: size, fontWeight: weight, color: color);

// ── App Theme ─────────────────────────────────────
ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        surface: kBg,
        primary: kAmber,
        secondary: kTeal,
        error: kRose,
      ),
      fontFamily: kFontCode,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: kText, fontFamily: kFontCode),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(const Color(0xFFCCCCCC)),
        trackColor: WidgetStateProperty.all(kBgDeep),
      ),
    );
