class Campaign {
  final String id;
  final String organizationId;
  final String title;
  final String? packageUsageId;
  final String? telephoneNumber;
  final int retryCountOnFailure;
  final int failureRetryDelay;
  final bool isAllowCallsOutside;
  final bool isAutoUpdateStage;
  final bool isAllowManualDialing;
  final bool isAutoEndIfNoAnswer;
  final String? content;
  final int status;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;

  Campaign({
    required this.id,
    required this.organizationId,
    required this.title,
    this.packageUsageId,
    this.telephoneNumber,
    required this.retryCountOnFailure,
    required this.failureRetryDelay,
    required this.isAllowCallsOutside,
    required this.isAutoUpdateStage,
    required this.isAllowManualDialing,
    required this.isAutoEndIfNoAnswer,
    this.content,
    required this.status,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? '',
      organizationId: json['organizationId'] ?? '',
      title: json['title'] ?? '',
      packageUsageId: json['packageUsageId'],
      telephoneNumber: json['telephoneNumber'],
      retryCountOnFailure: json['retryCountOnFailure'] ?? 0,
      failureRetryDelay: json['failureRetryDelay'] ?? 0,
      isAllowCallsOutside: json['isAllowCallsOutside'] ?? false,
      isAutoUpdateStage: json['isAutoUpdateStage'] ?? false,
      isAllowManualDialing: json['isAllowManualDialing'] ?? false,
      isAutoEndIfNoAnswer: json['isAutoEndIfNoAnswer'] ?? false,
      content: json['content'],
      status: json['status'] ?? 0,
      createdBy: json['createdBy'] ?? '',
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : DateTime.now(),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: json['lastModifiedDate'] != null 
          ? DateTime.parse(json['lastModifiedDate']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'title': title,
      'packageUsageId': packageUsageId,
      'telephoneNumber': telephoneNumber,
      'retryCountOnFailure': retryCountOnFailure,
      'failureRetryDelay': failureRetryDelay,
      'isAllowCallsOutside': isAllowCallsOutside,
      'isAutoUpdateStage': isAutoUpdateStage,
      'isAllowManualDialing': isAllowManualDialing,
      'isAutoEndIfNoAnswer': isAutoEndIfNoAnswer,
      'content': content,
      'status': status,
      'createdBy': createdBy,
      'createdDate': createdDate.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
    };
  }
} 