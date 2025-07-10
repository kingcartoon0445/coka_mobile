import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/utils/helpers.dart';
import 'enhanced_avatar_widget.dart';
import 'package:flutter/gestures.dart';

class MessageBubbleWidget extends StatelessWidget {
  final String message;
  final String senderName;
  final String? senderAvatar;
  final bool isFromCurrentUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? attachments;
  final bool showAvatar;
  final String? profileId;
  final VoidCallback? onPhoneNumberTap;
  final VoidCallback? onAvatarTap;
  
  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.senderName,
    this.senderAvatar,
    required this.isFromCurrentUser,
    required this.timestamp,
    this.attachments,
    this.showAvatar = true,
    this.profileId,
    this.onPhoneNumberTap,
    this.onAvatarTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 2,
        horizontal: 16,
      ),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && showAvatar) _buildAvatar(context),
          if (!isFromCurrentUser) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 280),
              child: Column(
                crossAxisAlignment: isFromCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
                children: [
                  if (showAvatar && !isFromCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  _buildMessageBubble(context),
                ],
              ),
            ),
          ),
          
          if (isFromCurrentUser) const SizedBox(width: 8),
          if (isFromCurrentUser && showAvatar) _buildAvatar(context),
        ],
      ),
    );
  }
  
  Widget _buildAvatar(BuildContext context) {
    return CustomAvatar(
      imageUrl: senderAvatar,
      displayName: senderName,
      size: 32,
      onTap: () => _showUserProfile(context),
    );
  }
  
  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isFromCurrentUser 
          ? Theme.of(context).primaryColor 
          : Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attachments
          if (attachments?.isNotEmpty == true)
            ...attachments!.map((attachment) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildAttachment(context, attachment),
              ),
            ),
          
          // Message text
          if (message.isNotEmpty)
            _buildMessageText(context, message),
        ],
      ),
    );
  }
  
  Widget _buildAttachment(BuildContext context, Map<String, dynamic> attachment) {
    final type = attachment['type'] ?? '';
    final url = attachment['url'] ?? attachment['payload']?['url'] ?? '';
    final name = attachment['name'] ?? attachment['payload']?['name'];
    
    if (type == 'image' || AvatarUtils.isImageUrl(url)) {
      return _buildImageAttachment(context, url);
    }
    
    return _buildFileAttachment(context, url, name);
  }
  
  Widget _buildImageAttachment(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, imageUrl),
      child: Hero(
        tag: imageUrl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 200),
          child: ClipRoundedRectangle(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFileAttachment(BuildContext context, String fileUrl, String? fileName) {
    return GestureDetector(
      onTap: () => _openFile(fileUrl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFromCurrentUser 
            ? Colors.white.withOpacity(0.1)
            : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFromCurrentUser 
              ? Colors.white.withOpacity(0.3)
              : Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file, 
              size: 20, 
              color: isFromCurrentUser ? Colors.white : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName ?? _getFileNameFromUrl(fileUrl),
                style: TextStyle(
                  fontSize: 14,
                  color: isFromCurrentUser ? Colors.white : Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageText(BuildContext context, String text) {
    final phoneRegex = RegExp(r'(\+84|0)(\s?\d\s?){9,10}');
    final matches = phoneRegex.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isFromCurrentUser ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      );
    }
    
    // Build rich text with clickable phone numbers
    List<TextSpan> spans = [];
    int lastIndex = 0;
    
    for (final match in matches) {
      // Add text before phone number
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: isFromCurrentUser ? Colors.white : Colors.black87,
          ),
        ));
      }
      
      // Add clickable phone number
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: isFromCurrentUser 
            ? Colors.white 
            : Theme.of(context).primaryColor,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _handlePhoneNumberTap(context, match.group(0) ?? ''),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: isFromCurrentUser ? Colors.white : Colors.black87,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
  
  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
        ),
      ),
    );
  }
  
  void _openFile(String fileUrl) async {
    final uri = Uri.parse(fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return 'File đính kèm';
    } catch (e) {
      return 'File đính kèm';
    }
  }
  
  void _handlePhoneNumberTap(BuildContext context, String phoneNumber) {
    if (onPhoneNumberTap != null) {
      onPhoneNumberTap!();
    } else {
      // Default action - show options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Số điện thoại'),
          content: Text(phoneNumber),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _makePhoneCall(phoneNumber);
              },
              child: const Text('Gọi'),
            ),
          ],
        ),
      );
    }
  }
  
  void _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  void _showUserProfile(BuildContext context) {
    if (profileId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(
        displayName: senderName,
        avatar: senderAvatar,
        profileId: profileId!,
      ),
    );
  }
}

/// Custom ClipRoundedRectangle widget
class ClipRoundedRectangle extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  
  const ClipRoundedRectangle({
    super.key,
    required this.child,
    required this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
} 