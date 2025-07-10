class AutomationEndpoints {
  static const String calendarBaseUrl = "https://calendar.coka.ai";

  // Eviction (Recall) endpoints
  static const String automationBase = "/api/v1/automation";

  // Reminder endpoints
  static const String reminderBase = "/api/ReminderConfig";
}

class AutomationConstants {
  // Rule types for eviction
  static const String assignTo = "ASSIGN_TO";
  static const String unassign = "UNASSIGN";

  // Notification types
  static const String email = "EMAIL";
  static const String sms = "SMS";
  static const String push = "PUSH";

  // Condition operators
  static const String equals = "equals";
  static const String notEquals = "not_equals";
  static const String contains = "contains";
  static const String inList = "in";
  static const String notIn = "not_in";

  // Conjunctions
  static const String and = "and";
  static const String or = "or";

  // Weekdays
  static const List<String> weekdays = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday"
  ];
}
