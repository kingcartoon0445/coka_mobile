import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coka/models/reminder.dart';
import 'package:coka/constants/reminder_constants.dart';
import 'package:coka/providers/reminder_provider.dart';
import 'package:coka/providers/customer_provider.dart';

class AddReminderDialog extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String? contactId;
  final Map<String, dynamic>? contactData;
  final Reminder? editingReminder;

  const AddReminderDialog({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    this.contactId,
    this.contactData,
    this.editingReminder,
  });

  @override
  ConsumerState<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends ConsumerState<AddReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  ScheduleType _selectedType = ScheduleType.reminder;
  Priority _selectedPriority = Priority.medium;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  bool _isDone = false;
  bool _isLoading = false;
  Map<String, dynamic>? _selectedContact;
  List<Map<String, int>> _notifyBeforeList = []; // Default empty - no notifications

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.editingReminder != null) {
      final reminder = widget.editingReminder!;
      _titleController = TextEditingController(text: reminder.title);
      _contentController = TextEditingController(text: reminder.content);
      
      _selectedType = ScheduleType.fromId(reminder.schedulesType);
      _selectedPriority = Priority.fromValue(reminder.priority);
      _isDone = reminder.isDone;
      
      try {
        // Parse UTC time and convert to local time for display
        final startDateTimeUtc = DateTime.parse(reminder.startTime);
        final startDateTimeLocal = startDateTimeUtc.toLocal();
        _startDate = DateTime(startDateTimeLocal.year, startDateTimeLocal.month, startDateTimeLocal.day);
        _startTime = TimeOfDay.fromDateTime(startDateTimeLocal);
        
        if (reminder.endTime != null) {
          final endDateTimeUtc = DateTime.parse(reminder.endTime!);
          final endDateTimeLocal = endDateTimeUtc.toLocal();
          _endDate = DateTime(endDateTimeLocal.year, endDateTimeLocal.month, endDateTimeLocal.day);
          _endTime = TimeOfDay.fromDateTime(endDateTimeLocal);
        }
      } catch (e) {
        // Use default values if parsing fails
      }

      if (reminder.contact != null) {
        _selectedContact = {
          'id': reminder.contact!.id,
          'fullName': reminder.contact!.fullName,
          'avatar': reminder.contact!.avatar,
          'phone': reminder.contact!.phone,
        };
      }

      // Initialize notification list from existing reminder
      if (reminder.notifyBefore != null && reminder.notifyBefore!.isNotEmpty) {
        _notifyBeforeList = reminder.notifyBefore!.asMap().entries.map((entry) {
          final index = entry.key;
          final notify = entry.value;
          final totalMinutes = notify.minutes;
          final hours = totalMinutes ~/ 60;
          final minutes = totalMinutes % 60;
          
          return {
            'id': index + 1,
            'hour': hours,
            'minute': minutes,
          };
        }).toList();
      }
    } else {
      _titleController = TextEditingController(text: _selectedType.name);
      _contentController = TextEditingController();
      
      // If contactData is provided directly, use it
      if (widget.contactData != null) {
        _selectedContact = {
          'id': widget.contactData!['id'],
          'fullName': widget.contactData!['fullName'] ?? '',
          'avatar': widget.contactData!['avatar'],
          'phone': widget.contactData!['phone'],
        };
      }
      // If only contactId is provided, load contact info
      else if (widget.contactId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadContactInfo();
        });
      }
    }
  }

  Future<void> _loadContactInfo() async {
    try {
      final customerListAsync = ref.read(customerListProvider);
      final customers = customerListAsync.value ?? [];
      final customerIndex = customers.indexWhere((c) => c['id'] == widget.contactId);
      
      if (customerIndex != -1) {
        final customer = customers[customerIndex];
        setState(() {
          _selectedContact = {
            'id': customer['id'],
            'fullName': customer['fullName'] ?? '',
            'avatar': customer['avatar'],
            'phone': customer['phone'],
          };
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _onTypeChanged(ScheduleType type) {
    setState(() {
      _selectedType = type;
      // Auto fill title with type name if title is empty or matches previous type
      if (_titleController.text.isEmpty || 
          ScheduleType.values.any((t) => t.name == _titleController.text)) {
        _titleController.text = type.name;
      }
    });
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority.value) {
      case 2: // Cao
        return const Color(0xFFEF4444); // red-500
      case 1: // Trung bình  
        return const Color(0xFFF59E0B); // amber-500
      case 0: // Thấp
      default:
        return const Color(0xFF9CA3AF); // gray-400
    }
  }

  void _scrollToNotificationSection() {
    // Scroll to bottom where notification section is located
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _addNotification() {
    setState(() {
      final newId = _notifyBeforeList.isNotEmpty 
          ? _notifyBeforeList.map((item) => item['id']!).reduce((a, b) => a > b ? a : b) + 1
          : 1;
      _notifyBeforeList.add({'id': newId, 'hour': 0, 'minute': 30});
    });
    
    // Auto scroll to notification section after adding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNotificationSection();
    });
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm thông báo mới'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 60, left: 16, right: 16),
      ),
    );
  }

  void _updateNotification(int id, String field, int value) {
    setState(() {
      final index = _notifyBeforeList.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _notifyBeforeList[index] = {
          ..._notifyBeforeList[index],
          field: value,
        };
      }
    });
  }

  void _removeNotification(int id) {
    setState(() {
      if (_notifyBeforeList.length > 1) {
        _notifyBeforeList.removeWhere((item) => item['id'] == id);
      } else {
        _notifyBeforeList.clear();
      }
    });
  }

  bool _validateNotifications() {
    for (final notify in _notifyBeforeList) {
      final hour = notify['hour']!;
      final minute = notify['minute']!;
      
      // Validate hour range
      if (hour < 0 || hour > 72) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giờ phải trong khoảng từ 0 đến 72'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      // Validate minute range
      if (minute < 0 || minute > 59) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phút phải trong khoảng từ 0 đến 59'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      // Validate total time is not 0
      final totalMinutes = (hour * 60) + minute;
      if (totalMinutes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thời gian thông báo phải lớn hơn 0'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    return true;
  }

  Widget _buildQuickSelectChip(String label, int hour, int minute) {
    return InkWell(
      onTap: () {
        setState(() {
          final newId = _notifyBeforeList.isNotEmpty 
              ? _notifyBeforeList.map((item) => item['id']!).reduce((a, b) => a > b ? a : b) + 1
              : 1;
          _notifyBeforeList.add({'id': newId, 'hour': hour, 'minute': minute});
        });
        
        // Auto scroll to notification section after adding
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToNotificationSection();
        });
        
        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm thông báo $label'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
      child: Container(
        width: screenWidth * 0.95,
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 600),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.editingReminder != null ? 'Chỉnh sửa nhắc hẹn' : 'Đặt nhắc hẹn',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title input
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: _selectedType.name,
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Vui lòng nhập tiêu đề';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        // Type selection
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ScheduleType.values.map((type) {
                            return InkWell(
                              onTap: () => _onTypeChanged(type),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedType == type 
                                      ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _selectedType == type 
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Icon(
                                  type.icon, 
                                  size: 16,
                                  color: _selectedType == type 
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Contact selection
                        if (_selectedContact != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Khách hàng',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _selectedContact!['fullName'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Time Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ngày bắt đầu',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _selectStartDate,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            DateFormat('dd/MM/yyyy').format(_startDate),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Giờ bắt đầu',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _selectStartTime,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _startTime.format(context),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ngày kết thúc',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _selectEndDate,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _endDate != null 
                                                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                                : 'Chưa chọn',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _endDate != null 
                                                  ? const Color(0xFF111827)
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Giờ kết thúc',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _selectEndTime,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _endTime?.format(context) ?? 'Chưa chọn',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _endTime != null 
                                                  ? const Color(0xFF111827)
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Priority Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Độ ưu tiên',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: Priority.values.map((priority) {
                                return Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedPriority = priority;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedPriority == priority
                                            ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                                            : const Color(0xFFF9FAFB),
                                        border: Border.all(
                                          color: _selectedPriority == priority
                                              ? const Color(0xFF4F46E5)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(priority),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            priority.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _selectedPriority == priority
                                                  ? const Color(0xFF4F46E5)
                                                  : const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mô tả chi tiết',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: TextFormField(
                                controller: _contentController,
                                decoration: const InputDecoration(
                                  hintText: 'Mô tả chi tiết về lịch hẹn',
                                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                                maxLines: 4,
                                minLines: 4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Notification Section
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    size: 16,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Thông báo trước',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Quick select buttons
                              const Text(
                                'Chọn nhanh:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildQuickSelectChip('5 phút', 0, 5),
                                  _buildQuickSelectChip('15 phút', 0, 15),
                                  _buildQuickSelectChip('30 phút', 0, 30),
                                  _buildQuickSelectChip('1 giờ', 1, 0),
                                  _buildQuickSelectChip('2 giờ', 2, 0),
                                  _buildQuickSelectChip('1 ngày', 24, 0),
                                  // Add notification button
                                  InkWell(
                                    onTap: _addNotification,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF4F46E5)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Color(0xFF4F46E5),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Thêm',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4F46E5),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              if (_notifyBeforeList.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: _notifyBeforeList.map((notify) {
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              // Hour input
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 60,
                                                    child: TextFormField(
                                                      key: ValueKey('hour_${notify['id']}'),
                                                      initialValue: notify['hour'].toString(),
                                                      decoration: InputDecoration(
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                                                        ),
                                                        errorBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Colors.red),
                                                        ),
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                        isDense: true,
                                                      ),
                                                      keyboardType: TextInputType.number,
                                                      validator: (value) {
                                                        if (value == null || value.isEmpty) {
                                                          return null;
                                                        }
                                                        final hour = int.tryParse(value);
                                                        if (hour == null || hour < 0 || hour > 72) {
                                                          return 'Giờ phải từ 0-72';
                                                        }
                                                        return null;
                                                      },
                                                      onChanged: (value) {
                                                        final hour = int.tryParse(value) ?? 0;
                                                        if (hour >= 0 && hour <= 72) {
                                                          _updateNotification(notify['id']!, 'hour', hour);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'giờ',
                                                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // Minute input
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 60,
                                                    child: TextFormField(
                                                      key: ValueKey('minute_${notify['id']}'),
                                                      initialValue: notify['minute'].toString(),
                                                      decoration: InputDecoration(
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                                                        ),
                                                        errorBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                          borderSide: const BorderSide(color: Colors.red),
                                                        ),
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                        isDense: true,
                                                      ),
                                                      keyboardType: TextInputType.number,
                                                      validator: (value) {
                                                        if (value == null || value.isEmpty) {
                                                          return null;
                                                        }
                                                        final minute = int.tryParse(value);
                                                        if (minute == null || minute < 0 || minute > 59) {
                                                          return 'Phút phải từ 0-59';
                                                        }
                                                        return null;
                                                      },
                                                      onChanged: (value) {
                                                        final minute = int.tryParse(value) ?? 0;
                                                        if (minute >= 0 && minute <= 59) {
                                                          _updateNotification(notify['id']!, 'minute', minute);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'phút',
                                                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                                                  ),
                                                ],
                                              ),
                                              
                                              const Spacer(),
                                              
                                              // Delete button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () => _removeNotification(notify['id']!),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              
                              if (_notifyBeforeList.isNotEmpty)
                                const SizedBox(height: 8),
                              
                              const Text(
                                'Hệ thống sẽ nhắc bạn trước khi đến lịch hẹn.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Checkbox for completion (only when editing)
                  if (widget.editingReminder != null)
                    Row(
                      children: [
                        Checkbox(
                          value: _isDone,
                          onChanged: (value) {
                            setState(() {
                              _isDone = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF4F46E5),
                        ),
                        const Text(
                          'Đánh dấu đã hoàn thành',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(),
                  
                  // Action buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Lưu',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
        // If end date is not set or is before start date, set it to start date
        if (_endDate == null || _endDate!.isBefore(date)) {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate, // End date cannot be before start date
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate notifications
    if (_notifyBeforeList.isNotEmpty && !_validateNotifications()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      // Convert local time to UTC for API
      final startDateTimeUtc = startDateTime.toUtc();
      final endDateTimeUtc = endDateTime?.toUtc();
      
      final data = <String, dynamic>{
        if (widget.editingReminder != null) 'Id': widget.editingReminder!.id,
        'Title': _titleController.text.trim(),
        'Content': _contentController.text.trim(),
        'StartTime': '${startDateTimeUtc.toIso8601String().substring(0, 23)}Z',
        if (endDateTimeUtc != null) 'EndTime': '${endDateTimeUtc.toIso8601String().substring(0, 23)}Z',
        'RepeatRule': <dynamic>[],
        'IsDone': _isDone,
        'SchedulesType': _selectedType.id,
        'Priority': _selectedPriority.value,
        'OrganizationId': widget.organizationId,
        'WorkspaceId': widget.workspaceId,
        'Reminders': _notifyBeforeList.map((notify) {
          final totalMinutes = (notify['hour']! * 60) + notify['minute']!;
          final hours = totalMinutes ~/ 60;
          final minutes = totalMinutes % 60;
          return {
            'Time': '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}'
          };
        }).toList(),
        'RelatedProfiles': <dynamic>[],
        if (_selectedContact != null) 'Contact': [
          {
            'id': _selectedContact!['id'],
            'fullName': _selectedContact!['fullName'],
            'phone': _selectedContact!['phone'],
            'avatar': _selectedContact!['avatar'],
          }
        ],
      };

      if (widget.editingReminder != null) {
        await ref.read(reminderListProvider.notifier).updateReminder(data);
      } else {
        await ref.read(reminderListProvider.notifier).createReminder(data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editingReminder != null ? 'Đã cập nhật nhắc hẹn' : 'Đã tạo nhắc hẹn'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 