import 'package:coka/api/api_client.dart';
import 'package:coka/models/api_response.dart';
import 'package:coka/models/wallet_info.dart';
import 'package:coka/models/package_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PaymentRepository {
  final ApiClient apiClient;
  static const storage = FlutterSecureStorage();

  PaymentRepository(this.apiClient);

  Future<String?> _getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  /// Lấy thông tin ví
  Future<ApiResponse<WalletInfo>> getWalletDetail(String orgId) async {
    try {
      final response = await apiClient.dio.get(
        'https://payment.coka.ai/api/v1/wallet/getdetail',
        options: Options(
          headers: {
            'organizationId': orgId,
            'Authorization': 'Bearer ${await _getAccessToken()}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final responseData = response.data;
      
      // Kiểm tra mã trả về
      if (responseData['code'] != 0) {
        return ApiResponse.error(responseData['message'] ?? 'Lỗi không xác định');
      }

      final walletInfo = WalletInfo.fromJson(responseData['content']);
      return ApiResponse.success(walletInfo);
    } catch (e) {
      return ApiResponse.error('Có lỗi xảy ra khi tải thông tin ví: ${e.toString()}');
    }
  }

  /// Lấy danh sách gói dịch vụ
  Future<ApiResponse<List<PackageData>>> getFeaturePackages(String orgId) async {
    try {
      final response = await apiClient.dio.get(
        'https://payment.coka.ai/api/v1/packages/feature/getlistpaging',
        queryParameters: {
          'PackageType': 'DATA_ENRICHMENT',
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
      
      // Kiểm tra mã trả về
      if (responseData['code'] != 0) {
        return ApiResponse.error(responseData['message'] ?? 'Lỗi không xác định');
      }

      // Parse dữ liệu
      final List<PackageData> packages = [];
      if (responseData['content'] != null && responseData['content'] is List) {
        for (var item in responseData['content']) {
          packages.add(PackageData.fromJson(item));
        }
      }

      return ApiResponse.success(packages);
    } catch (e) {
      return ApiResponse.error('Có lỗi xảy ra khi tải danh sách gói: ${e.toString()}');
    }
  }

  /// Đặt hàng và thanh toán gói
  Future<ApiResponse<void>> orderAndPayPackage({
    required String orgId,
    required String packageId,
    required String workspaceId,
  }) async {
    try {
      final response = await apiClient.dio.post(
        'https://payment.coka.ai/api/v1/transaction/package/orderandpayment',
        data: {
          'packageId': packageId,
          'type': 'FEATURE',
          'workspaceId': workspaceId,
          'paymentMethodId': '26934ad6-6e57-11ef-9351-02981be25414', // ID của ví Coka
        },
        options: Options(
          headers: {
            'organizationId': orgId,
            'Authorization': 'Bearer ${await _getAccessToken()}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;
      
      // Kiểm tra lỗi API
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return ApiResponse.error(data['message']);
      }

      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Có lỗi xảy ra khi thực hiện thanh toán: ${e.toString()}');
    }
  }
} 