import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Echelle typo commune de l'app (référence: labels de navigation type "Profil")
  static const double fsDisplayLg = 34;
  static const double fsDisplayMd = 28;
  static const double fsHeadlineLg = 24;
  static const double fsHeadlineMd = 20;
  static const double fsTitleLg = 18;
  static const double fsBodyLg = 16;
  static const double fsBodyMd = 14;
  static const double fsBodySm = 13;
  static const double fsLabelLg = 14;
  static const double fsLabelSm = 13;
  static const double fsNavLabel = 13;
  static const double fsBadgeSm = 9;
  static const double fsBadgeXs = 8;

  // Couleurs principales — inspirées de l'image
  static const Color primary = Color(0xFF1B2FBE); // Bleu foncé boutons/accents
  static const Color primaryLight =
      Color(0xFF2B3DD4); // Bleu légèrement plus clair
  // couleur secondaire plus grisée pour éléments moins importants
  static const Color secondary = Color(0xFF4E536F); // Gris-bleu plus contrasté
  static const Color accent = Color(0xFFFF6B6B); // Rouge (alertes, erreurs)
  static const Color background = Color(0xFFEEF1FB); // Fond légèrement bleuté
  static const Color surface = Color(0xFFFFFFFF); // Blanc pur (cartes, inputs)
  static const Color surfaceVariant = Color(0xFFE7EBFA); // Fond secondaire
  static const Color textPrimary =
      Color(0xFF0D0E2E); // Texte principal très foncé
  static const Color textSecondary =
      Color(0xFF373B57); // Texte secondaire renforcé
  static const Color border = Color(0xFFD7DDED); // Bordures plus visibles
  static const Color gold = Color(0xFFFFD700); // Badge AI

  // Dark mode
  static const Color darkBackground = Color(0xFF080A1E);
  static const Color darkSurface = Color(0xFF10122A);
  static const Color darkSurfaceVariant = Color(0xFF181A35);
  static const Color darkText = Color(0xFFF0F2FF);
  static const Color darkTextSecondary = Color(0xFFB2B8D0);
  static const Color darkBorder = Color(0xFF22254A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textSelectionTheme: const TextSelectionThemeData(cursorColor: primary),

      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSans(
            fontSize: fsDisplayLg,
            fontWeight: FontWeight.w800,
            color: textPrimary),
        displayMedium: GoogleFonts.dmSans(
            fontSize: fsDisplayMd,
            fontWeight: FontWeight.w800,
            color: textPrimary),
        headlineLarge: GoogleFonts.dmSans(
            fontSize: fsHeadlineLg,
            fontWeight: FontWeight.w700,
            color: textPrimary),
        headlineMedium: GoogleFonts.dmSans(
            fontSize: fsHeadlineMd,
            fontWeight: FontWeight.w700,
            color: textPrimary),
        titleLarge: GoogleFonts.dmSans(
            fontSize: fsTitleLg,
            fontWeight: FontWeight.w600,
            color: textPrimary),
        bodyLarge: GoogleFonts.dmSans(fontSize: fsBodyLg, color: textPrimary),
        bodyMedium: GoogleFonts.dmSans(fontSize: fsBodyMd, color: textPrimary),
        bodySmall: GoogleFonts.dmSans(fontSize: fsBodySm, color: textPrimary),
        labelLarge: GoogleFonts.dmSans(
            fontSize: fsLabelLg,
            fontWeight: FontWeight.w600,
            color: textPrimary),
        labelSmall: GoogleFonts.dmSans(fontSize: fsLabelSm, color: textPrimary),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.dmSans(
          color: textPrimary,
          fontSize: fsHeadlineMd,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Bouton principal — bleu foncé, blanc, carré arrondi
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle:
              GoogleFonts.dmSans(fontSize: fsBodyLg, fontWeight: FontWeight.w700),
        ),
      ),

      // Bouton outline — bordure bleue
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.dmSans(fontSize: fsLabelLg, fontWeight: FontWeight.w600),
        ),
      ),

      // Bouton texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle:
              GoogleFonts.dmSans(fontSize: fsLabelSm, fontWeight: FontWeight.w600),
        ),
      ),

      // Inputs — fond blanc, bordure légère, focus bleu
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: GoogleFonts.dmSans(color: textSecondary, fontSize: fsBodySm),
        labelStyle: GoogleFonts.dmSans(color: textSecondary, fontSize: fsBodySm),
        errorStyle: GoogleFonts.dmSans(color: accent, fontSize: fsBodySm),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return border;
        }),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.1),
        elevation: 0,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(
                fontSize: fsLabelSm, fontWeight: FontWeight.w600, color: primary);
          }
          return GoogleFonts.dmSans(fontSize: fsLabelSm, color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.dmSans(
          color: textPrimary,
          fontSize: fsTitleLg,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle:
            GoogleFonts.dmSans(color: textSecondary, fontSize: fsBodyMd),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: fsBodyMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: secondary,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSurface: darkText,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme:
          GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.dmSans(
            fontSize: fsDisplayLg,
            fontWeight: FontWeight.w800,
            color: darkText),
        displayMedium: GoogleFonts.dmSans(
            fontSize: fsDisplayMd,
            fontWeight: FontWeight.w800,
            color: darkText),
        headlineLarge: GoogleFonts.dmSans(
            fontSize: fsHeadlineLg,
            fontWeight: FontWeight.w700,
            color: darkText),
        headlineMedium: GoogleFonts.dmSans(
            fontSize: fsHeadlineMd,
            fontWeight: FontWeight.w700,
            color: darkText),
        titleLarge: GoogleFonts.dmSans(
            fontSize: fsTitleLg,
            fontWeight: FontWeight.w600,
            color: darkText),
        bodyLarge: GoogleFonts.dmSans(fontSize: fsBodyLg, color: darkText),
        bodyMedium: GoogleFonts.dmSans(fontSize: fsBodyMd, color: darkTextSecondary),
        bodySmall: GoogleFonts.dmSans(fontSize: fsBodySm, color: darkTextSecondary),
        labelLarge: GoogleFonts.dmSans(
            fontSize: fsLabelLg, fontWeight: FontWeight.w600, color: darkText),
        labelSmall: GoogleFonts.dmSans(fontSize: fsLabelSm, color: darkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.dmSans(
          color: darkText,
          fontSize: fsTitleLg,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle:
              GoogleFonts.dmSans(fontSize: fsBodyLg, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: primaryLight, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: GoogleFonts.dmSans(color: darkTextSecondary, fontSize: fsBodyMd),
        labelStyle: GoogleFonts.dmSans(color: darkTextSecondary, fontSize: fsBodySm),
        errorStyle: GoogleFonts.dmSans(color: accent, fontSize: fsBodySm),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight;
          return darkBorder;
        }),
      ),
      dividerTheme:
          const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primaryLight.withValues(alpha: 0.15),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(
                fontSize: fsLabelSm,
                fontWeight: FontWeight.w600,
                color: primaryLight);
          }
          return GoogleFonts.dmSans(fontSize: fsLabelSm, color: darkTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return const IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.dmSans(
            color: darkText, fontSize: fsTitleLg, fontWeight: FontWeight.w700),
        contentTextStyle:
            GoogleFonts.dmSans(color: darkTextSecondary, fontSize: fsBodyMd),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: GoogleFonts.dmSans(color: darkText, fontSize: fsBodyMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
