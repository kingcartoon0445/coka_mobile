import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
    fontFamily: 'GoogleSans',
    useMaterial3: true,
    textTheme: TextStyles.textTheme,
    appBarTheme: const AppBarTheme(
      toolbarHeight: 56,
      titleSpacing: 8,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
    ),
  );
}
