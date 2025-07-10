import 'package:flutter/material.dart';
import '../constants/automation_colors.dart';

class AutomationTextStyles {
  // Title styles
  static TextStyle cardTitle(bool isActive) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: isActive 
        ? AutomationColors.textOnPrimary 
        : AutomationColors.textPrimary,
  );
  
  // Subtitle styles
  static TextStyle cardSubtitle(bool isActive) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: isActive 
        ? AutomationColors.textOnPrimarySecondary 
        : AutomationColors.textSecondary,
  );
  
  // Workspace name style
  static TextStyle workspaceName(bool isActive) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: isActive 
        ? AutomationColors.textOnPrimarySecondary 
        : AutomationColors.textSecondary,
  );
  
  // Statistics text style
  static TextStyle statisticsText(bool isActive) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: isActive 
        ? AutomationColors.textOnPrimary 
        : AutomationColors.textPrimary,
  );
} 