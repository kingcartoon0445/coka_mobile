import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coka/models/reminder.dart';
import 'package:coka/constants/reminder_constants.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';

class ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final Function(bool) onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReminderListItem({
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
    final isOverdue = _isOverdue();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue && !reminder.isDone 
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Complete checkbox and type icon
              Column(
                children: [
                  Checkbox(
                    value: reminder.isDone,
                    onChanged: (value) => onToggleDone(value ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: reminder.isDone 
                          ? Colors.grey.withOpacity(0.2)
                          : _getTypeColor(scheduleType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      scheduleType.icon,
                      color: reminder.isDone 
                          ? Colors.grey
                          : _getTypeColor(scheduleType),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      reminder.title.isNotEmpty ? reminder.title : scheduleType.name,
                      style: TextStyle(
                        decoration: reminder.isDone ? TextDecoration.lineThrough : null,
                        color: reminder.isDone 
                            ? Colors.grey 
                            : isOverdue 
                                ? Colors.red 
                                : const Color(0xFF101828),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Contact info
                    if (reminder.contact != null) ...[
                      Row(
                        children: [
                          AppAvatar(
                            imageUrl: reminder.contact!.avatar,
                            fallbackText: reminder.contact!.fullName,
                            size: 20,
                            shape: AvatarShape.circle,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reminder.contact!.fullName,
                              style: TextStyle(
                                color: reminder.isDone ? Colors.grey : const Color(0xFF475467),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: reminder.isDone 
                              ? Colors.grey 
                              : isOverdue 
                                  ? Colors.red 
                                  : const Color(0xFF5C33F0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(),
                          style: TextStyle(
                            color: reminder.isDone 
                                ? Colors.grey 
                                : isOverdue 
                                    ? Colors.red 
                                    : const Color(0xFF5C33F0),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isOverdue && !reminder.isDone) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Quá hạn',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Content/Description
                    if (reminder.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        reminder.content,
                        style: TextStyle(
                          color: reminder.isDone ? Colors.grey : const Color(0xFF667085),
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status and menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Priority indicator
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: priority.color.withOpacity(reminder.isDone ? 0.3 : 1.0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Status icon
                  Icon(
                    reminder.isDone 
                        ? Icons.check_circle 
                        : isOverdue 
                            ? Icons.warning 
                            : Icons.schedule,
                    color: reminder.isDone 
                        ? Colors.green 
                        : isOverdue 
                            ? Colors.red 
                            : const Color(0xFF5C33F0),
                    size: 18,
                  ),
                  const SizedBox(height: 8),
                  
                  // Menu button
                  PopupMenuButton<String>(
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
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: Color(0xFF667085)),
                            SizedBox(width: 8),
                            Text('Sửa', style: TextStyle(color: Color(0xFF101828))),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatTime() {
    try {
      final startTime = DateTime.parse(reminder.startTime);
      final timeFormat = DateFormat('HH:mm');
      final dateFormat = DateFormat('dd/MM/yyyy');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reminderDate = DateTime(startTime.year, startTime.month, startTime.day);
      
      if (reminderDate.isAtSameMomentAs(today)) {
        return 'Hôm nay, ${timeFormat.format(startTime)}';
      } else if (reminderDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
        return 'Ngày mai, ${timeFormat.format(startTime)}';
      } else if (reminderDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
        return 'Hôm qua, ${timeFormat.format(startTime)}';
      } else {
        return '${dateFormat.format(startTime)}, ${timeFormat.format(startTime)}';
      }
    } catch (e) {
      return reminder.time;
    }
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.call:
        return Colors.green;
      case ScheduleType.meeting:
        return Colors.blue;
      case ScheduleType.meal:
        return Colors.orange;
      case ScheduleType.video:
        return Colors.purple;
      case ScheduleType.event:
        return Colors.indigo;
      case ScheduleType.document:
        return Colors.brown;
      default:
        return const Color(0xFF5C33F0);
    }
  }
} 