import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/constants/oiiax_brand.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:blockatie/constants/fonts.dart';

class AppTheme {
  // Primary theme with dynamic font based on language
  static ThemeData getPrimaryTheme() {
    return ThemeData(
      fontFamily: AppFonts.currentFontFamily, // Dynamic font based on language
      scaffoldBackgroundColor: AppColors.bgColor,
      // RTL-aware color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: OIIAXBrand.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: OIIAXBrand.primary,
        onPrimary: OIIAXBrand.charcoal,
        surface: OIIAXBrand.white,
        onSurface: OIIAXBrand.charcoal,
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: SizeConfig.textMultiplier * 1.2,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: SizeConfig.textMultiplier * 1.4,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: SizeConfig.textMultiplier * 1.6,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: SizeConfig.textMultiplier * 1.8,
        ),
        displayLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: SizeConfig.textMultiplier * 2,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: SizeConfig.textMultiplier * 2.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: SizeConfig.textMultiplier * 2.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: SizeConfig.textMultiplier * 3,
        ),
      ),
      // RTL-aware app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.gradient2,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      // RTL-aware button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: AppFonts.currentFontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // RTL-aware text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: AppFonts.currentFontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // RTL-aware input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.grey[600],
        ),
        hintStyle: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  // Light theme with dynamic font based on language
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: AppFonts.currentFontFamily, // Dynamic font based on language
      scaffoldBackgroundColor: AppColors.bgColor,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
      // RTL-aware color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: OIIAXBrand.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: OIIAXBrand.primary,
        onPrimary: OIIAXBrand.charcoal,
        surface: OIIAXBrand.white,
        onSurface: OIIAXBrand.charcoal,
      ),
    );
  }

  // Dark theme with dynamic font based on language
  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: AppFonts.currentFontFamily, // Dynamic font based on language
      scaffoldBackgroundColor: Colors.grey[900],
      brightness: Brightness.dark,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontFamily: AppFonts.currentFontFamily,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      // RTL-aware color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: OIIAXBrand.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: OIIAXBrand.primary,
        onPrimary: OIIAXBrand.charcoal,
        surface: OIIAXBrand.charcoal,
        onSurface: OIIAXBrand.white,
      ),
    );
  }
}
