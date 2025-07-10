import 'package:flutter/material.dart';
import '../constants/dialog_colors.dart';

class DialogTextStyles {
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: DialogColors.dialogTitleColor,
  );
  
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: DialogColors.titleColor,
  );
  
  static const TextStyle cardDescription = TextStyle(
    fontSize: 14,
    color: DialogColors.descriptionColor,
    height: 1.4,
  );
} 