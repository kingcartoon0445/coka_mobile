import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coka/models/reminder.dart';
import 'package:coka/constants/reminder_constants.dart';
import 'package:coka/providers/reminder_provider.dart';
import 'package:coka/pages/organization/detail_organization/workspace/reminders/add_reminder_dialog.dart';

class ReminderListPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String contactId;

  const ReminderListPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.contactId,
  });

  @override
  ConsumerState<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends ConsumerState<ReminderListPage> {
  @override
  void initState() {
    super.initState();
    // Load reminders for this contact
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderListProvider.notifier).loadReminders(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
        contactId: widget.contactId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Lịch hẹn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF101828),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101828)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5C33F0)),
            onPressed: () => _showAddReminderDialog(),
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          final contactReminders = reminders.where((r) => 
            r.contact?.id == widget.contactId
          ).toList();

          if (contactReminders.isEmpty) {
            return _buildEmptyState();
          }

                     return RefreshIndicator(
             onRefresh: () async {
               await ref.read(reminderListProvider.notifier).loadReminders(
                 organizationId: widget.organizationId,
                 workspaceId: widget.workspaceId,
                 contactId: widget.contactId,
               );
             },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contactReminders.length,
              itemBuilder: (context, index) {
                final reminder = contactReminders[index];
                return _buildReminderCard(reminder);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5C33F0),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF667085),
              ),
              const SizedBox(height: 16),
              Text(
                'Không thể tải lịch hẹn',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF667085),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
                             ElevatedButton(
                 onPressed: () {
                   ref.read(reminderListProvider.notifier).loadReminders(
                     organizationId: widget.organizationId,
                     workspaceId: widget.workspaceId,
                     contactId: widget.contactId,
                   );
                 },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C33F0),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_note,
            size: 64,
            color: Color(0xFF667085),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có lịch hẹn nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo lịch hẹn đầu tiên cho khách hàng này',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF667085),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddReminderDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C33F0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tạo lịch hẹn'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final scheduleType = ScheduleType.fromId(reminder.schedulesType);
    final priority = Priority.fromValue(reminder.priority);
    final startTime = DateTime.parse(reminder.startTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: reminder.isDone 
              ? Colors.green.withOpacity(0.3)
              : const Color(0xFFE4E7EC),
        ),
      ),
      child: InkWell(
        onTap: () => _showEditReminderDialog(reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheduleType == ScheduleType.reminder
                          ? const Color(0xFF5C33F0).withOpacity(0.1)
                          : scheduleType == ScheduleType.meeting
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      scheduleType.icon,
                      size: 16,
                      color: scheduleType == ScheduleType.reminder
                          ? const Color(0xFF5C33F0)
                          : scheduleType == ScheduleType.meeting
                              ? Colors.blue
                              : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: reminder.isDone 
                                ? const Color(0xFF667085)
                                : const Color(0xFF101828),
                            decoration: reminder.isDone 
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (reminder.content.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: reminder.isDone 
                                  ? const Color(0xFF667085)
                                  : const Color(0xFF344054),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (reminder.isDone)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: const Color(0xFF667085),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy - HH:mm').format(startTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priority == Priority.high
                          ? Colors.red.withOpacity(0.1)
                          : priority == Priority.medium
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: priority == Priority.high
                            ? Colors.red
                            : priority == Priority.medium
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
        contactId: widget.contactId,
      ),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
        contactId: widget.contactId,
        editingReminder: reminder,
      ),
    );
  }
} 