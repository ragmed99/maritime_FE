import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Consistent spacing scale used across newly-built and redesigned widgets.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

/// Diffuse, low-opacity shadow tokens for the "elevated" card tier (hero
/// banners, KPI/metric cards, balance headers) as opposed to the flat
/// outlined cards used for dense lists and tables.
abstract final class AppShadows {
  static List<BoxShadow> soft(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> elevated(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.14),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Brand gradients reused across the auth screens, the nav shell header and
/// hero/KPI card accents so the "2026" gradient language stays consistent
/// instead of being redefined inline per screen.
abstract final class AppGradients {
  static LinearGradient hero(ColorScheme scheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
  );

  static LinearGradient subtleTint(ColorScheme scheme, Color background) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.primary.withValues(alpha: 0.08), background],
      );
}

/// Semantic colors for financial values (money owed to us, money we owe,
/// neutral/settled balances) that stay legible in both light and dark mode.
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  const MoneyColors({
    required this.positive,
    required this.negative,
    required this.neutral,
  });

  final Color positive;
  final Color negative;
  final Color neutral;

  static const light = MoneyColors(
    positive: Color(0xFF1E8E5A),
    negative: Color(0xFFD1435B),
    neutral: Color(0xFF64748B),
  );

  static const dark = MoneyColors(
    positive: Color(0xFF4ADE94),
    negative: Color(0xFFFF8A9B),
    neutral: Color(0xFF9AA6B7),
  );

  @override
  MoneyColors copyWith({Color? positive, Color? negative, Color? neutral}) =>
      MoneyColors(
        positive: positive ?? this.positive,
        negative: negative ?? this.negative,
        neutral: neutral ?? this.neutral,
      );

  @override
  MoneyColors lerp(ThemeExtension<MoneyColors>? other, double t) {
    if (other is! MoneyColors) return this;
    return MoneyColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

extension MoneyColorsX on BuildContext {
  MoneyColors get moneyColors => Theme.of(this).extension<MoneyColors>()!;
}

/// Centralized design system for the app: color schemes, typography and
/// component theming shared across iOS, Android and Windows desktop.
abstract final class AppTheme {
  static const _seed = Color(0xFF0B4A75);
  static const _brandAccent = Color(0xFF0E8C82);

  static const _radiusSmall = 12.0;
  static const _radiusMedium = 16.0;
  static const _radiusLarge = 20.0;
  static const _radiusXl = 28.0;

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );

  /// Cairo reads well in both Latin and Arabic scripts, so it carries the
  /// whole app instead of falling back to the platform default per locale.
  static TextTheme _textTheme(TextTheme base) {
    final cairo = GoogleFonts.cairoTextTheme(base);
    return cairo.copyWith(
      displaySmall: cairo.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineMedium: cairo.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall: cairo.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: cairo.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleMedium: cairo.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: cairo.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: cairo.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: cairo.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: cairo.bodyMedium?.copyWith(height: 1.4),
    );
  }

  static ThemeData light() => _build(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      secondary: _brandAccent,
      brightness: Brightness.light,
    ),
    moneyColors: MoneyColors.light,
    scaffoldBackground: const Color(0xFFF3F7FA),
    cardFill: Colors.white,
    inputFill: Colors.white,
  );

  static ThemeData dark() => _build(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      secondary: _brandAccent,
      brightness: Brightness.dark,
    ),
    moneyColors: MoneyColors.dark,
    scaffoldBackground: const Color(0xFF0E1620),
    cardFill: const Color(0xFF17212C),
    inputFill: const Color(0xFF17212C),
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required MoneyColors moneyColors,
    required Color scaffoldBackground,
    required Color cardFill,
    required Color inputFill,
  }) {
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    final outline = colorScheme.outlineVariant;
    final scaledText = _textTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: _pageTransitions,
      extensions: [moneyColors],
      textTheme: scaledText,
      primaryTextTheme: scaledText,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.16),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: scaledText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: cardFill,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          side: BorderSide(color: outline.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radiusSmall),
              ),
              animationDuration: const Duration(milliseconds: 180),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.hovered)
                    ? Colors.white.withValues(alpha: 0.08)
                    : null,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scaffoldBackground,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
        useIndicator: true,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
      ),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusXl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        surfaceTintColor: Colors.transparent,
        color: cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
        elevation: 6,
      ),
      chipTheme: base.chipTheme.copyWith(
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: outline.withValues(alpha: 0.5)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? colorScheme.primary.withValues(alpha: 0.06)
              : null,
        ),
        dividerThickness: 0.6,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        dataTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: 13.5),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        radius: const Radius.circular(8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardFill,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
        backgroundColor: cardFill,
        collapsedBackgroundColor: cardFill,
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
