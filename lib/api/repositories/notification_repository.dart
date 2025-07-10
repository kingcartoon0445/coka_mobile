import '../api_client.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<Map<String, dynamic>> getNotifications({
    String? organizationId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = {
      'limit': limit,
      'offset': offset,
      'sort': '[{ "Column": "CreatedDate", "Dir": "DESC" }]',
    };
    
    if (organizationId != null) {
      queryParams['organizationId'] = organizationId;
    }
    
    final response = await _apiClient.dio.get(
      '/api/v1/notify/getlistpaging',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final response = await _apiClient.dio.get('/api/v1/notify/countunread');
    return response.data;
  }

  Future<Map<String, dynamic>> setNotificationRead(
    String notifyId, {
    int status = 0,
  }) async {
    final queryParams = {
      'notifyId': notifyId,
      'status': status,
    };
    final response = await _apiClient.dio.patch(
      '/api/v1/notify/updatestatus/notifyid',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> setAllNotificationsRead() async {
    final response = await _apiClient.dio.post('/api/v1/notify/readall');
    return response.data;
  }

  Future<Map<String, dynamic>> updateFCMToken({
    required String deviceId,
    required String fcmToken,
    required int status,
  }) async {
    final response = await _apiClient.dio.put(
      '/api/v1/user/fcm',
      data: {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'status': status,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await _apiClient.dio.get('/api/v1/setting/notify/getlist');
    return response.data;
  }

  Future<Map<String, dynamic>> updateNotificationSetting({
    required String id,
    required int status,
  }) async {
    final queryParams = {
      'id': id,
      'status': status,
    };
    final response = await _apiClient.dio.put(
      '/api/v1/setting/notify/update',
      queryParameters: queryParams,
    );
    return response.data;
  }
}
