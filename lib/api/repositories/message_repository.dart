import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:coka/api/api_client.dart';
import 'package:coka/api/api_path.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class MessageRepository {
  final ApiClient _apiClient;
  MessageRepository(this._apiClient);
  Future<Map<String, dynamic>> connectFacebook(
      String organizationId, String workspaceId, String data) async {
    log("Connecting Facebook with data: $data");
    final response = await _apiClient.dio.post(
      ApiPath.fbConnect3,
      data: data,
      options: Options(headers: {
        'organizationid': organizationId,
      }),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getPagesFaceWithToken(
    String tokenFB,
  ) async {
    log("Fetching Facebook pages with token: $tokenFB");
    String url = 'https://graph.facebook.com/v23.0/me/accounts?access_token=$tokenFB';
    final response = await Dio().get(
      url,
    );

    return json.decode(response.data);
  }

  Future<Map<String, dynamic>> getConversationList(
    String organizationId, {
    required String integrationAuthId,
    required String searchText,
    String sortDesc = 'CreatedDate DESC',
    required int page,
    String? provider,
  }) async {
    final queryParams = {
      'integrationAuthId': integrationAuthId,
      'searchText': searchText,
      'offset': page * 20,
      'limit': 20,
      'provider': provider,
      'sort': '[{ "Column": "CreatedDate", "Dir": "DESC" }]',
    };

    final response = await _apiClient.dio.get(
      ApiPath.conversationList,
      queryParameters: queryParams,
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateStatusReadRepos(
    String organizationId, {
    required String conversationId,
    String? provider,
  }) async {
    final response = await _apiClient.dio.patch(
      ApiPath.updateStatusRead(conversationId),
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future updateStatisOmniChannelRes(String id, status, organizationId) async {
    final response = await _apiClient.dio.patch(
      ApiPath.updateStatisOmniChannel(id),
      data: {"status": status},
      options: Options(headers: {'organizationid': organizationId}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getListMessagesConenction(String organizationId,
      {required String provider, required String subscribed, required String searchText}) async {
    final response = await _apiClient.dio.get(
      ApiPath.getListPage(provider, subscribed, searchText),
      options: Options(headers: {'organizationid': organizationId}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getChatList(
    String organizationId,
    String conversationId,
    int page,
  ) async {
    final queryParams = {
      'ConversationId': conversationId,
      'offset': page * 20,
      'limit': 20,
    };

    final response = await _apiClient.dio.get(
      ApiPath.chatList,
      queryParameters: queryParams,
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> sendFacebookMessage(
    String organizationId,
    String conversationId,
    String message, {
    String? messageId,
    List<Map<String, dynamic>>? attachments,
    File? attachment,
    String? attachmentName,
  }) async {
    final formData = FormData.fromMap({
      'conversationId': conversationId,
      'messageId': messageId ?? 'undefined',
      'message': message,
    });

    // ✅ Đính kèm 1 file đơn (ví dụ ảnh)
    if (attachment != null) {
      formData.files.add(MapEntry(
        'Attachment',
        await MultipartFile.fromFile(
          attachment.path,
          filename: attachmentName ?? attachment.path.split('/').last,
        ),
      ));
    }

    // ✅ Đính kèm nhiều file dạng Map (custom attachments nếu bạn xử lý dạng này)
    if (attachments != null && attachments.isNotEmpty) {
      for (final item in attachments) {
        final file = item['file'] as File?;
        final name = item['name'] as String?;
        if (file != null) {
          formData.files.add(MapEntry(
            'Attachment',
            await MultipartFile.fromFile(
              file.path,
              filename: name ?? file.path.split('/').last,
            ),
          ));
        }
      }
    }

    final response = await _apiClient.dio.post(
      ApiPath.sendMessage,
      data: formData,
      options: Options(headers: {'organizationid': organizationId}),
    );

    log("Sent message to ${ApiPath.sendMessage} | ${response.statusCode}");
    return response.data;
  }

  Future<Map<String, dynamic>> assignConversation(
    String organizationId,
    String conversationId,
    String userId,
  ) async {
    final response = await _apiClient.dio.patch(
      '${ApiPath.assignConversation}/$conversationId/assignto',
      data: {'assignTo': userId},
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateSubscription(
    String organizationId,
    String subscribedId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.patch(
      '${ApiPath.updateSubscription}/$subscribedId',
      data: body,
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getSubscriptions(
    String organizationId, {
    required bool subscribed,
    String? provider,
  }) async {
    final queryParams = {
      'offset': 0,
      'limit': 1000,
      'subscribed': subscribed,
      'provider': provider,
    };

    final response = await _apiClient.dio.get(
      ApiPath.subscriptionList,
      queryParameters: queryParams,
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAssignableUsers(
    String organizationId,
    String workspaceId,
  ) async {
    final response = await _apiClient.dio.get(
      ApiPath.assignableUsers,
      queryParameters: {'workspaceId': workspaceId},
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getTeamList(
    String organizationId,
    String workspaceId,
    String searchText, {
    bool isTreeView = false,
  }) async {
    final response = await _apiClient.dio.get(
      ApiPath.teamList,
      queryParameters: {
        'workspaceId': workspaceId,
        'searchText': searchText,
        'isTreeView': isTreeView,
        'offset': 0,
        'limit': 100,
      },
      options: Options(headers: {'organizationid': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> sendFileMessage(
    String organizationId,
    String conversationId,
    File file, {
    String? textMessage,
  }) async {
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();

    // MIME type map
    final mimeMap = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };

    final mimeType = mimeMap[fileExtension];
    if (mimeType == null) {
      throw Exception(
          'File extension .$fileExtension không hỗ trợ. Chỉ hỗ trợ: pdf, doc, docx, xls, xlsx');
    }

    final formData = FormData.fromMap({
      'conversationId': conversationId,
      'messageId': 'undefined',
      'message': textMessage ?? '',
      'Attachment': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    });

    try {
      final response = await _apiClient.dio.post(
        ApiPath.sendMessage,
        data: formData,
        options: Options(headers: {'organizationid': organizationId}),
      );

      if (response.data['code'] != null && response.data['code'] != 0) {
        final msg = response.data['message'] ?? 'Gửi file thất bại';
        throw Exception(msg);
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Lỗi không xác định khi gửi file';
        throw Exception(message);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendImageMessage(
    String organizationId,
    String conversationId,
    XFile imageFile, {
    String? textMessage,
  }) async {
    final formData = FormData.fromMap({
      'conversationId': conversationId,
      'messageId': 'undefined',
      'message': textMessage ?? '',
      'Attachment': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.name,
        contentType: MediaType('image', imageFile.path.split('.').last),
      ),
    });

    try {
      final response = await _apiClient.dio.post(
        ApiPath.sendMessage,
        data: formData,
        options: Options(headers: {'organizationid': organizationId}),
      );

      if (response.data['code'] != null && response.data['code'] != 0) {
        final msg = response.data['message'] ?? 'Gửi ảnh thất bại';
        throw Exception(msg);
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Lỗi không xác định khi gửi ảnh';
        throw Exception(message);
      }
      rethrow;
    }
  }
}
