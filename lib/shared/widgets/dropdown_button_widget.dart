import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Widget chuẩn hóa cho tất cả dropdown button trong app
/// Đảm bảo icon arrow down đồng nhất về vị trí và khoảng cách
class StandardDropdownButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isEnabled;
  final TextStyle? textStyle;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final double iconSize;
  final double spaceBetweenTextAndIcon;

  const StandardDropdownButton({
    super.key,
    required this.text,
    this.onTap,
    this.isEnabled = true,
    this.textStyle,
    this.iconColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.iconSize = 20,
    this.spaceBetweenTextAndIcon = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: textStyle ?? 
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? AppColors.text : AppColors.textTertiary,
                  ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: spaceBetweenTextAndIcon),
            Icon(
              Icons.keyboard_arrow_down,
              size: iconSize,
              color: iconColor ?? (isEnabled ? AppColors.textSecondary : AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget cho dropdown với style primary (màu xanh)
class PrimaryDropdownButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLoading;

  const PrimaryDropdownButton({
    super.key,
    required this.text,
    this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(4),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
    }

    return StandardDropdownButton(
      text: text,
      onTap: onTap,
      isEnabled: isEnabled,
      textStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        fontSize: 14,
      ),
      iconColor: AppColors.primary,
      iconSize: 16,
      spaceBetweenTextAndIcon: 4,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      border: Border.all(
        color: AppColors.primary.withOpacity(0.3),
      ),
      backgroundColor: AppColors.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(4),
    );
  }
}

/// Widget cho dropdown trong header/title
class TitleDropdownButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isEnabled;

  const TitleDropdownButton({
    super.key,
    required this.text,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return StandardDropdownButton(
      text: text,
      onTap: onTap,
      isEnabled: isEnabled,
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2329),
      ),
      iconColor: const Color(0xFF1F2329),
      iconSize: 24,
      spaceBetweenTextAndIcon: 4,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
} 