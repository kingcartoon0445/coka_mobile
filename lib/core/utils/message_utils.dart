import 'package:flutter/material.dart';

enum MessagePosition {
  single,        // Tin nhắn đơn lẻ
  firstInTurn,   // Tin nhắn đầu tiên trong lượt
  middleInTurn,  // Tin nhắn ở giữa lượt
  lastInTurn,    // Tin nhắn cuối cùng trong lượt
}

class MessageUtils {
  /// Xác định vị trí của tin nhắn trong chuỗi conversation
  static MessagePosition getMessagePosition(
    List<dynamic> messages,
    int currentIndex,
    String currentSenderId,
  ) {
    if (messages.isEmpty) return MessagePosition.single;
    
    final currentMessage = messages[currentIndex];
    final previousMessage = currentIndex > 0 ? messages[currentIndex - 1] : null;
    final nextMessage = currentIndex < messages.length - 1 ? messages[currentIndex + 1] : null;
    
    final currentSender = _getSenderId(currentMessage);
    final previousSender = previousMessage != null ? _getSenderId(previousMessage) : null;
    final nextSender = nextMessage != null ? _getSenderId(nextMessage) : null;
    
    final isFirstInTurn = previousSender != currentSender;
    final isLastInTurn = nextSender != currentSender;
    
    if (isFirstInTurn && isLastInTurn) {
      return MessagePosition.single;
    } else if (isFirstInTurn) {
      return MessagePosition.firstInTurn;
    } else if (isLastInTurn) {
      return MessagePosition.lastInTurn;
    } else {
      return MessagePosition.middleInTurn;
    }
  }

