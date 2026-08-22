import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const primary     = Color(0xFF1A3557);
  static const primaryDark = Color(0xFF0F2441);
  static const accent      = Color(0xFF2563EB);
  static const accentMid   = Color(0xFF0EA5E9);
  static const accentLight = Color(0xFF38BDF8);
  static const success     = Color(0xFF16A34A);
  static const warning     = Color(0xFFD97706);
  static const surface     = Color(0xFFFFFFFF);
  static const background  = Color(0xFFF8FAFC);
  static const authBg      = Color(0xFFF0F7FF);
  static const border      = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
  static const textPrimary    = Color(0xFF0F172A);
  static const textSecondary  = Color(0xFF64748B);
  static const textDisabled   = Color(0xFFCBD5E1);

  static const successBg  = Color(0xFFDCFCE7);
  static const warningBg  = Color(0xFFFEF3C7);
  static const neutralBg  = Color(0xFFF1F5F9);
  static const accentBg   = Color(0xFFEFF6FF);

  static const successText = Color(0xFF14532D);
  static const warningText = Color(0xFF78350F);

  static const dangerBg   = Color(0xFFFEE2E2);
  static const dangerText = Color(0xFF991B1B);

  // Legacy — kept for any remaining references
  static const gradientStart = Color(0xFF1A3557);
  static const gradientEnd   = Color(0xFF1A4480);
}

// ── Radii ─────────────────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double card   = 16;
  static const double field  = 12;
  static const double button = 14;
  static const double sheet  = 24;
}

// ── Spacing scale ─────────────────────────────────────────────────────────────

/// Named spacing scale — replaces ad hoc EdgeInsets/SizedBox magic numbers
/// in screens built or upgraded as part of the design-system foundation.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// ── Motion tokens ────────────────────────────────────────────────────────────

/// Named animation durations/curves — replaces scattered per-widget
/// `Duration(milliseconds: N)` literals in screens built or upgraded as
/// part of the design-system foundation.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve standard = Curves.easeOutCubic;
}

// ── Gradients ─────────────────────────────────────────────────────────────────

class AppGradients {
  AppGradients._();

  static const button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
  );

  static const authDecoration = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3557), Color(0xFF2563EB), Color(0xFF38BDF8)],
    stops: [0.0, 0.6, 1.0],
  );

  /// Contained-hero gradient — used by HeroHeader and the Login banner.
  /// Medium-saturated blue to soft pastel green, matching the reference
  /// design exactly (blue-dominant, green as the secondary accent). The
  /// blue stop is deliberately not ultra-pale — it needs to stay dark
  /// enough for the white greeting/name text drawn on top of it.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F86E8), Color(0xFF8FE3A9)],
  );

  /// Per-feature-area identity gradients — used on section headers, stat
  /// cards, and icon chips for that area. Distinct from [button] (the one
  /// universal action-gradient) and [hero] (the app's own brand chrome,
  /// used by HeroHeader).
  static const portal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
  );

  static const attendance = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
  );

  static const grades = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
  );
}

// ── Typography helpers ────────────────────────────────────────────────────────

TextStyle _pjs({
  required double size,
  required FontWeight weight,
  Color color = AppColors.textPrimary,
  double? height,
  double letterSpacing = 0,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

/// Canonical text styles. One-off tweaks should use `.copyWith(...)` on the
/// nearest style rather than calling GoogleFonts directly — theme.dart is the
/// only file that may import google_fonts.
class AppTextStyles {
  AppTextStyles._();

  /// Large screen/page title (AppHeader name line).
  static TextStyle get screenTitle =>
      _pjs(size: 22, weight: FontWeight.w800, letterSpacing: -0.3);

  /// Section heading inside a screen body.
  static TextStyle get sectionHeader => _pjs(size: 18, weight: FontWeight.w700);

  /// App-bar / prominent tile title.
  static TextStyle get title => _pjs(size: 17, weight: FontWeight.w700);

  /// Card heading.
  static TextStyle get cardTitle => _pjs(size: 15, weight: FontWeight.w700);

  /// Large stat figure (counts, grades).
  static TextStyle get stat =>
      _pjs(size: 20, weight: FontWeight.w800, letterSpacing: -0.3);

  /// Default paragraph text.
  static TextStyle get body => _pjs(size: 14, weight: FontWeight.w400, height: 1.5);

  static TextStyle get bodyMedium => _pjs(size: 14, weight: FontWeight.w500);

  static TextStyle get bodySemibold => _pjs(size: 14, weight: FontWeight.w600);

  /// Secondary line under a card title.
  static TextStyle get cardSubtitle =>
      _pjs(size: 13, weight: FontWeight.w400, color: AppColors.textSecondary);

  /// Small muted text.
  static TextStyle get caption =>
      _pjs(size: 12, weight: FontWeight.w400, color: AppColors.textSecondary);

  /// Form-field / small emphasis label.
  static TextStyle get fieldLabel =>
      _pjs(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary);

  /// Tiny uppercase-style label.
  static TextStyle get label => _pjs(
      size: 11, weight: FontWeight.w600,
      color: AppColors.textSecondary, letterSpacing: 0.7);

  /// Button text (white, for filled/gradient buttons).
  static TextStyle get button => _pjs(
      size: 15, weight: FontWeight.w600,
      color: Colors.white, letterSpacing: 0.3);

  /// Escape hatch for one-off styles that no semantic token covers.
  /// Leaves unset properties inheriting from the ambient DefaultTextStyle.
  static TextStyle custom({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

// ── Theme ─────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        secondary: AppColors.accentMid,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ).copyWith(surface: AppColors.surface),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: _pjs(size: 17, weight: FontWeight.w700),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: AppColors.accent,
        indicatorShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 22);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _pjs(size: 11, weight: FontWeight.w600, color: AppColors.accent);
          }
          return _pjs(size: 11, weight: FontWeight.w500, color: AppColors.textSecondary);
        }),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(88, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: _pjs(size: 15, weight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(88, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: _pjs(size: 14, weight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        labelStyle: _pjs(size: 14, weight: FontWeight.w400,
            color: AppColors.textSecondary),
        hintStyle: _pjs(size: 14, weight: FontWeight.w400,
            color: AppColors.textDisabled),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: _pjs(size: 13, weight: FontWeight.w400,
            color: Colors.white),
      ),
    );
  }
}

// ── Shadows ───────────────────────────────────────────────────────────────────

/// Soft resting shadow for all cards.
const kCardShadow = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 20,
    spreadRadius: 0,
    offset: Offset(0, 4),
  ),
  BoxShadow(
    color: Color(0x06000000),
    blurRadius: 6,
    spreadRadius: 0,
    offset: Offset(0, 1),
  ),
];

