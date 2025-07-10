import 'dart:convert';
import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final String content;
  final String startTime;
  final String? endTime;
  final String time;
  final bool isDone;
  final String schedulesType;
  final int priority;
  final String organizationId;
  final String workspaceId;
  final ContactInfo? contact;
  final List<RepeatRule>? repeatRule;
  final List<NotifyBefore>? notifyBefore;

  Reminder({
    required this.id,
    required this.title,
    required this.content,
    required this.startTime,
    this.endTime,
    required this.time,
    required this.isDone,
    required this.schedulesType,
    required this.priority,
    required this.organizationId,
    required this.workspaceId,
    this.contact,
    this.repeatRule,
    this.notifyBefore,
  });

  static List<RepeatRule>? _parseRepeatRule(dynamic repeatRuleData) {
    if (repeatRuleData == null) return null;
    
    try {
      if (repeatRuleData is String) {
        final List<dynamic> rules = jsonDecode(repeatRuleData);
        return rules.map((x) => RepeatRule.fromJson(x)).toList();
      } else if (repeatRuleData is List) {
        return repeatRuleData.map((x) => RepeatRule.fromJson(x)).toList();
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    // Parse Contact from string JSON if it's a string
    ContactInfo? contactInfo;
    if (json['Contact'] != null) {
      if (json['Contact'] is String) {
        try {
          final contactList = jsonDecode(json['Contact']) as List;
          if (contactList.isNotEmpty) {
            contactInfo = ContactInfo.fromJson(contactList.first);
          }
        } catch (e) {
          // If parsing fails, ignore contact
        }
      } else if (json['Contact'] is Map<String, dynamic>) {
        contactInfo = ContactInfo.fromJson(json['Contact']);
      }
    }

    // Generate time string from StartTime and EndTime if Time is not provided
    String timeString = json['Time'] ?? '';
    if (timeString.isEmpty && json['StartTime'] != null) {
      try {
        final startDateTime = DateTime.parse(json['StartTime']);
        final startTime = TimeOfDay.fromDateTime(startDateTime);
        timeString = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        
        if (json['EndTime'] != null) {
          final endDateTime = DateTime.parse(json['EndTime']);
          final endTime = TimeOfDay.fromDateTime(endDateTime);
          timeString += ' - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        timeString = '';
      }
    }

    return Reminder(
      id: json['Id'] ?? '',
      title: json['Title'] ?? '',
      content: json['Content'] ?? '',
      startTime: json['StartTime'] ?? '',
      endTime: json['EndTime'],
      time: timeString,
      isDone: json['IsDone'] ?? false,
      schedulesType: json['SchedulesType'] ?? 'reminder',
      priority: json['Priority'] ?? 1,
      organizationId: json['OrganizationId'] ?? '',
      workspaceId: json['WorkspaceId'] ?? '',
      contact: contactInfo,
      repeatRule: json['RepeatRule'] != null 
          ? _parseRepeatRule(json['RepeatRule'])
          : null,
      notifyBefore: json['Reminders'] != null
          ? (json['Reminders'] as List).map((x) => NotifyBefore.fromJson(x)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Title': title,
      'Content': content,
      'StartTime': startTime,
      'EndTime': endTime,
      'Time': time,
      'IsDone': isDone,
      'SchedulesType': schedulesType,
      'Priority': priority,
      'OrganizationId': organizationId,
      'WorkspaceId': workspaceId,
      'Contact': contact?.toJson(),
      'RepeatRule': repeatRule?.map((x) => x.toJson()).toList(),
      'NotifyBefore': notifyBefore?.map((x) => x.toJson()).toList(),
    };
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? content,
    String? startTime,
    String? endTime,
    String? time,
    bool? isDone,
    String? schedulesType,
    int? priority,
    String? organizationId,
    String? workspaceId,
    ContactInfo? contact,
    List<RepeatRule>? repeatRule,
    List<NotifyBefore>? notifyBefore,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      time: time ?? this.time,
      isDone: isDone ?? this.isDone,
      schedulesType: schedulesType ?? this.schedulesType,
      priority: priority ?? this.priority,
      organizationId: organizationId ?? this.organizationId,
      workspaceId: workspaceId ?? this.workspaceId,
      contact: contact ?? this.contact,
      repeatRule: repeatRule ?? this.repeatRule,
      notifyBefore: notifyBefore ?? this.notifyBefore,
    );
  }
}

class ContactInfo {
  final String id;
  final String fullName;
  final String? phone;
  final String? avatar;

  ContactInfo({
    required this.id,
    required this.fullName,
    this.phone,
    this.avatar,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      avatar: json['Avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'Avatar': avatar,
    };
  }
}

class RepeatRule {
  final String day;

  RepeatRule({required this.day});

  factory RepeatRule.fromJson(Map<String, dynamic> json) {
    return RepeatRule(day: json['day'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'day': day};
  }
}

class NotifyBefore {
  final int minutes;
  final String type;

  NotifyBefore({required this.minutes, required this.type});

  factory NotifyBefore.fromJson(Map<String, dynamic> json) {
    int minutes = 0;
    
    // Parse time string format "HH:MM" to minutes
    if (json['time'] != null) {
      try {
        final timeParts = json['time'].toString().split(':');
        if (timeParts.length == 2) {
          final hours = int.parse(timeParts[0]);
          final mins = int.parse(timeParts[1]);
          minutes = (hours * 60) + mins;
        }
      } catch (e) {
        // If parsing fails, use default 0
      }
    } else if (json['minutes'] != null) {
      minutes = json['minutes'];
    }
    
    return NotifyBefore(
      minutes: minutes,
      type: json['type'] ?? 'popup',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minutes': minutes,
      'type': type,
    };
  }
} 