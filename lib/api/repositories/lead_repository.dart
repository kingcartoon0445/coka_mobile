import 'package:coka/api/api_client.dart';
import 'package:dio/dio.dart';

class LeadRepository {
  final ApiClient _apiClient;

  LeadRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // Lấy danh sách Webform
  Future<Map<String, dynamic>> getWebformList(String orgId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/integration/website/getlistpaging',
        queryParameters: {'limit': '1000'},
        headers: {
          'organizationId': orgId,
          'workspaceId': 'null',
        },
      );
      return response;
    } catch (error) {
      print('Error getting webform list: $error');
      rethrow;
    }
  }

  // Thêm Webform mới
  Future<Map<String, dynamic>> addWebform(String orgId, String workspaceId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/integration/website/create',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error adding webform: $error');
      rethrow;
    }
  }

  // Xóa Webform
  Future<Map<String, dynamic>> deleteWebform(String domainId, String orgId, String workspaceId) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.delete(
        '/api/v1/integration/website/delete/$domainId',
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error deleting webform: $error');
      rethrow;
    }
  }

  // Cập nhật trạng thái Webform
  Future<Map<String, dynamic>> updateStatusWebform(String domainId, String orgId, String workspaceId, int status) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.patch(
        '/api/v1/integration/website/updatestatus/$domainId',
        queryParameters: {'Status': status.toString()},
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error updating webform status: $error');
      rethrow;
    }
  }

  // Lấy danh sách Zalo Form
  Future<Map<String, dynamic>> getZaloFormList(String orgId, String workspaceId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/integration/zalo/form/getlistpaging',
        queryParameters: {'limit': '1000'},
        headers: {
          'organizationId': orgId,
          'workspaceId': workspaceId,
        },
      );
      return response;
    } catch (error) {
      print('Error getting zalo form list: $error');
      rethrow;
    }
  }

  // Cập nhật trạng thái Zalo Form
  Future<Map<String, dynamic>> updateStatusZaloform(String orgId, String workspaceId, String formId, int status) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.patch(
        '/api/v1/integration/zalo/form/updatestatus/$formId',
        data: {'status': status},
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error updating zalo form status: $error');
      rethrow;
    }
  }

  // Xóa Zalo Form
  Future<Map<String, dynamic>> deleteZaloform(String orgId, String workspaceId, String formId) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.delete(
        '/api/v1/integration/zalo/form/delete/$formId',
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error deleting zalo form: $error');
      rethrow;
    }
  }

  // Lấy danh sách Lead Form
  Future<Map<String, dynamic>> getLeadList(String orgId, String workspaceId, String provider) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/integration/lead/getlistpaging',
        queryParameters: {
          'Subscribed': 'leadgen',
          'limit': '1000',
          'Provider': provider,
        },
        headers: {
          'organizationId': orgId,
          'workspaceId': workspaceId,
        },
      );
      return response;
    } catch (error) {
      print('Error getting lead list: $error');
      rethrow;
    }
  }

  // Cập nhật trạng thái Lead Form
  Future<Map<String, dynamic>> updateStatusLeadgen(
      String orgId, String workspaceId, String subscribedId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.patch(
        '/api/v1/integration/lead/updatestatus/$subscribedId',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error updating lead status: $error');
      rethrow;
    }
  }

  // Xóa Lead
  Future<Map<String, dynamic>> deleteLead(String orgId, String leadId, String provider) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.delete(
        '/api/v1/integration/$leadId/delete',
        data: {'provider': provider},
        options: Options(
          headers: {
            'organizationId': orgId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error deleting lead: $error');
      rethrow;
    }
  }

  // Kết nối với Facebook Lead
  Future<Map<String, dynamic>> fbLeadConnect(String orgId, String workspaceId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/auth/facebook/lead',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error connecting to Facebook lead: $error');
      rethrow;
    }
  }

  // Kết nối với Zalo Lead
  Future<Map<String, dynamic>> zaloLeadConnect(String orgId, String workspaceId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/auth/zalo/lead',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error connecting to Zalo lead: $error');
      rethrow;
    }
  }

  // Auto mapping Zalo
  Future<Map<String, dynamic>> autoMappingZalo(String orgId, String workspaceId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/integration/zalo/form/mappinggenerator',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error auto mapping Zalo: $error');
      rethrow;
    }
  }

  // Kết nối với Zalo Form
  Future<Map<String, dynamic>> connectZaloform(String orgId, String workspaceId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/integration/zalo/form/connect',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error connecting to Zalo form: $error');
      rethrow;
    }
  }

  // Xác thực Webform
  Future<Map<String, dynamic>> verifyWebform(String domainId, String orgId, String workspaceId) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/integration/website/verify/$domainId',
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error verifying webform: $error');
      rethrow;
    }
  }

  // ==== WEBHOOK API ====
  // Lấy danh sách webhook
  Future<Map<String, dynamic>> webhookGetList(String orgId, [String? workspaceId]) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/integration/webhook/getlist',
        queryParameters: {'limit': '1000'},
        headers: {
          'organizationId': orgId,
          if (workspaceId != null) 'workspaceId': workspaceId,
        },
      );
      return response;
    } catch (error) {
      print('Error getting webhook list: $error');
      rethrow;
    }
  }

  // Lấy chi tiết webhook
  Future<Map<String, dynamic>> webhookGetDetail(String orgId, String workspaceId, String webhookId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/integration/webhook/$webhookId/getdetail',
        headers: {
          'organizationId': orgId,
          'workspaceId': workspaceId,
        },
      );
      return response;
    } catch (error) {
      print('Error getting webhook detail: $error');
      rethrow;
    }
  }

  // Tạo mới webhook
  Future<Map<String, dynamic>> webhookCreate(String orgId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/integration/webhook/create',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error creating webhook: $error');
      rethrow;
    }
  }

  // Cập nhật webhook
  Future<Map<String, dynamic>> webhookUpdate(String orgId, String webhookId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.patch(
        '/api/v1/integration/webhook/$webhookId/update',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error updating webhook: $error');
      rethrow;
    }
  }

  // Cập nhật trạng thái webhook
  Future<Map<String, dynamic>> webhookUpdateStatus(String orgId, String workspaceId, String webhookId, int status) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.patch(
        '/api/v1/integration/webhook/$webhookId/updatestatus',
        data: {'status': status},
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error updating webhook status: $error');
      rethrow;
    }
  }

  // Xóa webhook
  Future<Map<String, dynamic>> webhookDelete(String orgId, String workspaceId, String webhookId) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.delete(
        '/api/v1/integration/webhook/$webhookId/delete',
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error deleting webhook: $error');
      rethrow;
    }
  }

  // TikTok Form API
  // TikTok Lead Auth
  Future<Map<String, dynamic>> tiktokLeadAuth(
      String orgId, String workspaceId, String accessToken, [String redirectUrl = ""]) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.get(
        '/api/v1/integration/tiktok/auth/lead',
        queryParameters: {
          'organizationId': orgId,
          'workspaceId': workspaceId,
          'accessToken': accessToken,
          'redirectUrl': redirectUrl,
        },
        options: Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error authenticating TikTok lead: $error');
      rethrow;
    }
  }

  // Lấy danh sách TikTok Form
  Future<Map<String, dynamic>> getTiktokFormList(
      String orgId, String workspaceId, [String? subscribedId, bool? isConnect]) async {
    try {
      final queryParams = <String, dynamic>{};
      if (subscribedId != null) queryParams['SubscribedId'] = subscribedId;
      if (isConnect != null) queryParams['IsConnect'] = isConnect;

      final response = await _apiClient.get(
        '/api/v1/integration/tiktok/form/getlist',
        queryParameters: queryParams,
        headers: {
          'organizationId': orgId,
          'workspaceId': workspaceId,
        },
      );
      return response;
    } catch (error) {
      print('Error getting TikTok form list: $error');
      rethrow;
    }
  }

  // Lấy danh sách TikTok Form đã kết nối
  Future<Map<String, dynamic>> getTiktokFormListConnected(String orgId, String? workspaceId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/integration/tiktok/form/getlistconnected',
        headers: {
          'organizationId': orgId,
          if (workspaceId != null) 'workspaceId': workspaceId,
        },
      );
      return response;
    } catch (error) {
      print('Error getting connected TikTok form list: $error');
      rethrow;
    }
  }

  // Lấy chi tiết TikTok Form
  Future<Map<String, dynamic>> getTiktokFormDetail(
      String orgId, String workspaceId, String subscribedId, String pageId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/integration/tiktok/form/getdetail',
        queryParameters: {
          'SubscribedId': subscribedId,
          'PageId': pageId,
        },
        headers: {
          'organizationId': orgId,
          'workspaceId': workspaceId,
        },
      );
      return response;
    } catch (error) {
      print('Error getting TikTok form detail: $error');
      rethrow;
    }
  }

  // Tạo TikTok Form
  Future<Map<String, dynamic>> createTiktokForm(
      String orgId, String workspaceId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.post(
        '/api/v1/integration/tiktok/form/create',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error creating TikTok form: $error');
      rethrow;
    }
  }

  // Cập nhật TikTok Form
  Future<Map<String, dynamic>> updateTiktokForm(
      String orgId, String workspaceId, String formId, Map<String, dynamic> data) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.patch(
        '/api/v1/integration/tiktok/form/$formId/update',
        data: data,
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error updating TikTok form: $error');
      rethrow;
    }
  }

  // Cập nhật trạng thái TikTok Form
  Future<Map<String, dynamic>> updateTiktokFormStatus(String orgId, String workspaceId, String formId, int status) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.patch(
        '/api/v1/integration/tiktok/form/$formId/updatestatus',
        data: {'status': status},
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error updating TikTok form status: $error');
      rethrow;
    }
  }

  // Xóa TikTok Form
  Future<Map<String, dynamic>> deleteTiktokForm(String orgId, String workspaceId, String formId) async {
    try {
      final dio = _apiClient.dio;
      final response = await dio.delete(
        '/api/v1/integration/tiktok/form/$formId/delete',
        options: Options(
          headers: {
            'organizationId': orgId,
            'workspaceId': workspaceId,
          },
        ),
      );
      return response.data;
    } catch (error) {
      print('Error deleting TikTok form: $error');
      rethrow;
    }
  }
} 