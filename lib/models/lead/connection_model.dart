class ConnectionModel {
  final String id;
  final String title;
  final String connectionType; // 'facebook', 'zalo', 'tiktok', 'webhook', 'webform'
  final int status;
  final String? connectionState; // 'Chưa xác minh', 'Mất kết nối', 'Đang kết nối', 'Đã kết nối', 'Gỡ kết nối'
  final String organizationId;
  final String workspaceId;
  final String workspaceName;
  final String? provider;
  final String? url;
  final Map<String, dynamic>? additionalData;

  ConnectionModel({
    required this.id,
    required this.title,
    required this.connectionType,
    required this.status,
    this.connectionState,
    required this.organizationId,
    required this.workspaceId,
    required this.workspaceName,
    this.provider,
    this.url,
    this.additionalData,
  });

  factory ConnectionModel.fromWebform(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] ?? '',
      title: json['name'] ?? json['url'] ?? 'Web Form',
      connectionType: 'webform',
      status: json['status'] ?? 0,
      connectionState: json['connectionState'],
      organizationId: json['organizationId'] ?? '',
      workspaceId: json['workspaceId'] ?? '',
      workspaceName: json['workspaceName'] ?? 'Không có workspace',
      url: json['url'],
    );
  }

  factory ConnectionModel.fromFacebook(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] ?? '',
      title: json['name'] ?? 'Facebook Form',
      connectionType: 'facebook',
      status: json['status'] ?? 0,
      connectionState: json['connectionState'],
      organizationId: json['organizationId'] ?? '',
      workspaceId: json['workspaceId'] ?? '',
      workspaceName: json['workspaceName'] ?? 'Không có workspace',
      provider: 'FACEBOOK',
    );
  }

  factory ConnectionModel.fromZalo(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Zalo Form',
      connectionType: 'zalo',
      status: json['status'] ?? 0,
      connectionState: json['connectionState'],
      organizationId: json['organizationId'] ?? '',
      workspaceId: json['workspaceId'] ?? '',
      workspaceName: json['workspaceName'] ?? 'Không có workspace',
      provider: 'ZALO',
    );
  }

  factory ConnectionModel.fromTiktok(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Tiktok Form',
      connectionType: 'tiktok',
      status: json['status'] ?? 0,
      connectionState: json['connectionState'],
      organizationId: json['organizationId'] ?? '',
      workspaceId: json['workspaceId'] ?? '',
      workspaceName: json['workspaceName'] ?? 'Không có workspace',
      additionalData: {
        'authName': json['authName'],
        'subscribedId': json['subscribedId'] ?? json['id'],
        'pageId': json['pageId'],
        'formId': json['formId'],
      },
    );
  }

  factory ConnectionModel.fromWebhook(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Webhook',
      connectionType: 'webhook',
      status: json['status'] ?? 0,
      connectionState: json['connectionState'],
      organizationId: json['organizationId'] ?? '',
      workspaceId: json['workspaceId'] ?? '',
      workspaceName: json['workspaceName'] ?? 'Không có workspace',
    );
  }
} 