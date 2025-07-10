import 'package:coka/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/api_response.dart';

class StageApiService {
  // Khởi tạo Dio với baseUrl cố định cho API chính
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiClient.baseUrl, // 👈 base URL cho stage list API
      contentType: 'application/json',
      // timeout, headers mặc định… có thể thêm tại đây
    ),
  );

  // Dio riêng cho app.coka.ai APIs
  final Dio _appDio = Dio(
    BaseOptions(
      baseUrl: 'https://app.coka.ai', // 👈 base URL cho hidden stages API
      contentType: 'application/json',
    ),
  );

  // Secure storage để lấy token
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<ApiResponse> getStageList(String orgId, String workspaceId) async {
    try {
      final response = await _dio.get(
        '/api/v1/crm/category/stage/getlistpaging', // API endpoint mới
        queryParameters: {'limit': 1000},
        options: Options(headers: {
          'organizationId': orgId,
          'workspaceId': workspaceId,
          'Authorization': 'Bearer ${await getAccessToken()}',
          'accept': '*/*',
          'content-type': 'application/json',
        }),
      );

      return ApiResponse(
        isSuccess: response.statusCode == 200,
        data: response.data['content'] ?? response.data['data'] ?? response.data,
        message: response.data['message'] ?? '',
      );
    } catch (e) {
      return ApiResponse(
        isSuccess: false,
        data: [],
        message: e.toString(),
      );
    }
  }

  Future<HiddenStagesResponse> getHiddenStagesAndGroups(String orgId, String workspaceId) async {
    try {
      final response = await _appDio.get(
        // Sử dụng _appDio với base URL app.coka.ai
        '/api/stages/visibility', // Endpoint đúng cho visibility
        queryParameters: {'workspaceId': workspaceId},
        options: Options(headers: {
          'organizationId': orgId,
          'Authorization': 'Bearer ${await getAccessToken()}',
          'Accept-Language': 'vi-VN,vi;q=0.9,en-VN;q=0.8,en;q=0.7,fr-FR;q=0.6,fr;q=0.5,en-US;q=0.4',
          'Content-Type': 'application/json',
          'accept': '*/*',
          'Connection': 'keep-alive',
          'Sec-Fetch-Dest': 'empty',
          'Sec-Fetch-Mode': 'cors',
          'Sec-Fetch-Site': 'same-origin',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
          'sec-ch-ua': '"Google Chrome";v="137", "Chromium";v="137", "Not/A)Brand";v="24"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"Windows"',
        }),
      );

      return HiddenStagesResponse.fromJson(response.data);
    } catch (e) {
      // Nếu API visibility chưa có, trả về empty list
      print("Stage visibility API error: $e");
      return HiddenStagesResponse(hiddenStages: [], hiddenGroups: []);
    }
  }

  // Method để lấy access token từ secure storage
  Future<String> getAccessToken() async {
    try {
      final token = await _storage.read(key: 'access_token');
      return token ?? '';
    } catch (e) {
      print('Error getting access token: $e');
      return '';
    }
  }
}
