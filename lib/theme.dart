import 'package:flutter/material.dart';

/// Warna diambil langsung dari prototype Figma PROJECT-50JT.
class AppColors {
  static const primary = Color(0xFF176B6B); // teal tombol & aksen utama
  static const primaryDark = Color(0xFF0B4148); // header/header kartu gelap
  static const bg = Color(0xFFF4F7F9); // latar layar
  static const card = Colors.white;
  static const textDark = Color(0xFF15262E);
  static const textMuted = Color(0xFF6B7A80);
  static const border = Color(0xFFDDE7E9);
  static const mintChip = Color(0xFFE7F4F2); // chip "Tepat waktu"
  static const lavenderChip = Color(0xFFEAEDFF); // chip biru muda
  static const red = Color(0xFFD64545);
  static const amber = Color(0xFFE8A13C);
  static const blue = Color(0xFF4A6FD4);
  static const green = Color(0xFF3E9B6B);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          foregroundColor: AppColors.textDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
}
