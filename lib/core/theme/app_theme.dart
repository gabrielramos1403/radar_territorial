import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Monta os três temas do app: claro, escuro e alto contraste.
/// Todas as telas usam Theme.of(context), então não tem estilo repetido
/// espalhado pelos widgets.
class AppTheme {
  AppTheme._();

  static const _fonte = 'Nunito';

  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.primaria,
      primary: AppColors.primaria,
      secondary: AppColors.secundaria,
      surface: Colors.white,
      brightness: Brightness.light,
    );
    return _base(esquema, AppColors.fundoClaro);
  }

  static ThemeData escuro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.primaria,
      secondary: AppColors.secundaria,
      surface: AppColors.superficieEscura,
      brightness: Brightness.dark,
    );
    return _base(esquema, AppColors.fundoEscuro);
  }

  /// Tema de alto contraste: fundo preto, texto branco e destaque amarelo.
  static ThemeData altoContraste() {
    const esquema = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.altoContrasteDestaque,
      onPrimary: Colors.black,
      secondary: AppColors.altoContrasteDestaque,
      onSecondary: Colors.black,
      error: Color(0xFFFF8A80),
      onError: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF1C1C1C),
      onSurfaceVariant: Colors.white,
      outline: Colors.white,
      primaryContainer: Color(0xFF333000),
      onPrimaryContainer: Colors.white,
      secondaryContainer: Color(0xFF333000),
      onSecondaryContainer: Colors.white,
    );
    final tema = _base(esquema, AppColors.altoContrasteFundo);
    return tema.copyWith(
      cardTheme: CardThemeData(
        color: Colors.black,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.raio),
          side: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData _base(ColorScheme esquema, Color fundo) {
    final textos = _textos(esquema.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      fontFamily: _fonte,
      scaffoldBackgroundColor: fundo,
      textTheme: textos,
      appBarTheme: AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: esquema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textos.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: esquema.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.raio),
          side: BorderSide(color: esquema.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // mensagens de erro maiores não ficam cortadas
        errorMaxLines: 3,
        fillColor: esquema.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.raioPequeno),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: textos.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.raioPequeno),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: textos.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.raioPequeno),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textos.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.raioPequeno),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: esquema.surface,
        indicatorColor: esquema.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textos.labelMedium),
      ),
    );
  }

  static TextTheme _textos(Color cor) {
    return TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cor),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cor),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cor),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cor),
      bodyLarge: TextStyle(fontSize: 16, color: cor),
      bodyMedium: TextStyle(fontSize: 14, color: cor),
      bodySmall: TextStyle(fontSize: 12.5, color: cor.withValues(alpha: 0.85)),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
    );
  }
}
