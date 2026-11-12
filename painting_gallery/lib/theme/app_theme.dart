import 'package:flutter/material.dart';

/// 颜色取自原型 painting-gallery-m3.html 的 CSS 变量，保持视觉一致。
class AppColors {
  const AppColors._();

  static const Color surface = Color(0xFFFDFBFE);
  static const Color surfaceDim = Color(0xFFEFE8F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFAF5FD);
  static const Color surfaceContainer = Color(0xFFF5EDFA);
  static const Color surfaceContainerHigh = Color(0xFFF0E5F8);
  static const Color surfaceContainerHighest = Color(0xFFEADFF4);
  static const Color onSurface = Color(0xFF241E2C);
  static const Color onSurfaceVariant = Color(0xFF5E5569);
  static const Color outline = Color(0xFF8C8297);
  static const Color outlineVariant = Color(0xFFDDD3E8);
  static const Color primary = Color(0xFF9376DE);
  static const Color primaryContainer = Color(0xFFEFE3FC);
  static const Color danger = Color(0xFFB44876);
  static const Color like = Color(0xFFD24A7A);
  static const Color snackbar = Color(0xFF2B2338);

  /// 原型中的半透明白色卡片底色（避免使用 withOpacity，兼容旧版 Flutter）。
  static const Color white78 = Color(0xC7FFFFFF);
  static const Color white62 = Color(0x9EFFFFFF);
  static const Color white72 = Color(0xB8FFFFFF);
  static const Color white86 = Color(0xDBFFFFFF);
  static const Color page86 = Color(0xDBFDFBFE);
  static const Color page82 = Color(0xD1FDFBFE);

  static const Color cardShadow = Color(0x248B6CBE);
  static const Color dividerShadow = Color(0x38A88FCD);
}

/// 原型中的渐变背景 / 渐变按钮。
class AppGradients {
  const AppGradients._();

  static const LinearGradient page = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: <Color>[Color(0xFFFCE9F4), Color(0xFFF2EBFD), Color(0xFFE8F3FE)],
    stops: <double>[0, 0.48, 1],
  );

  static const LinearGradient splash = LinearGradient(
    begin: Alignment(-0.45, -1),
    end: Alignment(0.45, 1),
    colors: <Color>[Color(0xFFF9D7EC), Color(0xFFE4D7F9), Color(0xFFD3E9FC)],
    stops: <double>[0, 0.5, 1],
  );

  static const LinearGradient button = LinearGradient(
    begin: Alignment(-1, -0.55),
    end: Alignment(1, 0.55),
    colors: <Color>[Color(0xFFF177AE), Color(0xFFA87BE8), Color(0xFF6F9BF2)],
    stops: <double>[0, 0.52, 1],
  );

  static const LinearGradient chip = LinearGradient(
    begin: Alignment(-1, -0.4),
    end: Alignment(1, 0.4),
    colors: <Color>[Color(0xFFFBD8EA), Color(0xFFE2D8F9), Color(0xFFD6E8FC)],
    stops: <double>[0, 0.55, 1],
  );

  static const LinearGradient likeIdle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFE4EF), Color(0xFFFED4E4)],
  );

  static const LinearGradient likeActive = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF177AE), Color(0xFFE85C93)],
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get theme {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryContainer,
        selectionHandleColor: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.snackbar,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(
          fontSize: 13,
          height: 18 / 13,
          color: Color(0xFFF7EFF8),
        ),
        actionTextColor: const Color(0xFFFFCFE6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
