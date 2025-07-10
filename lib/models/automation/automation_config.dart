import 'eviction_rule.dart';
import 'reminder_config.dart';

class AutomationConfig {
  final String id;
  final String name;
  final String organizationId;
  final String configType; // 'reminder' hoặc 'recall'
  final bool isActive;
  final DateTime formattedCreatedAt;
  final String? notificationMessage;
  final int? duration;
  final List<String>? hourFrame;
  final List<String>? workspaceIds;
  final List<String>? sourceIds;
  final List<String>? utmSources;
  final List<String>? stages;
  final int? repeat;
  final int? repeatTime;
  // Cho recall config
  final String? rule;
  final String? teamId;
  final int? maxAttempts;
  final dynamic condition;
  final List<String>? weekdays;
  final bool? repeatEnabled;
  final int? repeatCount;
  final int? repeatInterval;
  // Statistics fields
  final List<dynamic>? statistics; // For eviction rules
  final List<dynamic>? report; // For reminder configs
  final List<String>? notifications; // For eviction rules

  const AutomationConfig({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.configType,
    required this.isActive,
    required this.formattedCreatedAt,
    this.notificationMessage,
    this.duration,
    this.hourFrame,
    this.workspaceIds,
    this.sourceIds,
    this.utmSources,
    this.stages,
    this.repeat,
    this.repeatTime,
    this.rule,
    this.teamId,
    this.maxAttempts,
    this.condition,
    this.weekdays,
    this.repeatEnabled,
    this.repeatCount,
    this.repeatInterval,
    this.statistics,
    this.report,
    this.notifications,
  });

  factory AutomationConfig.fromEvictionRule(EvictionRule rule) {
    return AutomationConfig(
      id: rule.id ?? '',
      name: rule.name ?? 'Quy tắc thu hồi',
      organizationId: rule.organizationId ?? '',
      configType: 'recall',
      isActive: rule.isActive ?? false,
      formattedCreatedAt: rule.createdAt ?? DateTime.now(),
      notificationMessage: rule.notificationMessage,
      duration: rule.duration,
      hourFrame: rule.hourFrame,
      rule: rule.rule,
      teamId: rule.teamId,
      maxAttempts: rule.maxAttempts,
      condition: rule.condition?.toJson(),
      statistics: rule.statistics, // Extract from EvictionRule
      notifications: rule.notifications,
    );
  }

  factory AutomationConfig.fromReminderConfig(ReminderConfig config) {
    return AutomationConfig(
      id: config.id ?? '',
      name: config.name ?? 'Cấu hình nhắc hẹn',
      organizationId: config.organizationId ?? '',
      configType: 'reminder',
      isActive: config.isActive ?? false,
      formattedCreatedAt: config.createdAt ?? DateTime.now(),
      notificationMessage: config.notificationMessage,
      duration: config.duration,
      hourFrame: config.hourFrame,
      workspaceIds: config.workspaceId != null ? [config.workspaceId!] : null,
      weekdays: config.weekdays,
      repeatEnabled: config.repeatEnabled,
      repeatCount: config.repeatCount,
      repeatInterval: config.repeatInterval,
      condition: config.condition?.toJson(),
      report: config.report, // Extract from ReminderConfig
    );
  }

  AutomationConfig copyWith({
    String? id,
    String? name,
    String? organizationId,
    String? configType,
    bool? isActive,
    DateTime? formattedCreatedAt,
    String? notificationMessage,
    int? duration,
    List<String>? hourFrame,
    List<String>? workspaceIds,
    List<String>? sourceIds,
    List<String>? utmSources,
    List<String>? stages,
    int? repeat,
    int? repeatTime,
    String? rule,
    String? teamId,
    int? maxAttempts,
    dynamic condition,
    List<String>? weekdays,
    bool? repeatEnabled,
    int? repeatCount,
    int? repeatInterval,
    List<dynamic>? statistics,
    List<dynamic>? report,
    List<String>? notifications,
  }) {
    return AutomationConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      organizationId: organizationId ?? this.organizationId,
      configType: configType ?? this.configType,
      isActive: isActive ?? this.isActive,
      formattedCreatedAt: formattedCreatedAt ?? this.formattedCreatedAt,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      duration: duration ?? this.duration,
      hourFrame: hourFrame ?? this.hourFrame,
      workspaceIds: workspaceIds ?? this.workspaceIds,
      sourceIds: sourceIds ?? this.sourceIds,
      utmSources: utmSources ?? this.utmSources,
      stages: stages ?? this.stages,
      repeat: repeat ?? this.repeat,
      repeatTime: repeatTime ?? this.repeatTime,
      rule: rule ?? this.rule,
      teamId: teamId ?? this.teamId,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      condition: condition ?? this.condition,
      weekdays: weekdays ?? this.weekdays,
      repeatEnabled: repeatEnabled ?? this.repeatEnabled,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      statistics: statistics ?? this.statistics,
      report: report ?? this.report,
      notifications: notifications ?? this.notifications,
    );
  }
}

class AutomationState {
  final List<AutomationConfig> configs;
  final bool isLoading;
  final Map<String, bool> isUpdating;
  final String? error;
  final int refreshTrigger;

  const AutomationState({
    this.configs = const [],
    this.isLoading = false,
    this.isUpdating = const {},
    this.error,
    this.refreshTrigger = 0,
  });

  AutomationState copyWith({
    List<AutomationConfig>? configs,
    bool? isLoading,
    Map<String, bool>? isUpdating,
    String? error,
    int? refreshTrigger,
  }) {
    return AutomationState(
      configs: configs ?? this.configs,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      refreshTrigger: refreshTrigger ?? this.refreshTrigger,
    );
  }
}

class DialogState {
  final bool reminderConfigOpen;
  final bool recallConfigOpen;
  final bool alertOpen;
  final bool toggleAlertOpen;
  final AutomationConfig? selectedConfig;
  final AutomationConfig? configToDelete;
  final AutomationConfig? configToToggle;

  const DialogState({
    this.reminderConfigOpen = false,
    this.recallConfigOpen = false,
    this.alertOpen = false,
    this.toggleAlertOpen = false,
    this.selectedConfig,
    this.configToDelete,
    this.configToToggle,
  });

  DialogState copyWith({
    bool? reminderConfigOpen,
    bool? recallConfigOpen,
    bool? alertOpen,
    bool? toggleAlertOpen,
    AutomationConfig? selectedConfig,
    AutomationConfig? configToDelete,
    AutomationConfig? configToToggle,
  }) {
    return DialogState(
      reminderConfigOpen: reminderConfigOpen ?? this.reminderConfigOpen,
      recallConfigOpen: recallConfigOpen ?? this.recallConfigOpen,
      alertOpen: alertOpen ?? this.alertOpen,
      toggleAlertOpen: toggleAlertOpen ?? this.toggleAlertOpen,
      selectedConfig: selectedConfig ?? this.selectedConfig,
      configToDelete: configToDelete ?? this.configToDelete,
      configToToggle: configToToggle ?? this.configToToggle,
    );
  }
} 