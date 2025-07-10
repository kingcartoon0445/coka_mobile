import 'package:flutter/material.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/providers/app_providers.dart';
import 'package:coka/shared/widgets/custom_switch.dart';
import 'package:coka/models/lead/connection_model.dart';
import 'package:coka/pages/organization/campaigns/multi_source_connection/components/edit_webform_page.dart';
import 'package:coka/pages/organization/campaigns/multi_source_connection/components/edit_tiktok_page.dart';
import 'package:coka/pages/organization/campaigns/multi_source_connection/components/edit_webhook_page.dart';
import 'package:coka/pages/organization/campaigns/multi_source_connection/components/add_connection_page.dart';
import 'package:coka/api/providers.dart';
class MultiSourceConnectionPage extends ConsumerStatefulWidget {
  final String organizationId;
  
  const MultiSourceConnectionPage({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<MultiSourceConnectionPage> createState() => _MultiSourceConnectionPageState();
}

class _MultiSourceConnectionPageState extends ConsumerState<MultiSourceConnectionPage> {
  bool isLoading = true;
  // Map để theo dõi trạng thái animation của từng kết nối
  final Map<String, bool> _itemVisibility = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final provider = ref.read(multiSourceConnectionProvider);
      await provider.loadAllConnections(widget.organizationId);
      
      // Nếu có các webhook trong danh sách, thực hiện xử lý đặc biệt cho chúng
      // để đảm bảo dữ liệu đầy đủ từ API response
      final leadRepository = ref.read(leadRepositoryProvider);
      final webhooksResponse = await leadRepository.webhookGetList(widget.organizationId);
      
      if (webhooksResponse['code'] == 0 && webhooksResponse['content'] != null) {
        print("Đã nhận được danh sách webhook từ API");
        final List<dynamic> webhooksFromApi = webhooksResponse['content'];
        
        // Debug thông tin webhook từ API
        for (var webhook in webhooksFromApi) {
          print("Webhook từ API: ID=${webhook['id']}, Source=${webhook['source']}, URL=${webhook['url']}");
        }
        
        // Tạo webhook model mới từ dữ liệu API
        List<ConnectionModel> correctWebhooks = [];
        for (var apiWebhook in webhooksFromApi) {
          // Tạo additionalData từ API response
          final Map<String, dynamic> additionalData = {
            'source': apiWebhook['source'],
            'expiryDate': apiWebhook['expiryDate'],
            'url': apiWebhook['url'], // Đảm bảo URL được lưu trong additionalData
          };
          
          // Tạo ConnectionModel mới
          final webhook = ConnectionModel(
            id: apiWebhook['id'] ?? '',
            title: apiWebhook['title'] ?? 'Webhook',
            connectionType: 'webhook',
            status: apiWebhook['status'] ?? 0,
            connectionState: 'Đã kết nối',
            organizationId: apiWebhook['organizationId'] ?? '',
            workspaceId: apiWebhook['workspaceId'] ?? '',
            workspaceName: apiWebhook['workspaceName'] ?? 'Không có workspace',
            provider: apiWebhook['source'] ?? 'FBS',
            url: apiWebhook['url'],
            additionalData: additionalData,
          );
          
          correctWebhooks.add(webhook);
        }
        
        // Thay thế các webhook trong provider
        final allConnections = List<ConnectionModel>.from(provider.connections);
        bool hasChanges = false;
        
        // Xóa các webhook hiện tại
        allConnections.removeWhere((conn) => conn.connectionType == 'webhook');
        // Thêm các webhook mới đã được xử lý đúng
        allConnections.addAll(correctWebhooks);
        
        // Cập nhật lại danh sách connections trong provider
        provider.updateConnections(allConnections);
        print("Đã cập nhật ${correctWebhooks.length} webhook với dữ liệu đầy đủ");
      }
      
      // Cập nhật _itemVisibility cho các kết nối hiện tại
      _updateItemVisibility(provider.connections);
      
    } catch (e) {
      print('Lỗi khi tải dữ liệu kết nối: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  // Cập nhật trạng thái hiển thị của từng kết nối
  void _updateItemVisibility(List<ConnectionModel> connections) {
    setState(() {
      _itemVisibility.clear();
      for (var conn in connections) {
        // Sử dụng ID và connectionType làm key để theo dõi trạng thái
        _itemVisibility['${conn.id}_${conn.connectionType}'] = true;
      }
    });
  }

  void _showAddConnectionDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddConnectionPage(
          organizationId: widget.organizationId,
        ),
      ),
    ).then((result) {
      // Nếu có kết quả trả về và cần reload data
      if (result == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(multiSourceConnectionProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Colors.black12),
            
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : provider.groupedConnections.isEmpty
                  ? _buildEmptyState()
                  : _buildConnectionsList(provider.groupedConnections),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Kênh kết nối',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 24),
            onPressed: _showAddConnectionDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có kết nối nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Nhấn nút + ở góc trên phải để thêm kết nối mới',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsList(Map<String, List<ConnectionModel>> groupedConnections) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedConnections.length,
      itemBuilder: (context, index) {
        final workspace = groupedConnections.keys.elementAt(index);
        final connections = groupedConnections[workspace] ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workspace header
            Row(
              children: [
                Icon(Icons.groups, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  workspace,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Connection items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: connections.length,
              itemBuilder: (context, i) {
                final connection = connections[i];
                final itemKey = '${connection.id}_${connection.connectionType}';
                final isVisible = _itemVisibility[itemKey] ?? true;
                
                // Sử dụng AnimatedOpacity và AnimatedContainer để hiệu ứng biến mất
                return AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isVisible ? null : 0,
                    margin: EdgeInsets.only(bottom: isVisible ? 12 : 0),
                    child: isVisible ? _buildConnectionItem(connection) : const SizedBox(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildConnectionItem(ConnectionModel connection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _handleConnectionTap(connection),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with icon, title and switch
            Row(
              children: [
                _buildConnectionIcon(connection.connectionType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getConnectionTypeTitle(connection.connectionType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        connection.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setLocalState) {
                    return CustomSwitch(
                      value: connection.status == 1,
                      onChanged: (value) {
                        // Cập nhật UI ngay lập tức
                        setLocalState(() {});
                        // Sau đó xử lý logic
                        _handleStatusChange(connection, value);
                      },
                    );
                  },
                ),
              ],
            ),
            
            // Status badge and actions
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (connection.connectionState != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStateColor(connection.connectionState!),
                      ),
                    ),
                    child: Text(
                      connection.connectionState!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStateColor(connection.connectionState!),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                
                // Unlink button
                GestureDetector(
                  onTap: () => _confirmUnlink(connection),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off, size: 16, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Gỡ kết nối',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIcon(String type) {
    switch (type) {
      case 'facebook':
        return SvgPicture.asset('assets/icons/fb_ico.svg', width: 24, height: 24);
      case 'zalo':
        return SvgPicture.asset('assets/icons/zalo.svg', width: 24, height: 24);
      case 'tiktok':
        return SvgPicture.asset('assets/icons/tiktok.svg', width: 24, height: 24);
      case 'webhook':
        return SvgPicture.asset('assets/icons/webhook.svg', width: 24, height: 24);
      case 'webform':
        return const Icon(Icons.language, color: AppColors.primary, size: 24);
      default:
        return const Icon(Icons.link, color: Colors.grey, size: 24);
    }
  }

  String _getConnectionTypeTitle(String type) {
    switch (type) {
      case 'facebook':
        return 'Facebook Form';
      case 'zalo':
        return 'Zalo Form';
      case 'tiktok':
        return 'Tiktok Form';
      case 'webhook':
        return 'Webhook';
      case 'webform':
        return 'Web Form';
      default:
        return 'Kết nối';
    }
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'Chưa xác minh':
        return Colors.grey;
      case 'Mất kết nối':
        return Colors.red;
      case 'Đang kết nối':
        return Colors.green;
      case 'Đã kết nối':
        return AppColors.primary;
      case 'Gỡ kết nối':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _handleConnectionTap(ConnectionModel connection) {
    switch (connection.connectionType) {
      case 'webform':
        _navigateToEditWebform(connection);
        break;
      case 'tiktok':
        _navigateToEditTiktok(connection);
        break;
      case 'webhook':
        _navigateToEditWebhook(connection);
        break;
      case 'facebook':
      case 'zalo':
        _showNotImplementedDialog(connection.connectionType);
        break;
      default:
        _showNotImplementedDialog('kết nối');
    }
  }

  void _navigateToEditWebform(ConnectionModel webform) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditWebformPage(data: webform),
      ),
    );
    
    // Nếu result là true, tức là có thay đổi, cần reload data
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToEditTiktok(ConnectionModel tiktok) async {
    // Đảm bảo tiktok model có organizationId
    if (tiktok.organizationId.isEmpty) {
      print("TikTok model thiếu organizationId, sử dụng từ tham số của trang");
      // Tạo một bản sao với organizationId từ tham số của trang
      tiktok = ConnectionModel(
        id: tiktok.id,
        title: tiktok.title,
        connectionType: tiktok.connectionType,
        status: tiktok.status,
        connectionState: tiktok.connectionState,
        organizationId: widget.organizationId, // Sử dụng từ tham số của trang
        workspaceId: tiktok.workspaceId,
        workspaceName: tiktok.workspaceName,
        provider: tiktok.provider,
        url: tiktok.url,
        additionalData: tiktok.additionalData,
      );
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTiktokPage(data: tiktok),
      ),
    );
    
    // Nếu result là true, tức là có thay đổi, cần reload data
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToEditWebhook(ConnectionModel webhook) async {
    print("Mở trang chỉnh sửa webhook: ${webhook.id}");
    print("Provider: ${webhook.provider}, URL: ${webhook.url}");
    if (webhook.additionalData != null) {
      print("additionalData: ${webhook.additionalData}");
    }
    
    // Đảm bảo webhook có đủ thông tin cần thiết trước khi mở trang edit
    ConnectionModel webhookData = webhook;
    
    // Kiểm tra xem webhook có đầy đủ thông tin cần thiết không
    bool needsEnrichment = webhook.additionalData == null || 
                           !webhook.additionalData!.containsKey('source') ||
                           !webhook.additionalData!.containsKey('expiryDate');
    
    // Bổ sung dữ liệu cần thiết nếu thiếu
    if (needsEnrichment) {
      print("Bổ sung dữ liệu cho webhook: ${webhook.id}");
      
      // Chuẩn bị additionalData mới
      Map<String, dynamic> enrichedData = webhook.additionalData ?? {};
      
      // Thêm source nếu chưa có
      if (!enrichedData.containsKey('source') || enrichedData['source'] == null) {
        enrichedData['source'] = webhook.provider ?? 'FBS';
      }
      
      // Thêm ngày hết hạn nếu chưa có
      if (!enrichedData.containsKey('expiryDate') || enrichedData['expiryDate'] == null) {
        // Mặc định hạn 30 ngày
        enrichedData['expiryDate'] = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      }
      
      // Tạo ConnectionModel mới với dữ liệu đã bổ sung
      webhookData = ConnectionModel(
        id: webhook.id,
        title: webhook.title,
        connectionType: webhook.connectionType,
        status: webhook.status,
        connectionState: webhook.connectionState ?? 'Đã kết nối',
        organizationId: webhook.organizationId.isEmpty ? widget.organizationId : webhook.organizationId,
        workspaceId: webhook.workspaceId,
        workspaceName: webhook.workspaceName,
        provider: webhook.provider,
        url: webhook.url,
        additionalData: enrichedData,
      );
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditWebhookPage(data: webhookData),
      ),
    );
    
    // Nếu result là true, tức là có thay đổi, cần reload data
    if (result == true) {
      _loadData();
    }
  }

  void _showNotImplementedDialog(String connectionType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng chỉnh sửa $connectionType đang được phát triển'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _handleStatusChange(ConnectionModel connection, bool value) {
    final provider = ref.read(multiSourceConnectionProvider);
    final int newStatus = value ? 1 : 0;
    
    // Tạo bản sao của kết nối với trạng thái mới
    final updatedConnection = ConnectionModel(
      id: connection.id,
      title: connection.title,
      connectionType: connection.connectionType,
      status: newStatus, // Cập nhật trạng thái mới
      connectionState: connection.connectionState,
      organizationId: connection.organizationId,
      workspaceId: connection.workspaceId,
      workspaceName: connection.workspaceName,
      provider: connection.provider,
      url: connection.url,
      additionalData: connection.additionalData,
    );
    
    // Cập nhật danh sách kết nối trong provider
    final allConnections = List<ConnectionModel>.from(provider.connections);
    
    // Tìm và thay thế kết nối cần cập nhật
    for (int i = 0; i < allConnections.length; i++) {
      if (allConnections[i].id == connection.id && 
          allConnections[i].connectionType == connection.connectionType) {
        allConnections[i] = updatedConnection;
        break;
      }
    }
    
    // Cập nhật danh sách trong provider
    provider.updateConnections(allConnections);
    
    // Gọi API để cập nhật trạng thái trên server
    provider.updateConnectionStatus(
      widget.organizationId, 
      connection, 
      newStatus,
    );
    
    // Đảm bảo UI được cập nhật
    setState(() {});
  }

  void _confirmUnlink(ConnectionModel connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bạn muốn xóa ${connection.title}?'),
        content: const Text('Bạn sẽ không thể hoàn lại thao tác này'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Thêm animation biến mất trước khi xóa khỏi danh sách
              final itemKey = '${connection.id}_${connection.connectionType}';
              
              // Đặt trạng thái hiển thị thành false để kích hoạt animation
              setState(() {
                _itemVisibility[itemKey] = false;
              });
              
              // Đợi animation hoàn thành trước khi thực sự xóa khỏi danh sách
              Future.delayed(const Duration(milliseconds: 300), () {
                final provider = ref.read(multiSourceConnectionProvider);
                
                // Tạo một bản sao của danh sách kết nối
                final allConnections = List<ConnectionModel>.from(provider.connections);
                
                // Xóa connection khỏi danh sách
                allConnections.removeWhere((conn) => conn.id == connection.id && conn.connectionType == connection.connectionType);
                
                // Cập nhật lại provider với danh sách đã xóa item
                provider.updateConnections(allConnections);
                
                // Sau đó mới gọi API xóa nhưng không reload trang
                provider.deleteConnection(
                  widget.organizationId, 
                  connection,
                );
              });
            },
            child: const Text(
              'Đồng ý',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 