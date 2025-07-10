import '../api_client.dart';
import 'dart:io';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<Map<String, dynamic>> updateFcmToken({
    required String deviceId,
    required String fcmToken,
    required int status,
  }) async {
    final data = {
      "deviceId": deviceId,
      "fcmToken": fcmToken,
      "status": status,
    };
    print(data);
    
    final response = await _apiClient.dio.put(
      '/api/v1/user/fcm',
      data: data,
    );
    
    return response.data;
  }

  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        return 'android_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isIOS) {
        return 'ios_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Fallback cho các platform khác
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      // Fallback nếu không get được device info
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
} 