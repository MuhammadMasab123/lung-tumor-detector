import 'package:flutter/material.dart';

/// App theme — same colours as the LungTumorDetector web app.
class AppColors {
  static const Color navy = Color(0xFF080D1A);
  static const Color navy2 = Color(0xFF0E1628);
  static const Color mint = Color(0xFF00C896);
  static const Color mintDark = Color(0xFF059669);
  static const Color mintDim = Color(0xFFE6F9F2);
  static const Color red = Color(0xFFFF3B3B);
  static const Color redDark = Color(0xFFDC2626);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color blue = Color(0xFF2563EB);
  static const Color canvas = Color(0xFFF5F4F0);
  static const Color stone = Color(0xFFE8E6E0);
  static const Color ink = Color(0xFF0F1117);
  static const Color ink2 = Color(0xFF3D3D3D);
  static const Color muted = Color(0xFF7A7975);
  static const Color faint = Color(0xFFA8A6A0);

  /// Verdict colour: green = Non-Cancerous, red = Cancerous, amber = Uncertain.
  static Color verdictColor(String prediction) {
    if (prediction == 'Cancerous') return redDark;
    if (prediction == 'Uncertain') return amberDark;
    return const Color(0xFF16A34A);
  }

  static Color verdictBg(String prediction) {
    if (prediction == 'Cancerous') return const Color(0xFFFEE2E2);
    if (prediction == 'Uncertain') return const Color(0xFFFEF3C7);
    return const Color(0xFFDCFCE7);
  }

  static Color riskColor(String risk) {
    if (risk == 'High') return redDark;
    if (risk == 'Moderate') return amberDark;
    if (risk == 'Low') return blue;
    return const Color(0xFF16A34A);
  }
}

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      primary: AppColors.mint,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.navy,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.stone),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.stone),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.mint, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.stone),
      ),
    ),
  );
}

/// Small shared widgets used across screens.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The little mint logo square with a pulse line, like the web app header.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.monitor_heart,
        color: AppColors.navy,
        size: size * 0.6,
      ),
    );
  }
}
