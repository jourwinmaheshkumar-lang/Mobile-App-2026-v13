import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Zomato-inspired Design System for Director Management & Reporting App
class AppTheme {
  // Primary Color Palette
  static const primary = Color(0xFFFA425A);          // Coral Red
  static const secondary = Color(0xFFF37950);        // Warm Orange
  static const accent = Color(0xFF813563);           // Deep Purple
  
  // Semantic Colors  
  static const success = Color(0xFF1E9D8A);          // Teal
  static const warning = Color(0xFFF6BC59);          // Golden Yellow
  static const error = Color(0xFFFA425A);            // Coral Red
  static const info = Color(0xFF813563);             // Deep Purple (Accent)
  
  // Neutral Colors
  static const background = Color(0xFFF8F4F6);       // Light Blush
  static const surface = Color(0xFFFFFFFF);          // Card Surface
  static const border = Color(0xFFF0ECF0);           // Divider Color
  
  // Text Colors
  static const textPrimary = Color(0xFF2D1B2E);      // Dark Purple-Black
  static const textSecondary = Color(0xFF6B4C6B);    // Muted Purple-Gray
  static const textTertiary = Color(0xFFB09AB0);     // Hint Text
  static const textOnPrimary = Color(0xFFFFFFFF);    // White Text
  
  // Legacy / Missing Aliases to fix other screens
  static const cardSurface = surface;
  static const borderLight = Color(0xFFF0ECF0);
  static const hintText = textTertiary;
  static const surfaceVariant = Color(0xFFF8F4F6); // Using light blush
  
  // Dark Mode Legacy (Keeping these compatible)
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceVariant = Color(0xFF2C2C2C);
  static const darkBorderLight = Color(0xFF333333);
  static const darkBorder = Color(0xFF444444);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFCCCCCC);
  static const darkTextTertiary = Color(0xFFAAAAAA);
  
  // Shadows
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Gradient Presets (Hoodie Palette)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary], // FA425A -> F37950
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary], // 813563 -> FA425A
  );
  
  static const LinearGradient statHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, warning], // F37950 -> F6BC59
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, warning], // 1E9D8A -> F6BC59
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1B2E), Color(0xFF813563)], // Dark purple blend
  );
  
  static const LinearGradient blueGradient = premiumGradient; // Redirecting to premium for compatibility if used elsewhere
  
  // Shadow Presets (Zomato-style soft shadow)
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Border Radius Presets
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;

  // Spacing Presets
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        tertiary: success,
        surface: surface,
        background: background,
        error: error,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textOnPrimary,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: surface,
      dividerColor: border,
      
      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.3),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.3),
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.3),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.3),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.3),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: accent, letterSpacing: 0.3),
        titleMedium: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.3),
        titleSmall: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.3),
        bodyLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, letterSpacing: 0.1),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, letterSpacing: 0.1),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textTertiary, letterSpacing: 0.1),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, letterSpacing: 0.1),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.1),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: primary, letterSpacing: 0.1),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: Color(0xFFE8E0E8), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: Color(0xFFE8E0E8), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        hintStyle: GoogleFonts.inter(
          color: textTertiary,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        labelStyle: TextStyle(color: textSecondary),
        floatingLabelStyle: TextStyle(color: primary),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5E8EF), // Purple tint
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: accent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
      ),
      
      // TabBar Theme
      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: primary,
        unselectedLabelColor: textTertiary,
        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Dark Theme (Aligned with the new palette)
  static ThemeData get darkTheme => lightTheme; 
}

/// Reusable UI Components
class AppComponents {
  /// Zomato-style Card Container
  static Widget card({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    List<BoxShadow>? shadow,
    double? borderRadius,
    Border? border,
    VoidCallback? onTap,
  }) {
    final container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLG),
        boxShadow: shadow ?? AppTheme.softShadow,
        border: border,
      ),
      child: child,
    );
    
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppTheme.primary.withOpacity(0.1),
          highlightColor: AppTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLG),
          child: container,
        ),
      );
    }
    return container;
  }
  
  /// Zomato-style Gradient AppBar background
  static Widget appBarGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
    );
  }

  /// KPI / Summary Stat Card
  static Widget kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool animateValue = true,
  }) {
    return card(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Status Badge (Updated to support both old and new styles)
  static Widget statusBadge(String label, [dynamic typeLegacy, String? typeNamed]) {
    String typeStr = "info";
    Color? customColor;

    if (typeLegacy is Color) {
      customColor = typeLegacy;
      typeStr = "custom";
    } else if (typeLegacy is String) {
      typeStr = typeLegacy;
    } else if (typeNamed != null) {
      typeStr = typeNamed;
    }

    Color bg;
    Color text;
    
    if (typeStr == 'custom' && customColor != null) {
      bg = customColor.withOpacity(0.12);
      text = customColor;
    } else {
      switch (typeStr) {
        case 'success':
        case 'approved':
          bg = const Color(0xFFE3F5F2);
          text = const Color(0xFF1E9D8A);
          break;
        case 'warning':
        case 'pending':
          bg = const Color(0xFFFEF8E8);
          text = const Color(0xFFC9920A);
          break;
        case 'error':
        case 'rejected':
          bg = const Color(0xFFFEE9EC);
          text = AppTheme.error;
          break;
        default:
          bg = const Color(0xFFF5E8EF);
          text = AppTheme.accent;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }
}
