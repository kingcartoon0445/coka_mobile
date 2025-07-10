import 'package:flutter/material.dart';
import '../../constants/automation_colors.dart';

enum AutomationBadgeType { reminder, recall }

class AutomationBadge extends StatelessWidget {
  final AutomationBadgeType type;
  final bool isActive;
  
  const AutomationBadge({
    super.key,
    required this.type,
    required this.isActive,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive 
              ? AutomationColors.badgeBorderActive 
              : AutomationColors.badgeBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == AutomationBadgeType.reminder 
                ? Icons.alarm_on 
                : Icons.assignment_return,
            size: 14,
            color: isActive 
                ? AutomationColors.badgeBorderActive 
                : AutomationColors.badgeBorder,
          ),
          const SizedBox(width: 4),
          Text(
            type == AutomationBadgeType.reminder ? 'Nhắc hẹn' : 'Thu hồi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive 
                  ? AutomationColors.badgeBorderActive 
                  : AutomationColors.badgeBorder,
            ),
          ),
        ],
      ),
    );
  }
} 