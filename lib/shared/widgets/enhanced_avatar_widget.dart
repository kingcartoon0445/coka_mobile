import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/helpers.dart';

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;
  final bool useMemoryCache;
  
  const CustomAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.size = 44.0,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.onTap,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.useMemoryCache = true,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget avatarContent;
    
    if (useMemoryCache) {
      final cacheKey = '${imageUrl ?? 'text'}_${displayName}_$size';
      avatarContent = AvatarMemoryManager.getOrCreateAvatar(
        cacheKey: cacheKey,
        displayName: displayName,
        imageUrl: imageUrl,
        size: size,
      );
    } else {
      avatarContent = _buildAvatarContent();
    }
    
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder 
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      ),
      child: ClipOval(child: avatarContent),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    
    return avatar;
  }
  
  Widget _buildAvatarContent() {
    final initials = AvatarUtils.getInitials(displayName);
    final avatarColor = backgroundColor ?? AvatarUtils.getAvatarColor(displayName);
    final finalTextColor = textColor ?? Colors.white;
    final finalFontSize = fontSize ?? (size * 0.4);
    
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _buildImageAvatar(initials, avatarColor, finalTextColor, finalFontSize);
    } else {
      return _buildTextAvatar(initials, avatarColor, finalTextColor, finalFontSize);
    }
  }
  
  Widget _buildImageAvatar(String initials, Color bgColor, Color textColor, double fontSize) {
    return CachedNetworkImage(
      imageUrl: AvatarUtils.getAvatarUrl(imageUrl) ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildTextAvatar(initials, bgColor, textColor, fontSize),
      errorWidget: (context, url, error) => _buildTextAvatar(initials, bgColor, textColor, fontSize),
    );
  }
  
  Widget _buildTextAvatar(String initials, Color bgColor, Color textColor, double fontSize) {
    return Container(
      width: size,
      height: size,
      color: bgColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// User Profile Dialog với avatar
class UserProfileDialog extends StatelessWidget {
  final String displayName;
  final String? avatar;
  final String profileId;
  
  const UserProfileDialog({
    super.key,
    required this.displayName,
    this.avatar,
    required this.profileId,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomAvatar(
              imageUrl: avatar,
              displayName: displayName,
              size: 80,
              fontSize: 32,
              useMemoryCache: false, // Don't cache large avatars
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $profileId',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _viewFullProfile(context),
                  icon: const Icon(Icons.person),
                  label: const Text('Xem hồ sơ'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Đóng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _viewFullProfile(BuildContext context) {
    Navigator.pop(context);
    // TODO: Navigate to full profile page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng xem hồ sơ sẽ được phát triển')),
    );
  }
} 