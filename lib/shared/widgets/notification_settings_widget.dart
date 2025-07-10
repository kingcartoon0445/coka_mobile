import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/fcm_provider.dart';

class NotificationSettingsWidget extends ConsumerStatefulWidget {
  final String? organizationId;
  final String? workspaceId;

  const NotificationSettingsWidget({
    super.key,
    this.organizationId,
    this.workspaceId,
  });

  @override
  ConsumerState<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends ConsumerState<NotificationSettingsWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final fcmToken = ref.watch(fcmTokenProvider);
    final subscribedTopics = ref.watch(fcmTopicsProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt thông báo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            
            // FCM Token Status
            _buildTokenStatus(fcmToken),
            const SizedBox(height: 16),
            
            // Organization Notifications
            if (widget.organizationId != null)
              _buildOrganizationNotificationToggle(subscribedTopics),
            
            // Workspace Notifications
            if (widget.workspaceId != null) ...[
              const SizedBox(height: 8),
              _buildWorkspaceNotificationToggle(subscribedTopics),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenStatus(AsyncValue<String?> fcmToken) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fcmToken.when(
          data: (token) => token != null ? Colors.green.shade50 : Colors.red.shade50,
          loading: () => Colors.grey.shade50,
          error: (_, __) => Colors.red.shade50,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fcmToken.when(
            data: (token) => token != null ? Colors.green : Colors.red,
            loading: () => Colors.grey,
            error: (_, __) => Colors.red,
          ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            fcmToken.when(
              data: (token) => token != null ? Icons.check_circle : Icons.error,
              loading: () => Icons.hourglass_empty,
              error: (_, __) => Icons.error,
            ),
            color: fcmToken.when(
              data: (token) => token != null ? Colors.green : Colors.red,
              loading: () => Colors.grey,
              error: (_, __) => Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fcmToken.when(
                    data: (token) => token != null 
                        ? 'Thông báo đã được kích hoạt' 
                        : 'Thông báo chưa được kích hoạt',
                    loading: () => 'Đang kiểm tra...',
                    error: (_, __) => 'Lỗi kiểm tra thông báo',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (fcmToken.hasValue && fcmToken.value != null)
                  Text(
                    'Token: ${fcmToken.value!.substring(0, 20)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationNotificationToggle(Set<String> subscribedTopics) {
    final topicName = 'org_${widget.organizationId}';
    final isSubscribed = subscribedTopics.contains(topicName);

    return _buildNotificationToggle(
      title: 'Thông báo tổ chức',
      subtitle: 'Nhận thông báo từ tổ chức này',
      value: isSubscribed,
      onChanged: (value) => _toggleOrganizationNotification(value),
    );
  }

  Widget _buildWorkspaceNotificationToggle(Set<String> subscribedTopics) {
    final topicName = 'workspace_${widget.workspaceId}';
    final isSubscribed = subscribedTopics.contains(topicName);

    return _buildNotificationToggle(
      title: 'Thông báo workspace',
      subtitle: 'Nhận thông báo từ workspace này',
      value: isSubscribed,
      onChanged: (value) => _toggleWorkspaceNotification(value),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      value: value,
      onChanged: _isLoading ? null : onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _refreshToken,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16, 
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Làm mới token'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _testNotification,
            icon: const Icon(Icons.notification_add),
            label: const Text('Test thông báo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleOrganizationNotification(bool enabled) async {
    if (widget.organizationId == null) return;

    setState(() => _isLoading = true);
    
    try {
      if (enabled) {
        await FCMProviderHelpers.subscribeToOrganizationTopic(ref, widget.organizationId!);
      } else {
        await FCMProviderHelpers.unsubscribeFromOrganizationTopic(ref, widget.organizationId!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled 
                ? 'Đã bật thông báo tổ chức' 
                : 'Đã tắt thông báo tổ chức'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWorkspaceNotification(bool enabled) async {
    if (widget.workspaceId == null) return;

    setState(() => _isLoading = true);
    
    try {
      if (enabled) {
        await FCMProviderHelpers.subscribeToWorkspaceTopic(ref, widget.workspaceId!);
      } else {
        await FCMProviderHelpers.unsubscribeFromWorkspaceTopic(ref, widget.workspaceId!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled 
                ? 'Đã bật thông báo workspace' 
                : 'Đã tắt thông báo workspace'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isLoading = true);
    
    try {
      ref.invalidate(fcmTokenProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã làm mới token thông báo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi làm mới token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    setState(() => _isLoading = true);
    
    try {
      // Hiển thị thông báo test
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Để test thông báo, sử dụng Firebase Console hoặc gửi từ server'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
} 