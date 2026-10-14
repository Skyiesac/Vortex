import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const backgroundDark = Color(0xFFF4F0E6);
const surfaceDark = Color(0xFFF4F0E6);
const surfaceElevated = Color(0xFFE9E2D4);
const gold = Color(0xFF123B9A);
const goldLight = Color(0xFF315DC0);
const goldDark = Color(0xFF9BAED7);
const burgundy = Color(0xFFDB6548);
const emerald = Color(0xFF27806D);
const ivory = Color(0xFF19264A);
const ivoryMuted = Color(0xFF737783);
const errorRed = Color(0xFFC0392B);

final baroqueTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: backgroundDark,
  primaryColor: gold,
  colorScheme: const ColorScheme.light(
    primary: gold,
    onPrimary: Colors.white,
    secondary: burgundy,
    onSecondary: Colors.white,
    surface: surfaceDark,
    onSurface: ivory,
    error: errorRed,
    onError: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: surfaceDark,
    foregroundColor: ivory,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.playfairDisplay(
      color: ivory,
      fontSize: 19,
      fontWeight: FontWeight.bold,
    ),
    shape: const Border(bottom: BorderSide(color: Color(0xFFE2DDCF), width: 1)),
  ),
  cardTheme: CardThemeData(
    color: surfaceDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide.none,
    ),
    shadowColor: Colors.transparent,
    elevation: 0,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
      color: ivory,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineLarge: GoogleFonts.spaceGrotesk(
      color: ivory,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      color: ivory,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      color: ivory,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: GoogleFonts.dmSans(color: ivory, fontSize: 16),
    bodyMedium: GoogleFonts.dmSans(color: ivory, fontSize: 14),
    bodySmall: GoogleFonts.dmSans(color: ivoryMuted, fontSize: 12),
    labelLarge: GoogleFonts.dmSans(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: backgroundDark,
      backgroundColor: gold,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: GoogleFonts.cormorantGaramond(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: GoogleFonts.cormorantGaramond(color: ivoryMuted, fontSize: 14),
    labelStyle: GoogleFonts.cormorantGaramond(color: ivoryMuted, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: goldDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: goldDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: gold, width: 1.5),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? goldLight : ivoryMuted,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? burgundy : surfaceElevated,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: gold,
    foregroundColor: backgroundDark,
  ),
);
