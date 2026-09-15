import 'package:flutter/material.dart';

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

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );

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

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: _pageTransitions,
      extensions: [moneyColors],
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.16),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
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
        style: FilledButton.styleFrom(
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
          borderRadius: BorderRadius.circular(_radiusMedium),
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
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
        ),
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
          borderRadius: BorderRadius.circular(_radiusLarge),
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
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? colorScheme.primary.withValues(alpha: 0.06)
              : null,
        ),
        dividerThickness: 0.6,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
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
    );
  }
}