/// Deep shadow for floating form cards (auth screens).
const kFormShadow = [
  BoxShadow(
    color: Color(0x10000000),
    blurRadius: 32,
    spreadRadius: 0,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x07000000),
    blurRadius: 8,
    spreadRadius: 0,
    offset: Offset(0, 2),
  ),
];

/// Upward shadow for the floating bottom nav bar.
const kNavShadow = [
  BoxShadow(
    color: Color(0x14000000),
    blurRadius: 20,
    spreadRadius: 0,
    offset: Offset(0, -4),
  ),
  BoxShadow(
    color: Color(0x08000000),
    blurRadius: 6,
    spreadRadius: 0,
    offset: Offset(0, -1),
  ),
];

// ── Elevation scale ──────────────────────────────────────────────────────────

/// Named elevation tiers for the design-system foundation. `resting` and
/// `raised` alias the existing [kCardShadow]/[kFormShadow] values so every
/// current usage of those constants stays visually identical — this only
/// gives the scale a name. `floating` is new: a deeper tier for elements
/// that must read as detached from the page (e.g. a raised nav button).
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> resting = kCardShadow;
  static const List<BoxShadow> raised = kFormShadow;
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 28,
      spreadRadius: 0,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];
}

// ── Gradient button ───────────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final Widget? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: enabled ? AppGradients.button : null,
        color: !enabled ? AppColors.accent.withValues(alpha: 0.4) : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(text,
                          style: _pjs(
                              size: 15,
                              weight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── App header (white, light) ─────────────────────────────────────────────────

class AppHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  final List<Widget> actions;

  /// Optional widget before the text block (e.g. a back button on pushed
  /// screens).
  final Widget? leading;

  const AppHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: AppElevation.resting,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              leading == null ? AppSpacing.xl : AppSpacing.sm,
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: _pjs(
                            size: 12,
                            weight: FontWeight.w400,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(name,
                        style: _pjs(
                            size: 22,
                            weight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: _pjs(
                            size: 12,
                            weight: FontWeight.w400,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Accent card ───────────────────────────────────────────────────────────────

class AccentCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;
  final VoidCallback? onTap;

  const AccentCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          splashColor: accentColor.withValues(alpha: 0.06),
          highlightColor: accentColor.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border(
                left: BorderSide(color: accentColor, width: 4),
              ),
              boxShadow: kCardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
}

// ── Status badge ──────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String? status;

  const StatusBadge({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final isIn  = status == 'in';
    final isOut = status == 'out';
    final color = isIn
        ? AppColors.success
        : isOut
            ? AppColors.warning
            : AppColors.textSecondary;
    final bg = isIn
        ? AppColors.successBg
        : isOut
            ? AppColors.warningBg
            : AppColors.neutralBg;
    final label = isIn
        ? 'At School'
        : isOut
            ? 'Left School'
            : 'No Scan Today';
    final icon = isIn
        ? Icons.check_circle_rounded
        : isOut
            ? Icons.home_rounded
            : Icons.radio_button_unchecked_rounded;

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: _pjs(
                    size: 12,
                    weight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(text,
                style: _pjs(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
          ],
        ),
      );
}

// ── Labelled field ────────────────────────────────────────────────────────────

class LabelledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabelledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: _pjs(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          child,
        ],
      );
}
