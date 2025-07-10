import 'package:flutter/material.dart';

enum ScheduleType {
  call('call', 'Gọi điện', Icons.phone),
  meeting('meeting', 'Gặp gỡ', Icons.people),
  reminder('reminder', 'Nhắc nhở', Icons.notifications),
  meal('meal', 'Ăn uống', Icons.local_cafe),
  document('document', 'Tài liệu', Icons.description),
  video('video', 'Video', Icons.videocam),
  event('event', 'Sự kiện', Icons.event);

  const ScheduleType(this.id, this.name, this.icon);
  final String id;
  final String name;
  final IconData icon;

  static ScheduleType fromId(String id) {
    return values.firstWhere(
      (type) => type.id == id,
      orElse: () => ScheduleType.reminder,
    );
  }
}

enum Priority {
  low(0, 'Thấp', Colors.grey),
  medium(1, 'Trung bình', Colors.orange),
  high(2, 'Cao', Colors.red);

  const Priority(this.value, this.name, this.color);
  final int value;
  final String name;
  final Color color;

  static Priority fromValue(int value) {
    return values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => Priority.medium,
    );
  }
}

class ReminderConstants {
  static const String calendarBaseUrl = 'https://calendar.coka.ai';
  static const String scheduleEndpoint = '/api/Schedule';
  
  // Time options for notifications
  static const List<Map<String, dynamic>> notifyBeforeOptions = [
    {'minutes': 0, 'label': 'Đúng giờ'},
    {'minutes': 5, 'label': '5 phút trước'},
    {'minutes': 10, 'label': '10 phút trước'},
    {'minutes': 15, 'label': '15 phút trước'},
    {'minutes': 30, 'label': '30 phút trước'},
    {'minutes': 60, 'label': '1 giờ trước'},
    {'minutes': 120, 'label': '2 giờ trước'},
    {'minutes': 1440, 'label': '1 ngày trước'},
  ];

  // Default notification types
  static const List<String> notificationTypes = [
    'popup',
    'email', 
    'sms',
  ];

  // Days of week for repeat rules
  static const List<Map<String, dynamic>> weekDays = [
    {'day': 'monday', 'label': 'Thứ 2'},
    {'day': 'tuesday', 'label': 'Thứ 3'},
    {'day': 'wednesday', 'label': 'Thứ 4'},
    {'day': 'thursday', 'label': 'Thứ 5'},
    {'day': 'friday', 'label': 'Thứ 6'},
    {'day': 'saturday', 'label': 'Thứ 7'},
    {'day': 'sunday', 'label': 'Chủ nhật'},
  ];
} 