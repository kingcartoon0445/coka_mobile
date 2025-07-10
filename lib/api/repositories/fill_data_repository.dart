import 'package:coka/api/api_client.dart';
import 'package:coka/models/api_response.dart';
import 'package:coka/models/workspace_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FillDataRepository {
  final ApiClient apiClient;
  static const storage = FlutterSecureStorage();

  FillDataRepository(this.apiClient);

  Future<String?> _getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  /// Lấy danh sách workspace fill data
  Future<ApiResponse<List<WorkspaceData>>> getFillDataList(String orgId) async {
    try {
      // Sử dụng domain riêng cho payment API
      final response = await apiClient.dio.get(
        'https://payment.coka.ai/api/v1/data-enrichment/getlist',
        options: Options(
          headers: {
            'organizationId': orgId,
            'Authorization': 'Bearer ${await _getAccessToken()}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final responseData = response.data;
      
      // Kiểm tra lỗi API
      if (responseData['message'] != null && responseData['message'].toString().isNotEmpty) {
        return ApiResponse.error(responseData['message']);
      }

      // Parse dữ liệu
      final List<WorkspaceData> workspaces = [];
      if (responseData['content'] != null && responseData['content'] is List) {
        for (var item in responseData['content']) {
          workspaces.add(WorkspaceData.fromJson(item));
        }
      }

      return ApiResponse.success(workspaces);
    } catch (e) {
      return ApiResponse.error('Có lỗi xảy ra khi tải danh sách workspace: ${e.toString()}');
    }
  }

  /// Cập nhật trạng thái workspace
  Future<ApiResponse<void>> updateFillDataStatus(
    String orgId, 
    String id, 
    int status
  ) async {
    try {
      final response = await apiClient.dio.patch(
        'https://payment.coka.ai/api/v1/data-enrichment/$id/updatestatus',
        queryParameters: {
          'Status': status,
        },
        options: Options(
          headers: {
            'organizationId': orgId,
            'Authorization': 'Bearer ${await _getAccessToken()}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final responseData = response.data;
      
      // Kiểm tra lỗi API
      if (responseData['message'] != null && responseData['message'].toString().isNotEmpty) {
        return ApiResponse.error(responseData['message']);
      }

      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Có lỗi xảy ra khi cập nhật trạng thái: ${e.toString()}');
    }
  }
} 