import 'package:flutter/material.dart';
import 'package:coka/api/repositories/lead_repository.dart';
import 'package:coka/models/lead/connection_model.dart';
import '../../core/utils/helpers.dart';
class MultiSourceConnectionProvider extends ChangeNotifier {
  final LeadRepository _leadRepository;
  
  MultiSourceConnectionProvider({required LeadRepository leadRepository})
      : _leadRepository = leadRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<ConnectionModel> _connections = [];
  List<ConnectionModel> get connections => _connections;
  
  Map<String, List<ConnectionModel>> _groupedConnections = {};
  Map<String, List<ConnectionModel>> get groupedConnections => _groupedConnections;

  // Load tất cả kết nối 
  Future<void> loadAllConnections(String organizationId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Reset danh sách kết nối
      _connections = [];
      
      // Load Webforms
      final webformsResponse = await _leadRepository.getWebformList(organizationId);
      if (webformsResponse['code'] == 0 && webformsResponse['content'] != null) {
        final List<dynamic> webforms = webformsResponse['content'];
        _connections.addAll(
          webforms.map((item) => ConnectionModel.fromWebform(item)).toList()
        );
      }
      
      // Load Facebook leads
      final fbLeadsResponse = await _leadRepository.getLeadList(organizationId, "null", "FACEBOOK");
      if (fbLeadsResponse['code'] == 0 && fbLeadsResponse['content'] != null) {
        final List<dynamic> fbLeads = fbLeadsResponse['content'];
        _connections.addAll(
          fbLeads.map((item) => ConnectionModel.fromFacebook(item)).toList()
        );
      }
      
      // Load Zalo forms
      final zaloFormsResponse = await _leadRepository.getZaloFormList(organizationId, "null");
      if (zaloFormsResponse['code'] == 0 && zaloFormsResponse['content'] != null) {
        final List<dynamic> zaloForms = zaloFormsResponse['content'];
        _connections.addAll(
          zaloForms.map((item) => ConnectionModel.fromZalo(item)).toList()
        );
      }
      
      // Load TikTok forms
      final tiktokFormsResponse = await _leadRepository.getTiktokFormListConnected(organizationId, null);
      if (tiktokFormsResponse['code'] == 0 && tiktokFormsResponse['content'] != null) {
        final List<dynamic> tiktokForms = tiktokFormsResponse['content'];
        _connections.addAll(
          tiktokForms.map((item) => ConnectionModel.fromTiktok(item)).toList()
        );
      }
      
      // Load Webhooks
      final webhooksResponse = await _leadRepository.webhookGetList(organizationId);
      if (webhooksResponse['code'] == 0 && webhooksResponse['content'] != null) {
        final List<dynamic> webhooks = webhooksResponse['content'];
        _connections.addAll(
          webhooks.map((item) => ConnectionModel.fromWebhook(item)).toList()
        );
      }
      
      // Nhóm kết nối theo workspace
      _groupConnections();
    } catch (e) {
      print('Error loading connections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Nhóm kết nối theo workspace
  void _groupConnections() {
    _groupedConnections = {};
    
    for (final connection in _connections) {
      final workspaceName = connection.workspaceName;
      if (!_groupedConnections.containsKey(workspaceName)) {
        _groupedConnections[workspaceName] = [];
      }
      _groupedConnections[workspaceName]!.add(connection);
    }
  }
  
  // Thay thế một kết nối cụ thể trong danh sách
  void replaceConnection(int index, ConnectionModel newConnection) {
    if (index >= 0 && index < _connections.length) {
      _connections[index] = newConnection;
      _groupConnections(); // Cập nhật danh sách đã nhóm
      notifyListeners();
    }
  }
  
  // Cập nhật toàn bộ danh sách kết nối
  void updateConnections(List<ConnectionModel> newConnections) {
    _connections = newConnections;
    _groupConnections(); // Nhóm lại kết nối
    notifyListeners();
  }
  
  // Cập nhật trạng thái kết nối
  Future<void> updateConnectionStatus(
    String organizationId, 
    ConnectionModel connection,
    int newStatus,
  ) async {
    try {
      bool success = false;
      
      switch (connection.connectionType) {
        case 'webform':
          final response = await _leadRepository.updateStatusWebform(
            connection.id,
            organizationId,
            connection.workspaceId,
            newStatus,
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'facebook':
          final response = await _leadRepository.updateStatusLeadgen(
            organizationId,
            connection.workspaceId,
            connection.id,
            {'status': newStatus},
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'zalo':
          final response = await _leadRepository.updateStatusZaloform(
            organizationId,
            connection.workspaceId,
            connection.id,
            newStatus,
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'tiktok':
          final response = await _leadRepository.updateTiktokFormStatus(
            organizationId,
            connection.workspaceId,
            connection.id,
            newStatus,
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'webhook':
          final response = await _leadRepository.webhookUpdateStatus(
            organizationId,
            connection.workspaceId,
            connection.id,
            newStatus,
          );
          success = Helpers.isResponseSuccess(response);
          break;
      }
      
      if (success) {
        // Cập nhật lại danh sách kết nối
        await loadAllConnections(organizationId);
      }
    } catch (e) {
      print('Error updating connection status: $e');
    }
  }
  
  // Xóa kết nối
  Future<void> deleteConnection(
    String organizationId,
    ConnectionModel connection,
  ) async {
    try {
      bool success = false;
      
      switch (connection.connectionType) {
        case 'webform':
          final response = await _leadRepository.deleteWebform(
            connection.id,
            organizationId,
            connection.workspaceId,
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'facebook':
          final response = await _leadRepository.deleteLead(
            organizationId,
            connection.id,
            'FACEBOOK',
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'zalo':
          final response = await _leadRepository.deleteZaloform(
            organizationId,
            connection.workspaceId,
            connection.id,
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'tiktok':
          final response = await _leadRepository.deleteTiktokForm(
            organizationId,
            connection.workspaceId,
            connection.id,
          );
          success = Helpers.isResponseSuccess(response);
          break;
          
        case 'webhook':
          final response = await _leadRepository.webhookDelete(
            organizationId,
            connection.workspaceId,
            connection.id,
          );
          success = Helpers.isResponseSuccess(response);
          break;
      }
      
      if (success) {
        // Cập nhật lại danh sách kết nối
        await loadAllConnections(organizationId);
      }
    } catch (e) {
      print('Error deleting connection: $e');
    }
  }

  // Phương thức tạo mới Webform
  Future<ConnectionModel?> createWebform(
    String organizationId,
    String workspaceId,
    String url,
  ) async {
    try {
      // Chuẩn bị dữ liệu để tạo webform
      final Map<String, dynamic> data = {
        'title': 'Webform $url',
        'url': url,
        'workspaceId': workspaceId,
      };
      
      // Gọi API để tạo webform
      final response = await _leadRepository.addWebform(
        organizationId,
        workspaceId,
        data,
      );
      
      // Kiểm tra kết quả
      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        // Tạo thành công, load lại danh sách kết nối
        await loadAllConnections(organizationId);
        
        // Tìm webform vừa tạo trong danh sách
        for (var connection in _connections) {
          if (connection.connectionType == 'webform' && connection.url == url) {
            return connection;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error creating webform: $e');
      return null;
    }
  }
  
  // Phương thức tạo mới Webhook
  Future<String?> createWebhook(
    String organizationId,
    String workspaceId,
    String title,
    String source,
  ) async {
    try {
      // Chuẩn bị dữ liệu để tạo webhook
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      
      final Map<String, dynamic> data = {
        'title': title.isEmpty ? 'Webhook $source' : title,
        'workspaceId': workspaceId,
        'source': source,
        'expiryDate': expiryDate.toUtc().toIso8601String(),
      };
      
      // Gọi API để tạo webhook
      final response = await _leadRepository.webhookCreate(
        organizationId,
        data,
      );
      
      // Kiểm tra kết quả
      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        // Tạo thành công, load lại danh sách kết nối
        await loadAllConnections(organizationId);
        
        // Trả về URL từ API response
        return response['content']['url'];
      }
      
      return null;
    } catch (e) {
      print('Error creating webhook: $e');
      return null;
    }
  }
} 