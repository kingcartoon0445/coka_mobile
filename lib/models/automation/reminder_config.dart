class ReminderConfig {
  final String? id;
  final String? name;
  final String? organizationId;
  final String? workspaceId;
  final ReminderCondition? condition;
  final int? duration; // phút
  final List<String>? hourFrame;
  final List<String>? notifications;
  final String? notificationMessage;
  final List<String>? weekdays;
  final bool? repeatEnabled;
  final int? repeatCount;
  final int? repeatInterval; // phút
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic>? report; // API report data

  ReminderConfig({
    this.id,
    this.name,
    this.organizationId,
    this.workspaceId,
    this.condition,
    this.duration,
    this.hourFrame,
    this.notifications,
    this.notificationMessage,
    this.weekdays,
    this.repeatEnabled,
    this.repeatCount,
    this.repeatInterval,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.report,
  });

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    return ReminderConfig(
      id: json['id'],
      name: json['name'],
      organizationId: json['organizationId'],
      workspaceId: json['workspaceId'],
      condition: json['condition'] != null 
          ? ReminderCondition.fromJson(json['condition']) 
          : null,
      duration: json['duration'] is String ? int.tryParse(json['duration']) : json['duration'],
      hourFrame: json['hourFrame']?.cast<String>(),
      notifications: json['notifications']?.cast<String>(),
      notificationMessage: json['notificationMessage'],
      weekdays: json['weekdays']?.cast<String>(),
      repeatEnabled: json['repeatEnabled'],
      repeatCount: json['repeatCount'] is String ? int.tryParse(json['repeatCount']) : json['repeatCount'],
      repeatInterval: json['repeatInterval'] is String ? int.tryParse(json['repeatInterval']) : json['repeatInterval'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      report: json['report'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organizationId': organizationId,
      'workspaceId': workspaceId,
      'condition': condition?.toJson(),
      'duration': duration,
      'hourFrame': hourFrame,
      'notifications': notifications,
      'notificationMessage': notificationMessage,
      'weekdays': weekdays,
      'repeatEnabled': repeatEnabled,
      'repeatCount': repeatCount,
      'repeatInterval': repeatInterval,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'report': report,
    };
  }

  ReminderConfig copyWith({
    String? id,
    String? name,
    String? organizationId,
    String? workspaceId,
    ReminderCondition? condition,
    int? duration,
    List<String>? hourFrame,
    List<String>? notifications,
    String? notificationMessage,
    List<String>? weekdays,
    bool? repeatEnabled,
    int? repeatCount,
    int? repeatInterval,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? report,
  }) {
    return ReminderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      organizationId: organizationId ?? this.organizationId,
      workspaceId: workspaceId ?? this.workspaceId,
      condition: condition ?? this.condition,
      duration: duration ?? this.duration,
      hourFrame: hourFrame ?? this.hourFrame,
      notifications: notifications ?? this.notifications,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      weekdays: weekdays ?? this.weekdays,
      repeatEnabled: repeatEnabled ?? this.repeatEnabled,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      report: report ?? this.report,
    );
  }
}

class ReminderCondition {
  final String? conjunction;
  final List<ReminderCondition>? conditions;
  final String? field;
  final String? operator;
  final dynamic value;

  ReminderCondition({
    this.conjunction,
    this.conditions,
    this.field,
    this.operator,
    this.value,
  });

  factory ReminderCondition.fromJson(Map<String, dynamic> json) {
    return ReminderCondition(
      conjunction: json['conjunction'],
      conditions: json['conditions'] != null
          ? (json['conditions'] as List)
              .map((e) => ReminderCondition.fromJson(e))
              .toList()
          : null,
      field: json['field'],
      operator: json['operator'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conjunction': conjunction,
      'conditions': conditions?.map((e) => e.toJson()).toList(),
      'field': field,
      'operator': operator,
      'value': value,
    };
  }
} 