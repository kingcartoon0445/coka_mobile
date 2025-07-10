import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coka/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_response.dart';
import '../../core/constants/automation_constants.dart';
import '../../models/automation/eviction_rule.dart';

class EvictionRuleService {
  static final String _baseUrl = "${ApiClient.baseUrl}${AutomationEndpoints.automationBase}";
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Convert API response to match EvictionRule model structure
  static Map<String, dynamic> _normalizeEvictionRuleResponse(Map<String, dynamic> item) {
    return {
      'id': item['id'],
      'name': item['name'],
      'organizationId': item['organizationId'],
      'condition': item['condition'],
      'duration': item['duration'],
      'hourFrame': item['hourFrame'],
      'notifications': item['notifications'],
      'rule': item['rule'],
      'notificationMessage': item['notificationMessage'],
      'teamId': item['teamId'],
      'stages': item['stages'],
      'maxAttempts': item['maxAttempts'],
      'isActive': item['status'] == 1, // API uses 'status' (1=active, 0=inactive)
      'createdAt': item['createdDate'],
      'updatedAt': item['lastModifiedDate'],
      'statistics': item['statistics'], // Extract statistics from API response
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

  static Future<Map<String, String>> _getHeaders({String? organizationId}) async {
    final headers = {
      'accept': '*/*',
      'Authorization': 'Bearer ${await _getAccessToken()}',
      'Content-Type': 'application/json',
    };

    if (organizationId != null) {
      headers['organizationId'] = organizationId;
    }

    return headers;
  }

  // Lấy danh sách quy tắc thu hồi
  static Future<ApiResponse<List<EvictionRule>>> getEvictionRuleList(
    String organizationId, {
    int? page,
    int? pageSize,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$_baseUrl/eviction/rule/getlistpaging')
          .replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));

      final response = await http.get(
        uri,
        headers: await _getHeaders(organizationId: organizationId),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('🔍 Eviction API Response JSON: $jsonData');

        // Handle actual response structure - API returns {code: 0, content: [...]}
        final List<EvictionRule> rules = [];

        if (jsonData['code'] == 0 && jsonData['content'] != null && jsonData['content'] is List) {
          final contentList = jsonData['content'] as List;
          for (var item in contentList) {
            try {
              // Convert to match our model structure
              final normalizedItem = _normalizeEvictionRuleResponse(item);
              rules.add(EvictionRule.fromJson(normalizedItem));
              print('✅ Successfully parsed eviction rule: ${normalizedItem['id']}');
            } catch (e) {
              print('⚠️ Failed to parse eviction rule: $e');
              print('⚠️ Raw item: $item');
            }
          }
        } else {
          print(
              '⚠️ Eviction response structure unexpected: code=${jsonData['code']}, content=${jsonData['content']}');
        }

        return ApiResponse.success(rules);
      } else {
        return ApiResponse.error('Không thể tải danh sách quy tắc thu hồi');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Lấy chi tiết quy tắc thu hồi
  static Future<ApiResponse<EvictionRule>> getEvictionRuleDetail(
    String organizationId,
    String ruleId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eviction/rule/$ruleId'),
        headers: await _getHeaders(organizationId: organizationId),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final rule = EvictionRule.fromJson(jsonData['data']);
        return ApiResponse.success(rule);
      } else {
        return ApiResponse.error('Không thể tải chi tiết quy tắc');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Tạo quy tắc thu hồi mới
  static Future<ApiResponse<EvictionRule>> createEvictionRule(
    String organizationId,
    EvictionRule rule,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/eviction/rule/create'),
        headers: await _getHeaders(organizationId: organizationId),
        body: json.encode(rule.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final createdRule = EvictionRule.fromJson(jsonData['data']);
        return ApiResponse.success(createdRule);
      } else {
        return ApiResponse.error('Không thể tạo quy tắc thu hồi');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Cập nhật quy tắc thu hồi
  static Future<ApiResponse<EvictionRule>> updateEvictionRule(
    String organizationId,
    String ruleId,
    EvictionRule rule,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/eviction/rule/$ruleId/update'),
        headers: await _getHeaders(organizationId: organizationId),
        body: json.encode(rule.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final updatedRule = EvictionRule.fromJson(jsonData['data']);
        return ApiResponse.success(updatedRule);
      } else {
        return ApiResponse.error('Không thể cập nhật quy tắc');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Xóa quy tắc thu hồi
  static Future<ApiResponse<bool>> deleteEvictionRule(
    String organizationId,
    String ruleId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/eviction/rule/$ruleId/delete'),
        headers: await _getHeaders(organizationId: organizationId),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Không thể xóa quy tắc');
      }
    } on SocketException {
      return ApiResponse.error('Không có kết nối internet');
    } on TimeoutException {
      return ApiResponse.error('Timeout - Vui lòng thử lại');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: $e');
    }
  }

  // Cập nhật trạng thái quy tắc thu hồi
  static Future<ApiResponse<bool>> updateEvictionRuleStatus(
    String organizationId,
    String ruleId,
    bool status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/eviction/rule/$ruleId/updatestatus'),
        headers: await _getHeaders(organizationId: organizationId),
        body: json.encode({'status': status}),
      );

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

  // Lấy lịch sử thực hiện quy tắc thu hồi
  static Future<ApiResponse<List<EvictionLog>>> getEvictionLogs(
    String organizationId,
    String ruleId, {
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;

      final uri = Uri.parse('$_baseUrl/eviction/rule/$ruleId/logs')
          .replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));

      final response = await http.get(
        uri,
        headers: await _getHeaders(organizationId: organizationId),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<EvictionLog> logs =
            (jsonData['data'] as List).map((item) => EvictionLog.fromJson(item)).toList();

        return ApiResponse.success(logs);
      } else {
        return ApiResponse.error('Không thể tải lịch sử thực hiện');
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
