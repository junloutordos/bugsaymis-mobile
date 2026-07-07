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

  // Legacy — kept for any remaining references
  static const gradientStart = Color(0xFF1A3557);
  static const gradientEnd   = Color(0xFF1A4480);
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

class AppTextStyles {
  AppTextStyles._();

  static TextStyle screenTitle(BuildContext context) =>
      _pjs(size: 22, weight: FontWeight.w800, letterSpacing: -0.3);

  static TextStyle sectionHeader(BuildContext context) =>
      _pjs(size: 18, weight: FontWeight.w700);

  static TextStyle cardTitle(BuildContext context) =>
      _pjs(size: 15, weight: FontWeight.w700);

  static TextStyle body(BuildContext context) =>
      _pjs(size: 14, weight: FontWeight.w400, height: 1.5);

  static TextStyle bodyMedium(BuildContext context) =>
      _pjs(size: 14, weight: FontWeight.w500);

  static TextStyle caption(BuildContext context) =>
      _pjs(size: 12, weight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle label(BuildContext context) =>
      _pjs(size: 11, weight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.7);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(88, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _pjs(size: 15, weight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(88, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _pjs(size: 14, weight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

const _cardShadow = [
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
        borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
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

  const AppHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
            const Divider(height: 1),
          ],
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
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withValues(alpha: 0.06),
          highlightColor: accentColor.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border(
                left: BorderSide(color: accentColor, width: 4),
              ),
              boxShadow: _cardShadow,
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
