import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/acessibilidade_provider.dart';
import 'providers/tema_provider.dart';
import 'screens/main_layout_screen.dart';

// Paleta de marca
const Color kBrand     = Color(0xFFFF6B35); // laranja de marca
const Color kBrandDark = Color(0xFFFF7A30); // laranja quente e vivo, natural

// Fundos
const Color kLightBg   = Color(0xFFF4F5F8); // cinza claro suave
const Color kLightCard = Color(0xFFFFFFFF);
const Color kDarkBg    = Color(0xFF0D0E11); // preto suave neutro (True Dark Apple style)
const Color kDarkCard  = Color(0xFF16171B); // cinzento-carvão escuro neutro elevado
const Color kDarkCard2 = Color(0xFF202227); // superfície secundária cinza-escuro neutra

class PirApp extends StatelessWidget {
  const PirApp({super.key});

  @override
  Widget build(BuildContext context) {
    final temaProvider = context.watch<TemaProvider>();
    final accProvider = context.watch<AcessibilidadeProvider>();
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = switch (temaProvider.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TemaProvider.syncTitleBar(isDark);
    });

    final lightTheme = _buildLightTheme(accProvider.altoContraste);
    final darkTheme = _buildDarkTheme(accProvider.altoContraste);

    return MaterialApp(
      title: 'PIR - Perigo de Incendio Rural',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.unknown,
        },
      ),
      themeMode: temaProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(accProvider.textScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainLayoutScreen(),
    );
  }

  ThemeData _buildLightTheme([bool altoContraste = false]) {
    final cs = ColorScheme.fromSeed(
      seedColor: kBrand,
      brightness: Brightness.light,
    ).copyWith(
      primary: altoContraste ? const Color(0xFFC43A00) : kBrand,
      onPrimary: Colors.white,
      secondary: altoContraste ? const Color(0xFFC43A00) : kBrand,
      surface: kLightCard,
      onSurface: altoContraste ? Colors.black : const Color(0xFF1C1C1E),
      surfaceContainerHighest: altoContraste ? const Color(0xFFDEDFE5) : const Color(0xFFE9EAEF),
      outline: altoContraste ? const Color(0xFF333333) : const Color(0xFF79747E),
      outlineVariant: altoContraste ? const Color(0xFF555555) : const Color(0xFFE0E2EA),
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ).apply(
      bodyColor: altoContraste ? Colors.black : const Color(0xFF1C1C1E),
      displayColor: altoContraste ? Colors.black : const Color(0xFF1C1C1E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: altoContraste ? Colors.white : kLightBg,
      textTheme: baseTextTheme,
      splashColor: Colors.transparent,
      highlightColor: cs.primary.withValues(alpha: 0.06),
      hoverColor: Colors.black.withValues(alpha: 0.03),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: altoContraste ? FontWeight.bold : FontWeight.w700,
          letterSpacing: -0.3,
          color: altoContraste ? Colors.black : const Color(0xFF1C1C1E),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: kLightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: altoContraste ? Colors.black : const Color(0x12000000),
            width: altoContraste ? 1.5 : 0.8,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kLightCard.withValues(alpha: 0.94),
        indicatorColor: (altoContraste ? const Color(0xFFC43A00) : kBrand).withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.1,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: kLightCard,
        indicatorColor: (altoContraste ? const Color(0xFFC43A00) : kBrand).withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: DividerThemeData(
        color: altoContraste ? const Color(0x40000000) : const Color(0x10000000),
        thickness: altoContraste ? 1.2 : 0.8,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: altoContraste ? const Color(0xFFC43A00) : kBrand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            letterSpacing: -0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: altoContraste ? Colors.black : const Color(0x10000000),
            width: altoContraste ? 1.2 : 0.8,
          ),
        ),
        backgroundColor: const Color(0xFFEBECEF),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          letterSpacing: 0.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: altoContraste ? const Color(0xFFC43A00) : kBrand,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kLightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: altoContraste ? Colors.black : const Color(0x16000000),
            width: altoContraste ? 1.5 : 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: altoContraste ? Colors.black : const Color(0x16000000),
            width: altoContraste ? 1.5 : 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: altoContraste ? const Color(0xFFC43A00) : kBrand,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme([bool altoContraste = false]) {
    final cs = ColorScheme.fromSeed(
      seedColor: kBrand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: altoContraste ? const Color(0xFFFF9E66) : kBrandDark,
      onPrimary: Colors.black,
      secondary: altoContraste ? const Color(0xFFFF9E66) : kBrandDark,
      surface: altoContraste ? Colors.black : kDarkCard,
      onSurface: Colors.white,
      surfaceContainerHighest: altoContraste ? const Color(0xFF1B1D22) : kDarkCard2,
      outline: altoContraste ? const Color(0xFFAAAAAA) : const Color(0xFF5A5C66),
      outlineVariant: altoContraste ? const Color(0xFF444444) : const Color(0xFF26282E),
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: altoContraste ? Colors.black : kDarkBg,
      textTheme: baseTextTheme,
      splashColor: Colors.transparent,
      highlightColor: cs.primary.withValues(alpha: 0.08),
      hoverColor: Colors.white.withValues(alpha: 0.03),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: altoContraste ? FontWeight.bold : FontWeight.w700,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: altoContraste ? const Color(0xFF0F1014) : kDarkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: altoContraste ? Colors.white70 : const Color(0x16FFFFFF),
            width: altoContraste ? 1.5 : 0.8,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kDarkCard.withValues(alpha: 0.96),
        indicatorColor: kBrandDark.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.1,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: kDarkCard,
        indicatorColor: kBrandDark.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x16FFFFFF),
        thickness: 0.8,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kBrandDark,
          foregroundColor: kDarkBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: -0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0x16FFFFFF), width: 0.8),
        ),
        backgroundColor: kDarkCard2,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
          letterSpacing: 0.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kBrandDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kDarkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x22FFFFFF), width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x22FFFFFF), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBrandDark, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0x70FFFFFF)),
      ),
    );
  }
}
