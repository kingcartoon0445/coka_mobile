import 'package:flutter/material.dart';
import 'package:coka/models/reminder.dart';
import 'package:coka/constants/reminder_constants.dart';
import 'package:coka/theme/reminder_theme.dart';
import 'package:intl/intl.dart';

class WebReminderItem extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final Function(bool) onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WebReminderItem({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleType = ScheduleType.fromId(reminder.schedulesType);
    final priority = Priority.fromValue(reminder.priority);
    final backgroundColor = _getBackgroundColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ReminderColors.gray200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              // Checkbox
              _buildCheckbox(),
              const SizedBox(width: 10),
              
              // Type icon
              _buildTypeIcon(scheduleType),
              const SizedBox(width: 10),
              
              // Content
              Expanded(
                child: _buildContent(priority),
              ),
              
              const SizedBox(width: 4),
              
              // Menu
              _buildMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return SizedBox(
      width: 16,
      height: 16,
      child: Checkbox(
        value: reminder.isDone,
        onChanged: (value) => onToggleDone(value ?? false),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        side: BorderSide(
          color: reminder.isDone 
              ? ReminderColors.success 
              : ReminderColors.gray300,
          width: 1.5,
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ReminderColors.success;
          }
          return Colors.transparent;
        }),
      ),
    );
  }

  Widget _buildTypeIcon(ScheduleType scheduleType) {
    final baseColor = scheduleType == ScheduleType.call 
        ? ReminderColors.success
        : ReminderColors.primary;
        
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: reminder.isDone 
            ? baseColor.withOpacity(0.05)
            : baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        scheduleType.icon,
        size: 14,
        color: reminder.isDone 
            ? baseColor.withOpacity(0.3)
            : baseColor,
      ),
    );
  }

  String _getTimeRemaining() {
    try {
      final startTime = DateTime.parse(reminder.startTime);
      final now = DateTime.now();
      
      if (reminder.isDone) {
        return "Đã hoàn thành";
      }
      
      if (_isOverdue()) {
        final endTime = DateTime.parse(reminder.endTime!);
        final overdueDuration = now.difference(endTime);
        
        if (overdueDuration.inDays > 0) {
          return "Quá hạn ${overdueDuration.inDays} ngày";
        } else if (overdueDuration.inHours > 0) {
          return "Quá hạn ${overdueDuration.inHours} giờ";
        } else {
          return "Quá hạn ${overdueDuration.inMinutes} phút";
        }
      }
      
      final difference = startTime.difference(now);
      
      if (difference.isNegative) {
        // Đã bắt đầu nhưng chưa kết thúc
        return "Đang diễn ra";
      }
      
      if (difference.inDays > 0) {
        return "Còn ${difference.inDays} ngày";
      } else if (difference.inHours > 0) {
        return "Còn ${difference.inHours} giờ";
      } else if (difference.inMinutes > 0) {
        return "Còn ${difference.inMinutes} phút";
      } else {
        return "Sắp bắt đầu";
      }
    } catch (e) {
      return reminder.time; // Fallback về format cũ nếu có lỗi
    }
  }

  Widget _buildContent(Priority priority) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title với priority indicator kế bên (không expand full width)
        Row(
          children: [
            // Title không expand để priority badge gần hơn
            Flexible(
              child: Text(
                reminder.title.isNotEmpty 
                    ? reminder.title 
                    : ScheduleType.fromId(reminder.schedulesType).name,
                style: ReminderTypography.body1.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  decoration: reminder.isDone ? TextDecoration.lineThrough : null,
                  color: reminder.isDone 
                      ? ReminderColors.gray400
                      : _isOverdue() 
                          ? ReminderColors.overdueText
                          : ReminderColors.gray800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            // Priority indicator - Hình tròn màu kế bên title
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getPriorityColor(priority).withOpacity(reminder.isDone ? 0.3 : 1.0),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 3),
        
        // Time và description trên cùng 1 dòng
        Row(
          children: [
            // Time - Hiển thị thời gian còn lại với long press tooltip
            Tooltip(
              message: _formatDetailedTime(),
              triggerMode: TooltipTriggerMode.longPress,
              waitDuration: const Duration(milliseconds: 500),
              showDuration: const Duration(seconds: 5),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              child: Text(
                _getTimeRemaining(),
                style: ReminderTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: reminder.isDone 
                      ? ReminderColors.gray400
                      : _isOverdue() 
                          ? ReminderColors.overdueText
                          : ReminderColors.primary,
                  decoration: reminder.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            
            // Description với icon tròn ngăn cách (nếu có)
            if (reminder.content.isNotEmpty) ...[
              const SizedBox(width: 6),
              // Icon tròn ngăn cách
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: ReminderColors.gray400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              // Description
              Expanded(
                child: Text(
                  reminder.content,
                  style: ReminderTypography.caption.copyWith(
                    fontSize: 10,
                    color: reminder.isDone 
                        ? ReminderColors.gray400
                        : ReminderColors.gray600,
                    decoration: reminder.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 16,
        color: ReminderColors.gray400,
      ),
      padding: EdgeInsets.zero,
      iconSize: 16,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.edit, size: 14, color: ReminderColors.gray600),
              const SizedBox(width: 6),
              Text('Sửa', style: ReminderTypography.body2.copyWith(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.delete, size: 14, color: ReminderColors.error),
              const SizedBox(width: 6),
              Text(
                'Xóa', 
                style: ReminderTypography.body2.copyWith(
                  color: ReminderColors.error,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(Priority priority) {
    // Priority value: 2=cao, 1=trung bình, 0=thấp (theo logic từ React code)
    final priorityValue = reminder.priority ?? 0;
    
    switch (priorityValue) {
      case 2: // Cao
        return const Color(0xFFEF4444); // red-500
      case 1: // Trung bình  
        return const Color(0xFFF59E0B); // amber-500
      case 0: // Thấp
      default:
        return const Color(0xFF9CA3AF); // gray-400
    }
  }

  bool _isOverdue() {
    if (reminder.isDone || reminder.endTime == null) return false;
    
    try {
      final endTime = DateTime.parse(reminder.endTime!);
      return DateTime.now().isAfter(endTime);
    } catch (e) {
      return false;
    }
  }

  Color _getBackgroundColor() {
    if (reminder.isDone) return Colors.white; // Không có background màu cho done state
    if (_isOverdue()) return ReminderColors.overdue;
    return Colors.white;
  }

  String _formatDetailedTime() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    try {
      final startTime = DateTime.parse(reminder.startTime);
      String result = 'Bắt đầu: ${dateFormat.format(startTime)}';
      
      if (reminder.endTime != null && reminder.endTime!.isNotEmpty) {
        final endTime = DateTime.parse(reminder.endTime!);
        result += '\nKết thúc: ${dateFormat.format(endTime)}';
      }
      
      return result;
    } catch (e) {
      return 'Thời gian: ${reminder.time}';
    }
  }
} 