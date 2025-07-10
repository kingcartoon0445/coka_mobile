import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'enhanced_avatar_widget.dart';

class UserProfileDialog extends StatelessWidget {
  final String displayName;
  final String? avatar;
  final String profileId;
  final Map<String, dynamic>? additionalInfo;

  const UserProfileDialog({
    super.key,
    required this.displayName,
    this.avatar,
    required this.profileId,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với avatar và tên
            _buildHeader(),
            
            const SizedBox(height: 20),
            
            // Thông tin bổ sung
            if (additionalInfo != null) ...[
              _buildAdditionalInfo(),
              const SizedBox(height: 20),
            ],
            
            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Avatar lớn
        CustomAvatar(
          imageUrl: avatar,
          displayName: displayName,
          size: 80,
          showBorder: true,
          borderColor: const Color(0xFF554FE8),
          borderWidth: 3,
        ),
        
        const SizedBox(height: 16),
        
        // Tên người dùng
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 4),
        
        // Profile ID
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'ID: ${profileId.length > 10 ? "${profileId.substring(0, 10)}..." : profileId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _copyToClipboard(profileId),
                child: Icon(
                  Icons.copy,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    if (additionalInfo == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Hiển thị các thông tin bổ sung
          ...additionalInfo!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getIconForKey(entry.key),
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayNameForKey(entry.key),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Đóng
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Đóng'),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Xem chi tiết
        Expanded(
          child: ElevatedButton(
            onPressed: () => _viewDetailProfile(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF554FE8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Xem chi tiết'),
          ),
        ),
      ],
    );
  }

  IconData _getIconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'phone':
      case 'phoneNumber':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'location':
      case 'address':
        return Icons.location_on;
      case 'birthday':
      case 'dob':
        return Icons.cake;
      case 'gender':
        return Icons.person;
      case 'facebook':
        return Icons.facebook;
      case 'company':
      case 'work':
        return Icons.business;
      default:
        return Icons.info_outline;
    }
  }

  String _getDisplayNameForKey(String key) {
    switch (key.toLowerCase()) {
      case 'phone':
      case 'phoneNumber':
        return 'Số điện thoại';
      case 'email':
        return 'Email';
      case 'location':
      case 'address':
        return 'Địa chỉ';
      case 'birthday':
      case 'dob':
        return 'Ngày sinh';
      case 'gender':
        return 'Giới tính';
      case 'facebook':
        return 'Facebook';
      case 'company':
      case 'work':
        return 'Công ty';
      default:
        return key;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _viewDetailProfile(BuildContext context) {
    Navigator.of(context).pop();
    // TODO: Navigate to customer detail page
    // Example: context.push('/customer/$profileId');
  }
}

// Extension widget để dễ sử dụng
extension UserProfileDialogExtension on BuildContext {
  void showUserProfile({
    required String displayName,
    String? avatar,
    required String profileId,
    Map<String, dynamic>? additionalInfo,
  }) {
    showDialog(
      context: this,
      builder: (context) => UserProfileDialog(
        displayName: displayName,
        avatar: avatar,
        profileId: profileId,
        additionalInfo: additionalInfo,
      ),
    );
  }
} 