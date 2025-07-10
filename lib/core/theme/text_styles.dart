import 'package:flutter/material.dart';
import 'app_colors.dart';

class TextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle subtitle2 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
  static const TextStyle subtitle3 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    overflow: TextOverflow.ellipsis,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.text,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle label = TextStyle(
    fontSize: 16,
    color: AppColors.text,
    fontWeight: FontWeight.w500,
  );

  static TextTheme get textTheme => const TextTheme(
        displayLarge: heading1,
        bodyLarge: body,
        titleLarge: title,
        titleMedium: subtitle1,
      );
}
