import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep navy command-center palette
  static const Color background = Color(0xFF080B13); // HSL(226, 47%, 6%)
  static const Color card = Color(0xFF0E111B); // HSL(225, 38%, 9%)
  static const Color popover = Color(0xFF0D101A); // HSL(225, 40%, 8%)

  // Indigo Primary
  static const Color primary = Color(0xFF7C3AED); // HSL(244, 92%, 66%)
  static const Color primaryGlow = Color(0xFFA78BFA); // HSL(244, 100%, 75%)
  static const Color primaryForeground = Colors.white;

  // Electric Blue Accent
  static const Color accent = Color(0xFF38BDF8); // HSL(198, 100%, 60%)
  static const Color accentForeground = Color(0xFF080B13);

  // Status Colors
  static const Color destructive = Color(0xFFEF4444); // HSL(358, 85%, 60%)
  static const Color warning = Color(0xFFF59E0B); // HSL(38, 95%, 58%)
  static const Color success = Color(0xFF10B981); // HSL(152, 76%, 48%)

  // Muted Colors
  static const Color muted = Color(0xFF1E212E); // HSL(225, 25%, 13%)
  static const Color mutedForeground = Color(0xFF94A3B8); // HSL(220, 14%, 62%)

  // Border & Glass
  static const Color border = Color(0xFF202738); // HSL(224, 30%, 18%)
  static const Color glassBorder = Color(0x14E2E8F0); // HSL(220, 100%, 90%) / 0.08
  static const Color glassHighlight = Color(0x0AE2E8F0); // HSL(220, 100%, 95%) / 0.04
  static const Color glassBackground = Color(0x8C1E263D); // HSL(225, 35%, 12%) / 0.55

  // Secondary
  static const Color secondary = Color(0xFF1E293B); // HSL(222, 33%, 17%)
  // Severity Colors (Semantic)
  static const Color severityCritical = Color(0xFFEF4444);
  static const Color severityHigh = Color(0xFFF97316);
  static const Color severityMedium = Color(0xFF3B82F6);
  static const Color severityInfo = Color(0xFF10B981);
}

class AppGradients {
  static const LinearGradient indigo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)], 
  );

  static const LinearGradient purpleGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
  );

  static const LinearGradient electric = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF60A5FA)],
  );

  static const LinearGradient tealGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
  );

  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
  );

  static const LinearGradient orangeGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const RadialGradient mesh = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      Color(0x800F172A),
      Color(0xFF080B13),
    ],
  );
}

class AppTextStyles {
  static TextStyle heading({
    double fontSize = 24,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: -0.02,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  static TextStyle mono({
    double fontSize = 12,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
