import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/shared/widgets/custom_alert_dialog.dart';
import 'package:coka/shared/widgets/workspace_list_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/pages/organization/campaigns/multi_source_connection/components/webform_config_page.dart';
import 'package:coka/pages/organization/campaigns/multi_source_connection/components/webhook_config_page.dart';
import 'package:coka/pages/organization/campaigns/multi_source_connection/components/tiktok_config_page.dart';

// Trang chính để chọn kênh kết nối
class AddConnectionPage extends ConsumerStatefulWidget {
  final String organizationId;
  
  const AddConnectionPage({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<AddConnectionPage> createState() => _AddConnectionPageState();
}

class _AddConnectionPageState extends ConsumerState<AddConnectionPage> {
  String? selectedWorkspaceId;
  String? selectedWorkspaceName;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Liên kết trang mới',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Colors.black12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phần chọn workspace
                  Row(
                    children: [
                      const Text(
                        'Không gian làm việc',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _selectWorkspace,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedWorkspaceName ?? 'Chọn không gian làm việc',
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedWorkspaceName != null 
                                ? Colors.black 
                                : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Chọn kênh kết nối',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Danh sách loại kết nối
                  Expanded(
                    child: ListView.separated(
                      itemCount: _connectionItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _connectionItems[index];
                        
                        return InkWell(
                          onTap: () {
                            if (selectedWorkspaceId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chọn không gian làm việc trước'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            _handleConnectionItemTap(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                item.icon,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectWorkspace() {
    WorkspaceListModal.show(
      context: context,
      organizationId: widget.organizationId,
      showAvatar: true,
      showMemberCount: true,
      onWorkspaceSelected: (workspace) {
        setState(() {
          selectedWorkspaceId = workspace['id'];
          selectedWorkspaceName = workspace['name'];
        });
      },
    );
  }

  void _handleConnectionItemTap(int index) async {
    switch (index) {
      case 0: // Web Form
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebFormConfigPage(
              organizationId: widget.organizationId,
              workspaceId: selectedWorkspaceId!,
              workspaceName: selectedWorkspaceName!,
            ),
          ),
        );
        if (result == true) {
          Navigator.pop(context, true); // Trả về true để reload danh sách kết nối
        }
        break;
        
      case 1: // Facebook Form
        _showFeatureNotAvailableDialog(connectionType: 'Facebook Form');
        break;
        
      case 2: // Zalo Form
        _showFeatureNotAvailableDialog(connectionType: 'Zalo Form');
        break;
        
      case 3: // Tiktok Form
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TiktokConfigPage(
              organizationId: widget.organizationId,
              workspaceId: selectedWorkspaceId!,
              workspaceName: selectedWorkspaceName!,
            ),
          ),
        );
        if (result == true) {
          Navigator.pop(context, true); // Trả về true để reload danh sách kết nối
        }
        break;
        
      case 4: // Webhook
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebhookConfigPage(
              organizationId: widget.organizationId,
              workspaceId: selectedWorkspaceId!,
              workspaceName: selectedWorkspaceName!,
            ),
          ),
        );
        if (result == true) {
          Navigator.pop(context, true); // Trả về true để reload danh sách kết nối
        }
        break;
    }
  }

  void _showFeatureNotAvailableDialog({required String connectionType}) {
    showCustomAlert(
      context: context,
      title: 'Tính năng đang phát triển',
      message: 'Kết nối $connectionType hiện chỉ có sẵn trên phiên bản PC. '
               'Phiên bản mobile đang được phát triển.',
      confirmText: 'Đã hiểu',
      isWarning: true,
    );
  }
  
  void _showNotAvailableYetDialog({
    required String iconPath,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 48,
                height: 48,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Định nghĩa kênh kết nối
class ConnectionItemData {
  final Widget icon;
  final String label;
  
  ConnectionItemData({required this.icon, required this.label});
}

// Danh sách các kênh kết nối
final List<ConnectionItemData> _connectionItems = [
  ConnectionItemData(
    icon: const Icon(Icons.language, color: AppColors.primary, size: 24),
    label: 'Liên kết qua Web Form',
  ),
  ConnectionItemData(
    icon: SvgPicture.asset('assets/icons/fb_ico.svg', width: 24, height: 24),
    label: 'Liên kết qua Facebook Form',
  ),
  ConnectionItemData(
    icon: SvgPicture.asset('assets/icons/zalo.svg', width: 24, height: 24),
    label: 'Liên kết qua Zalo Form',
  ),
  ConnectionItemData(
    icon: SvgPicture.asset('assets/icons/tiktok.svg', width: 24, height: 24),
    label: 'Liên kết qua Tiktok Form',
  ),
  ConnectionItemData(
    icon: SvgPicture.asset('assets/icons/webhook.svg', width: 24, height: 24),
    label: 'Webhook',
  ),
]; 