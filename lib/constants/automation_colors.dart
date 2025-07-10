import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AutomationColors {
  // Primary Colors - sử dụng từ app theme
  static const Color primaryBlue = AppColors.primary;
  static const Color primaryBlueHover = Color(0xFF4A2BC7); // Darker version of primary
  
  // Background Colors
  static const Color cardActive = AppColors.primary;
  static const Color cardInactive = Color(0xFFF8F9FA);
  static const Color cardHover = Color(0xFFE5E7EB);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnPrimarySecondary = Color(0xFFE5E7EB);
  
  // Badge Colors
  static const Color badgeBorder = Color(0xFF6B7280);
  static const Color badgeBorderActive = Colors.white;
  
  // Statistics Colors
  static const Color statsBackground = Color(0x1A000000); // 10% black
  static const Color statsBackgroundActive = Color(0x33FFFFFF); // 20% white
  
  // Delete Button
  static const Color deleteButton = Color(0xFFEF4444);
} 