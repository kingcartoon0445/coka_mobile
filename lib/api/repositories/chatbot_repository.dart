import 'package:coka/api/api_path.dart';

import '../api_client.dart';

class ChatbotRepository {
  final ApiClient _apiClient;

  ChatbotRepository(this._apiClient);

  Future<Map<String, dynamic>> getChatbotList(String organizationId) async {
    try {
      return await _apiClient.get(
        ApiPath.chatbotPaging,
        headers: {'organizationId': organizationId},
      );
    } catch (e) {
      print('Lỗi khi lấy danh sách chatbot: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChatbotDetail(String organizationId, String chatbotId) async {
    try {
      return await _apiClient.get(
        ApiPath.chatbotDetail(chatbotId),
        headers: {'organizationId': organizationId},
      );
    } catch (e) {
      print('Lỗi khi lấy chi tiết chatbot: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createChatbot(
      String organizationId, Map<String, dynamic> data) async {
    try {
      return await _apiClient.post(
        ApiPath.chatbotCreate,
        data: data,
        headers: {'organizationId': organizationId},
      );
    } catch (e) {
      print('Lỗi khi tạo chatbot: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChatbot(
      String organizationId, String chatbotId, Map<String, dynamic> data) async {
    try {
      return await _apiClient.patch(
        ApiPath.chatbotUpdate(chatbotId),
        data: data,
        headers: {'organizationId': organizationId},
      );
    } catch (e) {
      print('Lỗi khi cập nhật chatbot: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChatbotStatus(
      String organizationId, String chatbotId, int status) async {
    try {
      return await _apiClient.patch(
        ApiPath.chatbotUpdateStatus(chatbotId),
        data: {'status': status},
        headers: {'organizationId': organizationId},
      );
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái chatbot: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChatbotConversationStatus(
    String organizationId,
    String conversationId,
    int status,
  ) async {
    try {
      return await _apiClient.patch(
        ApiPath.chatbotConversationUpdateStatus(conversationId, status),
        headers: {'organizationId': organizationId},
      );
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái hội thoại chatbot: $e');
      rethrow;
    }
  }
}
