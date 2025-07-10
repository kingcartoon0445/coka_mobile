import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_response.dart';
import '../../core/constants/automation_constants.dart';
import '../../models/automation/reminder_config.dart';

class ReminderConfigService {
  static const String _baseUrl = "${AutomationEndpoints.calendarBaseUrl}${AutomationEndpoints.reminderBase}";
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Convert PascalCase API response to camelCase for ReminderConfig model
  static Map<String, dynamic> _normalizePascalCaseToReminderConfig(Map<String, dynamic> item) {
    return {
      'id': item['Id'],
      'name': item['Name'],
      'organizationId': item['OrganizationId'],
      'workspaceId': item['WorkspaceIds'] != null && (item['WorkspaceIds'] as List).isNotEmpty 
          ? (item['WorkspaceIds'] as List).first 
          : null,
      'duration': item['Time'], // API uses 'Time' instead of 'duration'
      'hourFrame': item['HourFrame'],
      'notifications': item['Notifications'],
      'notificationMessage': item['NotificationMessage'],
      'weekdays': [], // Default empty, API doesn't seem to have this
      'repeatEnabled': (item['Repeat'] ?? 0) > 0,
      'repeatCount': item['Repeat'],
      'repeatInterval': item['RepeatTime'],
      'isActive': item['IsActive'],
      'createdAt': item['CreatedAt'],
      'updatedAt': item['LastModifiedDate'] ?? item['CreatedAt'],
      'report': item['Report'], // Extract Report from API response
    };
  }

  static Future<String> _getAccessToken() async {
    try {
      final token = await _storage.read(key: 'access_token');
      return token ?? '';
    } catch (e) {
      // Log error in production, you should use proper logging framework
      return '';
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    return {
      'accept': '*/*',
      'Authorization': 'Bearer ${await _getAccessToken()}',
      'Content-Type': 'application/json',
    };
  }

  // Lấy danh sách cấu hình nhắc hẹn
  static Future<ApiResponse<List<ReminderConfig>>> getReminderConfigList(
    String organizationId, {
    int? page,
    int? pageSize,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'OrganizationId': organizationId,
      };
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(_baseUrl)
          .replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<ReminderConfig> configs = (jsonData['data'] as List)
            .map((item) => ReminderConfig.fromJson(item))
            .toList();
        
        return ApiResponse.success(configs);
      } else {
        return ApiResponse.error('Không thể tải danh sách cấu hình nhắc hẹn');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Lấy danh sách cấu hình nhắc hẹn theo organization
  static Future<ApiResponse<List<ReminderConfig>>> getReminderConfigListByOrgId(
    String organizationId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/organization/$organizationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('🔍 Reminder API Response JSON (ByOrgId): $responseData');
        
        // Handle actual response structure - API returns array directly
        final List<ReminderConfig> configs = [];
        
        if (responseData is List) {
          for (var item in responseData) {
            try {
              // Convert PascalCase to camelCase for our model
              final normalizedItem = _normalizePascalCaseToReminderConfig(item);
              configs.add(ReminderConfig.fromJson(normalizedItem));
              print('✅ Successfully parsed reminder config: ${normalizedItem['id']}');
            } catch (e) {
              print('⚠️ Failed to parse reminder config: $e');
              print('⚠️ Raw item: $item');
            }
          }
        } else {
          print('⚠️ Reminder response is not a List: $responseData');
        }
        
        return ApiResponse.success(configs);
      } else {
        return ApiResponse.error('Không thể tải danh sách cấu hình');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Tạo cấu hình nhắc hẹn mới
  static Future<ApiResponse<ReminderConfig>> createReminderConfig(
    String organizationId,
    ReminderConfig config,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final createdConfig = ReminderConfig.fromJson(jsonData['data']);
        return ApiResponse.success(createdConfig);
      } else {
        return ApiResponse.error('Không thể tạo cấu hình nhắc hẹn');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Lấy chi tiết cấu hình nhắc hẹn
  static Future<ApiResponse<ReminderConfig>> getReminderConfigDetail(
    String organizationId,
    String configId,
  ) async {
    try {
      final queryParams = {'OrganizationId': organizationId};
      final uri = Uri.parse('$_baseUrl/$configId')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final config = ReminderConfig.fromJson(jsonData['data']);
        return ApiResponse.success(config);
      } else {
        return ApiResponse.error('Không thể tải chi tiết cấu hình');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Cập nhật cấu hình nhắc hẹn
  static Future<ApiResponse<ReminderConfig>> updateReminderConfig(
    String organizationId,
    String configId,
    ReminderConfig config,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/$configId'),
        headers: headers,
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final updatedConfig = ReminderConfig.fromJson(jsonData['data']);
        return ApiResponse.success(updatedConfig);
      } else {
        return ApiResponse.error('Không thể cập nhật cấu hình');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Xóa cấu hình nhắc hẹn
  static Future<ApiResponse<bool>> deleteReminderConfig(
    String organizationId,
    String configId,
  ) async {
    try {
      final queryParams = {'OrganizationId': organizationId};
      final uri = Uri.parse('$_baseUrl/$configId')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Không thể xóa cấu hình');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Bật/tắt cấu hình nhắc hẹn
  static Future<ApiResponse<bool>> toggleReminderConfigStatus(
    String organizationId,
    String configId,
  ) async {
    try {
      final queryParams = {'OrganizationId': organizationId};
      final uri = Uri.parse('$_baseUrl/$configId/toggle-active')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.patch(uri, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Không thể cập nhật trạng thái');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }
} 