class EvictionRule {
  final String? id;
  final String? name;
  final String? organizationId;
  final EvictionCondition? condition;
  final int? duration; // phút
  final List<String>? hourFrame;
  final List<String>? notifications;
  final String? rule;
  final String? notificationMessage;
  final String? teamId;
  final List<EvictionStage>? stages;
  final int? maxAttempts;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic>? statistics; // API statistics data

  EvictionRule({
    this.id,
    this.name,
    this.organizationId,
    this.condition,
    this.duration,
    this.hourFrame,
    this.notifications,
    this.rule,
    this.notificationMessage,
    this.teamId,
    this.stages,
    this.maxAttempts,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.statistics,
  });

  factory EvictionRule.fromJson(Map<String, dynamic> json) {
    return EvictionRule(
      id: json['id'],
      name: json['name'],
      organizationId: json['organizationId'],
      condition: json['condition'] != null 
          ? EvictionCondition.fromJson(json['condition']) 
          : null,
      duration: json['duration'] is String ? int.tryParse(json['duration']) : json['duration'],
      hourFrame: json['hourFrame']?.cast<String>(),
      notifications: json['notifications']?.cast<String>(),
      rule: json['rule'],
      notificationMessage: json['notificationMessage'],
      teamId: json['teamId'],
      stages: json['stages'] != null
          ? (json['stages'] as List)
              .map((e) => EvictionStage.fromJson(e))
              .toList()
          : null,
      maxAttempts: json['maxAttempts'] is String ? int.tryParse(json['maxAttempts']) : json['maxAttempts'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      statistics: json['statistics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organizationId': organizationId,
      'condition': condition?.toJson(),
      'duration': duration,
      'hourFrame': hourFrame,
      'notifications': notifications,
      'rule': rule,
      'notificationMessage': notificationMessage,
      'teamId': teamId,
      'stages': stages?.map((e) => e.toJson()).toList(),
      'maxAttempts': maxAttempts,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'statistics': statistics,
    };
  }

  EvictionRule copyWith({
    String? id,
    String? name,
    String? organizationId,
    EvictionCondition? condition,
    int? duration,
    List<String>? hourFrame,
    List<String>? notifications,
    String? rule,
    String? notificationMessage,
    String? teamId,
    List<EvictionStage>? stages,
    int? maxAttempts,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? statistics,
  }) {
    return EvictionRule(
      id: id ?? this.id,
      name: name ?? this.name,
      organizationId: organizationId ?? this.organizationId,
      condition: condition ?? this.condition,
      duration: duration ?? this.duration,
      hourFrame: hourFrame ?? this.hourFrame,
      notifications: notifications ?? this.notifications,
      rule: rule ?? this.rule,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      teamId: teamId ?? this.teamId,
      stages: stages ?? this.stages,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statistics: statistics ?? this.statistics,
    );
  }
}

class EvictionCondition {
  final String? conjunction; // "and", "or"
  final List<EvictionCondition>? conditions;
  final String? field;
  final String? operator;
  final dynamic value;

  EvictionCondition({
    this.conjunction,
    this.conditions,
    this.field,
    this.operator,
    this.value,
  });

  factory EvictionCondition.fromJson(Map<String, dynamic> json) {
    return EvictionCondition(
      conjunction: json['conjunction'],
      conditions: json['conditions'] != null
          ? (json['conditions'] as List)
              .map((e) => EvictionCondition.fromJson(e))
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

class EvictionStage {
  final String? stageId;

  EvictionStage({this.stageId});

  factory EvictionStage.fromJson(Map<String, dynamic> json) {
    return EvictionStage(stageId: json['stageId']);
  }

  Map<String, dynamic> toJson() {
    return {'stageId': stageId};
  }
}

class EvictionLog {
  final String? id;
  final String? ruleId;
  final String? contactId;
  final String? fromUserId;
  final String? toUserId;
  final String? status;
  final String? reason;
  final DateTime? executedAt;
  final DateTime? createdAt;

  EvictionLog({
    this.id,
    this.ruleId,
    this.contactId,
    this.fromUserId,
    this.toUserId,
    this.status,
    this.reason,
    this.executedAt,
    this.createdAt,
  });

  factory EvictionLog.fromJson(Map<String, dynamic> json) {
    return EvictionLog(
      id: json['id'],
      ruleId: json['ruleId'],
      contactId: json['contactId'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      status: json['status'],
      reason: json['reason'],
      executedAt: json['executedAt'] != null 
          ? DateTime.parse(json['executedAt']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }
}

class EvictionRuleResponse {
  final int code;
  final String message;
  final List<EvictionRule> content;

  const EvictionRuleResponse({
    required this.code,
    required this.message,
    required this.content,
  });

  factory EvictionRuleResponse.fromJson(Map<String, dynamic> json) {
    return EvictionRuleResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => EvictionRule.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'content': content.map((rule) => rule.toJson()).toList(),
    };
  }
} 