  /// Tạo border radius cho message bubble dựa trên vị trí
  static BorderRadius getMessageBorderRadius(
    MessagePosition position,
    bool isFromCurrentUser,
  ) {
    const double radius = 18.0;
    const double smallRadius = 4.0;
    
    if (isFromCurrentUser) {
      // Message từ current user (bên phải)
      switch (position) {
        case MessagePosition.single:
          return BorderRadius.circular(radius);
        case MessagePosition.firstInTurn:
          return const BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
            bottomRight: Radius.circular(smallRadius),
          );
        case MessagePosition.middleInTurn:
          return const BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(smallRadius),
            bottomLeft: Radius.circular(radius),
            bottomRight: Radius.circular(smallRadius),
          );
        case MessagePosition.lastInTurn:
          return const BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(smallRadius),
            bottomLeft: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          );
      }
    } else {
      // Message từ người khác (bên trái)
      switch (position) {
        case MessagePosition.single:
          return BorderRadius.circular(radius);
        case MessagePosition.firstInTurn:
          return const BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(smallRadius),
            bottomRight: Radius.circular(radius),
          );
        case MessagePosition.middleInTurn:
          return const BorderRadius.only(
            topLeft: Radius.circular(smallRadius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(smallRadius),
            bottomRight: Radius.circular(radius),
          );
        case MessagePosition.lastInTurn:
          return const BorderRadius.only(
            topLeft: Radius.circular(smallRadius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          );
      }
    }
  }

  /// Kiểm tra xem có nên hiển thị avatar không
  static bool shouldShowAvatar(MessagePosition position) {
    return position == MessagePosition.single || 
           position == MessagePosition.lastInTurn;
  }

  /// Kiểm tra xem có nên hiển thị tên người gửi không
  static bool shouldShowSenderName(MessagePosition position) {
    return position == MessagePosition.single || 
           position == MessagePosition.firstInTurn;
  }

  /// Kiểm tra xem có nên hiển thị timestamp không
  static bool shouldShowTimestamp(MessagePosition position) {
    return position == MessagePosition.single || 
           position == MessagePosition.lastInTurn;
  }

  /// Tính margin giữa các message
  static EdgeInsets getMessageMargin(MessagePosition position) {
    switch (position) {
      case MessagePosition.single:
        return const EdgeInsets.symmetric(vertical: 4);
      case MessagePosition.firstInTurn:
        return const EdgeInsets.only(top: 8, bottom: 1);
      case MessagePosition.middleInTurn:
        return const EdgeInsets.symmetric(vertical: 1);
      case MessagePosition.lastInTurn:
        return const EdgeInsets.only(top: 1, bottom: 4);
    }
  }

  /// Format thời gian tin nhắn
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Tạo date separator cho message list
  static Widget? buildDateSeparator(
    List<dynamic> messages,
    int currentIndex,
    DateTime currentTimestamp,
  ) {
    if (currentIndex == messages.length - 1) {
      // First message, always show date
      return _buildDateSeparatorWidget(currentTimestamp);
    }

    final nextMessage = messages[currentIndex + 1];
    final nextTimestamp = _getTimestamp(nextMessage);

    if (!_isSameDay(currentTimestamp, nextTimestamp)) {
      return _buildDateSeparatorWidget(currentTimestamp);
    }

    return null;
  }

  static Widget _buildDateSeparatorWidget(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDateSeparator(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  static String _formatDateSeparator(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (_isSameDay(timestamp, now)) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return weekdays[timestamp.weekday % 7];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static String _getSenderId(dynamic message) {
    // Adapt this based on your message structure
    return message.from ?? message.senderId ?? '';
  }

  static DateTime _getTimestamp(dynamic message) {
    // Adapt this based on your message structure
    if (message.timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(message.timestamp * 1000);
    }
    return message.timestamp ?? DateTime.now();
  }

  /// Tạo message action bottom sheet
  static void showMessageActions(
    BuildContext context,
    dynamic message,
    {
      VoidCallback? onReply,
      VoidCallback? onForward,
      VoidCallback? onCopy,
      VoidCallback? onDelete,
    }
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Trả lời'),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
            if (onForward != null)
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Chuyển tiếp'),
                onTap: () {
                  Navigator.pop(context);
                  onForward();
                },
              ),
            if (onCopy != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Sao chép'),
                onTap: () {
                  Navigator.pop(context);
                  onCopy();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Tính khoảng cách giữa các message groups
  static double getGroupSpacing(
    List<dynamic> messages,
    int currentIndex,
  ) {
    if (currentIndex == 0) return 0;

    final currentMessage = messages[currentIndex];
    final previousMessage = messages[currentIndex - 1];

    final currentTimestamp = _getTimestamp(currentMessage);
    final previousTimestamp = _getTimestamp(previousMessage);

    final difference = currentTimestamp.difference(previousTimestamp);

    // Nếu cách nhau hơn 5 phút, tăng khoảng cách
    if (difference.inMinutes > 5) {
      return 16;
    }

    return 4;
  }

  /// Tạo loading skeleton cho message
  static Widget buildMessageSkeleton({
    bool isFromCurrentUser = false,
    bool showAvatar = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser && showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Container(
            width: 200,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          
          if (isFromCurrentUser && showAvatar) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Extract file name from URL (theo logic web)
  static String getFileNameFromUrl(String url, {String? attachmentName}) {
    try {
      // Ưu tiên tên file từ attachment
      if (attachmentName != null && attachmentName.isNotEmpty) {
        return attachmentName;
      }

      // Xử lý URL Facebook
      if (url.contains("fbsbx.com")) {
        final urlObj = Uri.parse(url);
        final pathParts = urlObj.pathSegments;
        
        for (int i = pathParts.length - 1; i >= 0; i--) {
          if (pathParts[i].isNotEmpty && pathParts[i].contains(".")) {
            return Uri.decodeComponent(pathParts[i]);
          }
        }
      }

      // Parse tên file từ URL thường
      final urlParts = url.split("/");
      for (int i = urlParts.length - 1; i >= 0; i--) {
        final part = urlParts[i];
        if (part.isNotEmpty && part.contains(".") && !part.startsWith("http")) {
          final fileNamePart = part.split("?")[0];
          if (fileNamePart.isNotEmpty) {
            return Uri.decodeComponent(fileNamePart);
          }
        }
      }

      // Fallback
      return "File đính kèm";
    } catch (error) {
      print("Lỗi khi trích xuất tên file: $error");
      return "File đính kèm";
    }
  }

  /// Check if URL is image
  static bool isImageUrl(String url) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains('.$ext'));
  }

  /// Get file type from extension
  static String getFileTypeFromExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return "${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${suffixes[i]}";
  }
} 