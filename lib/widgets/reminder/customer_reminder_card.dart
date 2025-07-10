import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coka/models/reminder.dart';
import 'package:coka/constants/reminder_constants.dart';
import 'package:coka/providers/reminder_provider.dart';
import 'package:coka/pages/organization/detail_organization/workspace/reminders/add_reminder_dialog.dart';
import 'package:coka/theme/reminder_theme.dart';
import 'package:coka/widgets/web_reminder_item.dart';

class CustomerReminderCard extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String customerId;
  final Map<String, dynamic>? customerData;
  final VoidCallback? onAddReminder;

  const CustomerReminderCard({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.customerId,
    this.customerData,
    this.onAddReminder,
  });

  @override
  ConsumerState<CustomerReminderCard> createState() => _CustomerReminderCardState();
}

class _CustomerReminderCardState extends ConsumerState<CustomerReminderCard> {
  bool _showAllReminders = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderListProvider.notifier).loadReminders(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
        contactId: widget.customerId,
      );
    });
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
        contactId: widget.customerId,
        contactData: widget.customerData,
      ),
    ).then((_) {
      // Reload reminders after dialog closes
      _loadReminders();
    });
  }

  void _toggleReminderDone(Reminder reminder, bool isDone) {
    ref.read(reminderListProvider.notifier).toggleReminderDone(reminder.id, isDone);
  }

  void _editReminder(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
        contactId: widget.customerId,
        contactData: widget.customerData,
        editingReminder: reminder,
      ),
    ).then((_) {
      _loadReminders();
    });
  }

  void _deleteReminder(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhắc hẹn?'),
        content: const Text('Bạn có chắc chắn muốn xóa nhắc hẹn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(reminderListProvider.notifier).deleteReminder(reminder.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa nhắc hẹn'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderListProvider);
    final pendingReminders = ref.watch(pendingRemindersProvider);
    final todayReminders = ref.watch(todayRemindersProvider);
    final overdueReminders = ref.watch(overdueRemindersProvider);
    
    // Lấy tất cả reminders và sắp xếp: pending trước, completed sau
    final allReminders = remindersAsync.when(
      data: (reminders) => reminders,
      loading: () => <Reminder>[],
      error: (_, __) => <Reminder>[],
    );

    return Theme(
      data: ReminderTheme.lightTheme,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C33F0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Color(0xFF5C33F0),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hoạt động',
                    style: ReminderTypography.heading3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Di chuyển badges về phía trái, sau title
                  if (overdueReminders.isNotEmpty)
                    _buildStatChip(
                      label: 'Quá hạn',
                      count: overdueReminders.length,
                      color: ReminderColors.error,
                      icon: Icons.warning,
                    ),
                  if (overdueReminders.isNotEmpty && todayReminders.isNotEmpty)
                    const SizedBox(width: 4),
                  if (todayReminders.isNotEmpty)
                    _buildStatChip(
                      label: 'Hôm nay',
                      count: todayReminders.length,
                      color: ReminderColors.warning,
                      icon: Icons.today,
                    ),
                  
                  const Spacer(),
                  
                  if (allReminders.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ReminderColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${allReminders.length}',
                        style: ReminderTypography.caption.copyWith(
                          color: ReminderColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  GestureDetector(
                    onTap: () => _showAddReminderDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: ReminderColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Thêm',
                            style: ReminderTypography.button.copyWith(
                              color: ReminderColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Content
              remindersAsync.when(
                data: (_) {
                  if (allReminders.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return Column(
                    children: [
                      // Tất cả reminders (đã sắp xếp pending trước, completed sau)
                      const SizedBox(height: 8),
                      ...(_showAllReminders ? allReminders : allReminders.take(2)).map((reminder) => WebReminderItem(
                        reminder: reminder,
                        onTap: () {},
                        onToggleDone: (isDone) => _toggleReminderDone(reminder, isDone),
                        onEdit: () => _editReminder(reminder),
                        onDelete: () => _deleteReminder(reminder),
                      )),
                      if (allReminders.length > 2) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAllReminders = !_showAllReminders;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                _showAllReminders 
                                    ? 'Thu gọn' 
                                    : 'Xem thêm ${allReminders.length - 2} hoạt động',
                                style: ReminderTypography.body2.copyWith(
                                  color: ReminderColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    if (count == 0) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ReminderColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.schedule_outlined,
              size: 28,
              color: ReminderColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có hoạt động nào',
            style: ReminderTypography.body1.copyWith(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhấn "Thêm" để tạo nhắc hẹn mới',
            style: ReminderTypography.caption.copyWith(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C33F0)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red,
          ),
          const SizedBox(height: 6),
          const Text(
            'Không thể tải nhắc hẹn',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _loadReminders,
            child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(Reminder reminder) {
    if (reminder.isDone || reminder.endTime == null) return false;
    
    try {
      final endTime = DateTime.parse(reminder.endTime!);
      return DateTime.now().isAfter(endTime);
    } catch (e) {
      return false;
    }
  }

  bool _isToday(Reminder reminder) {
    try {
      final startTime = DateTime.parse(reminder.startTime);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reminderDate = DateTime(startTime.year, startTime.month, startTime.day);
      return reminderDate.isAtSameMomentAs(today);
    } catch (e) {
      return false;
    }
  }

  String _formatTime(Reminder reminder) {
    try {
      final startTime = DateTime.parse(reminder.startTime);
      final timeFormat = DateFormat('HH:mm');
      final dateFormat = DateFormat('dd/MM');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reminderDate = DateTime(startTime.year, startTime.month, startTime.day);
      
      if (reminderDate.isAtSameMomentAs(today)) {
        return 'Hôm nay, ${timeFormat.format(startTime)}';
      } else if (reminderDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
        return 'Ngày mai, ${timeFormat.format(startTime)}';
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