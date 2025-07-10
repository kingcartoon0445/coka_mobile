class WorkspaceData {
  String? id;
  String workspaceId;
  String workspaceName;
  String? packageName;
  String statusName;
  int usage;
  int usageLimit;

  WorkspaceData({
    this.id,
    required this.workspaceId,
    required this.workspaceName,
    this.packageName,
    required this.statusName,
    required this.usage,
    required this.usageLimit,
  });

  factory WorkspaceData.fromJson(Map<String, dynamic> json) {
    return WorkspaceData(
      id: json['id'],
      workspaceId: json['workspaceId'] ?? '',
      workspaceName: json['workspaceName'] ?? '',
      packageName: json['packageName'],
      statusName: json['statusName'] ?? 'Chưa kích hoạt',
      usage: json['usage'] ?? 0,
      usageLimit: json['usageLimit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'packageName': packageName,
      'statusName': statusName,
      'usage': usage,
      'usageLimit': usageLimit,
    };
  }

  // Helper method để kiểm tra trạng thái
  bool get isActive => statusName == "Đang chạy";
  bool get isExpired => statusName == "Hết hạn" || statusName == "Hết hạn mức";
  bool get isPaused => statusName == "Tạm dừng";
  bool get isInactive => statusName == "Chưa kích hoạt";
  
  // Helper method để tính phần trăm sử dụng
  double get usagePercentage {
    if (usageLimit == 0) return 0.0;
    return (usage / usageLimit).clamp(0.0, 1.0);
  }
} 