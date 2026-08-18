import 'dart:ui';

class AppThemeData {
  // ── Surface & Background ──
  static Color surface50 = const Color(0xFFF7F8FB);       // Cool-tinted white
  static Color surface50Dark = const Color(0xFF111827);    // Deep ink night

  // ── Primary Palette (Emerald Green Brand) ──
  static Color primary50 = const Color(0xFFECFDF5);       // Lightest green tint
  static Color primary200 = const Color(0xFF10B981);       // Confident emerald green
  static Color primary300 = const Color(0xFF059669);       // Deep emerald
  static Color primary300Dark = const Color(0xFF34D399);   // Light emerald for dark mode

  // ── Neutral / Grey Scale ──
  static Color grey50 = const Color(0xFF1B2138);           // Ink heading
  static Color grey50Dark = const Color(0xFFF0F1F5);       // Light text on dark
  static Color grey300 = const Color(0xFFDDE1EA);          // Soft border
  static Color grey300Dark = const Color(0xFF2A3044);      // Dark border
  static Color grey900 = const Color(0xFF1B2138);          // Heading ink
  static Color grey900Dark = const Color(0xFFF0F1F5);      // Heading on dark
  static Color grey500 = const Color(0xFF5A6178);          // Muted body text
  static Color grey500Dark = const Color(0xFFB0B7C9);      // Muted on dark
  static Color grey100 = const Color(0xFFECEEF4);          // Section bg
  static Color grey100Dark = const Color(0xFF1E2436);      // Section bg dark
  static Color grey400Dark = const Color(0xFFA3ABBE);
  static Color grey400 = const Color(0xFF7E8699);
  static Color grey200 = const Color(0xFFDDE1EA);
  static Color grey200Dark = const Color(0xFF2A3044);
  static Color grey800 = const Color(0xFF1E2436);
  static Color grey800Dark = const Color(0xFFF0F1F5);

  // ── Accent (Warm Coral & Success) ──
  static Color yellow = const Color(0xFFFFF0EB);           // Coral tint bg
  static Color warning200 = const Color(0xFFFF6B4A);       // Warm coral accent
  static Color success300 = const Color(0xFF10B981);       // Active / success green
  static Color success50 = const Color(0xFFECFDF5);
  static Color secondary50 = const Color(0xFFFFF5F0);
  static Color secondary200 = const Color(0xFFFF6B4A);     // Coral
  static Color secondar300 = const Color(0xFFFFB199);
  static Color secondary300 = const Color(0xFFE54D2E);
  static Color pink = const Color(0xFFFFDDD4);
  static Color pink2 = const Color(0xFFFFE5E8);
  static Color error200 = const Color(0xFFDC2626);
  static Color error50 = const Color(0xFFFEF2F2);
  static Color blue200 = const Color(0xFFECFDF5);
  static Color referBgone = const Color(0xFF0F1B3D);
  static Color referBgtwo = const Color(0xFF1A2E6B);
  static Color info200 = const Color(0xFF3B82F6);
  static Color loadingBgColor = const Color(0xFFF7F8FB);

  // ── Typography (Switzer family) ──
  static const String black = 'Switzer-Black';
  static const String bold = 'Switzer-Bold';
  static const String extraBold = 'Switzer-Extrabold';
  static const String extraLight = 'Switzer-Extralight';
  static const String light = 'Switzer-Italic';
  static const String medium = 'Switzer-Medium';
  static const String regular = 'Switzer-Regular';
  static const String semiBold = 'Switzer-Semibold';
  static const String thin = 'Switzer-Thin';

  static get grey700 => null;

  static void applyThemeColor(String colorHex) {
    try {
      String hex = colorHex.replaceAll("#", "").trim();
      if (hex.length == 6) {
        hex = "FF$hex";
      }
      final color = Color(int.parse(hex, radix: 16));
      primary200 = color;
      ConstantColors.primary = color;
      ConstantColors.blue = color;
    } catch (_) {}
  }
}

class ConstantColors {
  static Color primary = const Color(0xFF10B981);          // Emerald green
  static Color blue = const Color(0xFF10B981);
  static Color yellow = const Color(0xFFFF6B4A);           // Warm coral (CTA)
  static Color yellow1 = const Color(0xFFFF8866);
  static Color background = const Color(0xFFF7F8FB);       // Cool-tinted white
  static Color titleTextColor = const Color(0xFF1B2138);   // Ink heading
  static Color subTitleTextColor = const Color(0xFF5A6178); // Muted body
  static Color hintTextColor = const Color(0xFF7E8699);     // Hint text
  static Color textFieldBoarderColor = const Color(0xFFDDE1EA); // Borders
}
