import 'package:flutter/material.dart';

abstract final class AppColors {
  static const galleryWhite = Color(0xFFFFFFFF);
  static const studioMist = Color(0xFFF5F5F7);
  static const paperFrost = Color(0xFFFAFAFC);
  static const hairlineSilver = Color(0xFFD6D6D6);
  static const controlGray = Color(0xFFE6E6E8);
  static const ink = Color(0xFF1D1D1F);
  static const slate = Color(0xFF707070);
  static const steel = Color(0xFF86868B);
  static const appleBlue = Color(0xFF0066CC);
  static const pricingBlue = Color(0xFF0071E3);
  static const error = Color(0xFFB42318);
  static const errorContainer = Color(0xFFFCE8E6);
  static const onErrorContainer = Color(0xFF7A271A);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.appleBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.appleBlue,
          onPrimary: AppColors.galleryWhite,
          secondary: AppColors.ink,
          onSecondary: AppColors.galleryWhite,
          surface: AppColors.studioMist,
          onSurface: AppColors.ink,
          outline: AppColors.steel,
          outlineVariant: AppColors.hairlineSilver,
          error: AppColors.error,
          onError: AppColors.galleryWhite,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
        );

    const textTheme = TextTheme(
      displayLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 40,
        height: 1.05,
        letterSpacing: -1,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 34,
        height: 1.08,
        letterSpacing: -0.7,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        height: 1.14,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        height: 1.21,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        height: 1.29,
        letterSpacing: -0.15,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        height: 1.33,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        height: 1.45,
        letterSpacing: -0.2,
      ),
      bodyMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        height: 1.4,
        letterSpacing: -0.1,
      ),
      bodySmall: TextStyle(color: AppColors.slate, fontSize: 13, height: 1.38),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.33,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.33,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 1.33,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w500,
      ),
    );

    const cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    );
    const controlShape = StadiumBorder();
    const inputRadius = BorderRadius.all(Radius.circular(20));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.studioMist,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.galleryWhite,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 19,
          height: 1.2,
          letterSpacing: 0.1,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.ink, size: 22),
        shape: Border(
          bottom: BorderSide(color: AppColors.hairlineSilver, width: 1),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.galleryWhite,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: cardShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.galleryWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.slate),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.slate),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.appleBlue,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.hairlineSilver),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.hairlineSilver),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.appleBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.appleBlue,
          foregroundColor: AppColors.galleryWhite,
          disabledBackgroundColor: AppColors.controlGray,
          disabledForegroundColor: AppColors.slate,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
          side: const BorderSide(color: AppColors.steel, width: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.appleBlue,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paperFrost,
        selectedColor: AppColors.controlGray,
        disabledColor: AppColors.controlGray,
        secondarySelectedColor: AppColors.paperFrost,
        labelStyle: textTheme.labelSmall!.copyWith(color: AppColors.ink),
        secondaryLabelStyle: textTheme.labelSmall!.copyWith(
          color: AppColors.slate,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        side: const BorderSide(color: AppColors.hairlineSilver, width: 1),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.galleryWhite,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.studioMist,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: isSelected ? AppColors.ink : AppColors.slate,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.appleBlue : AppColors.slate,
            size: 22,
          );
        }),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.galleryWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairlineSilver,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.appleBlue,
        linearTrackColor: AppColors.hairlineSilver,
        circularTrackColor: AppColors.hairlineSilver,
        linearMinHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.galleryWhite,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
