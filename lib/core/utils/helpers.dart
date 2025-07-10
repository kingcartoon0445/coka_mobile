import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class Helpers {
  /// Kiểm tra xem response có thành công hay không
  /// Hỗ trợ các mã: 0 (success), 200 (OK), 201 (Created)
  static bool isResponseSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['code'];
    return code == 0 || code == 200 || code == 201;
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  static String formatDate(DateTime date) {
    // Logic format date
    return '';
  }

  /// Chuyển đổi ngày từ định dạng dd/MM/yyyy sang ISO string
  static String convertToISOString(String dateStr) {
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      final date = DateTime(
        int.parse(parts[2]), // năm
        int.parse(parts[1]), // tháng
        int.parse(parts[0]), // ngày
      );
      return date.toIso8601String();
    }
    return dateStr;
  }

  static String getAvatarUrl(String? imgData) {
    if (imgData == null || imgData.isEmpty) return '';
    if (imgData.contains('https')) return imgData;
    return '${ApiClient.baseUrl}$imgData';
  }

  /// Clear cache cho một URL cụ thể
  static Future<void> clearImageCache(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final url = getAvatarUrl(imageUrl);
    await CachedNetworkImage.evictFromCache(url);
  }

  /// Clear toàn bộ image cache
  static Future<void> clearAllImageCache() async {
    await DefaultCacheManager().emptyCache();
  }

  static Color getColorFromText(String text) {
    final List<Color> colors = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFFE53935), // Red
      const Color(0xFF43A047), // Green
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFFFB300), // Amber
      const Color(0xFF00897B), // Teal
      const Color(0xFF3949AB), // Indigo
      const Color(0xFFD81B60), // Pink
      const Color(0xFF6D4C41), // Brown
      const Color(0xFF546E7A), // Blue Grey
    ];

    // Tính tổng mã ASCII của các ký tự trong text
    int sum = 0;
    for (int i = 0; i < text.length; i++) {
      sum += text.codeUnitAt(i);
    }

    // Lấy màu dựa trên phần dư của tổng với số lượng màu
    return colors[sum % colors.length];
  }

  static Color getTabBadgeColor(String tabName) {
    switch (tabName) {
      case "Tất cả":
        return const Color(0xFF5C33F0);
      case "Tiềm năng":
        return const Color(0xFF92F7A8);
      case "Giao dịch":
        return const Color(0xFFA4F3FF);
      case "Không tiềm năng":
        return const Color(0xFFFEC067);
      case "Chưa xác định":
        return const Color(0xFF9F87FF);
      default:
        return const Color(0xFF9F87FF);
    }
  }

  static String? getStageGroupName(String stageId) {
    for (var entry in AppConstants.stageObject.entries) {
      final stages = entry.value['data'] as List;
      if (stages.any((stage) => stage['id'] == stageId)) {
        return entry.value['name'] as String;
      }
    }
    return null;
  }
}

extension DioExceptionExt on DioException {
  String get errorMessage {
    final response = this.response?.data;
    if (response != null && response['message'] != null) {
      return response['message'];
    }
    return 'Có lỗi xảy ra, vui lòng thử lại';
  }
}

extension MapExtension on Map<String, dynamic> {
  Map<String, String> toQueryParameters() {
    final Map<String, String> result = {};

    void convert(String key, dynamic value) {
      if (value == null) return;

      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          result['$key[$i]'] = value[i].toString();
        }
      } else {
        result[key] = value.toString();
      }
    }

    forEach((key, value) => convert(key, value));
    return result;
  }
}

/// Enum cho vị trí tin nhắn trong chuỗi
enum MessagePosition {
  single, // Tin nhắn đơn lẻ
  firstInReply, // Tin nhắn đầu trong chuỗi
  middleInReply, // Tin nhắn giữa chuỗi
  lastInReply, // Tin nhắn cuối chuỗi
}

// Chat utility functions
class ChatHelpers {
  /// Xác định vị trí tin nhắn trong chuỗi
  static MessagePosition getMessagePosition(List messages, int index, String currentPersonId) {
    if (messages.isEmpty) return MessagePosition.single;

    final currentMessage = messages[index];
    final isFromCurrentPerson = currentMessage.from == currentPersonId;

    if (messages.length == 1) {
      return MessagePosition.single;
    } else if (index == 0) {
      final nextMessage = messages[index + 1];
      final nextIsFromCurrentPerson = nextMessage.from == currentPersonId;
      return isFromCurrentPerson == nextIsFromCurrentPerson
          ? MessagePosition.firstInReply
          : MessagePosition.single;
    } else if (index == messages.length - 1) {
      final prevMessage = messages[index - 1];
      final prevIsFromCurrentPerson = prevMessage.from == currentPersonId;
      return isFromCurrentPerson == prevIsFromCurrentPerson
          ? MessagePosition.lastInReply
          : MessagePosition.single;
    } else {
      final prevMessage = messages[index - 1];
      final nextMessage = messages[index + 1];
      final prevIsFromCurrentPerson = prevMessage.from == currentPersonId;
      final nextIsFromCurrentPerson = nextMessage.from == currentPersonId;

      if (isFromCurrentPerson != prevIsFromCurrentPerson &&
          isFromCurrentPerson == nextIsFromCurrentPerson) {
        return MessagePosition.firstInReply;
      } else if (isFromCurrentPerson == prevIsFromCurrentPerson &&
          isFromCurrentPerson != nextIsFromCurrentPerson) {
        return MessagePosition.lastInReply;
      } else if (isFromCurrentPerson == prevIsFromCurrentPerson &&
          isFromCurrentPerson == nextIsFromCurrentPerson) {
        return MessagePosition.middleInReply;
      } else {
        return MessagePosition.single;
      }
    }
  }

  /// Tạo border radius cho message bubble
  static BorderRadius getMessageBorderRadius(MessagePosition position, bool isFromUser) {
    if (isFromUser) {
      switch (position) {
        case MessagePosition.single:
          return BorderRadius.circular(14);
        case MessagePosition.lastInReply:
          return const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(3),
          );
        case MessagePosition.middleInReply:
          return const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(3),
          );
        case MessagePosition.firstInReply:
          return const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          );
      }
    } else {
      switch (position) {
        case MessagePosition.single:
          return BorderRadius.circular(14);
        case MessagePosition.lastInReply:
          return const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(3),
            bottomLeft: Radius.circular(14),
          );
        case MessagePosition.middleInReply:
          return const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(3),
            bottomRight: Radius.circular(3),
            bottomLeft: Radius.circular(14),
          );
        case MessagePosition.firstInReply:
          return const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(3),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          );
      }
    }
  }

  /// Format time difference
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Format time for message
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('dd/MM HH:mm').format(dateTime);
    }
  }

  /// Tạo avatar từ tên
  static Widget createCircleAvatar({
    required String name,
    double radius = 20,
    double? fontSize,
  }) {
    String initials = getInitials(name);
    Color avatarColor = getColorFromInitial(initials);

    return Container(
      height: radius * 2,
      width: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: CircleAvatar(
        backgroundColor: avatarColor,
        radius: radius,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize ?? (radius * 0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Lấy initials từ tên
  static String getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return (words.first[0] + words.last[0]).toUpperCase();
    }
  }

  /// Tạo màu từ initials
  static Color getColorFromInitial(String initials) {
    final colors = [
      const Color(0xFF5C33F0),
      const Color(0xFF0F5ABF),
      const Color(0xFF00A86B),
      const Color(0xFFFF6B35),
      const Color(0xFFE74C3C),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFFF39C12),
    ];

    int index = 0;
    for (int i = 0; i < initials.length; i++) {
      index += initials.codeUnitAt(i);
    }
    return colors[index % colors.length];
  }

  /// Get avatar provider từ URL/path
  static ImageProvider getAvatarProvider(String? imgData) {
    if (imgData == null || imgData.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }

    // Nếu là URL đầy đủ
    if (imgData.startsWith('https://') || imgData.startsWith('http://')) {
      return CachedNetworkImageProvider(imgData);
    }

    // Nếu là base64
    if (imgData.startsWith('data:image')) {
      final base64String = imgData.split(',')[1];
      return MemoryImage(base64Decode(base64String));
    }

    // Nếu là relative path từ server - cần config API base URL
    try {
      return CachedNetworkImageProvider(imgData);
    } catch (e) {
      return const AssetImage('assets/images/default_avatar.png');
    }
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Check if URL is image
  static bool isImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  /// Check if URL is video
  static bool isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext));
  }
}

class AvatarUtils {
  // Danh sách màu cho fallback avatar (tương tự react-avatar)
  static const List<Color> avatarColors = [
    Color(0xFFE53E3E), // red
    Color(0xFFD69E2E), // orange
    Color(0xFF38A169), // green
    Color(0xFF3182CE), // blue
    Color(0xFF805AD5), // purple
    Color(0xFFD53F8C), // pink
    Color(0xFF319795), // teal
    Color(0xFFE56B6F), // coral
  ];

  /// Tạo URL avatar từ string (tương tự getAvatarUrl trong utils.js)
  static String? getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return null;

    // Nếu đã là URL đầy đủ
    if (avatarPath.startsWith('http')) {
      return avatarPath;
    }

    // Nếu là đường dẫn tương đối, thêm base URL
    const String baseUrl = 'https://your-api-domain.com';
    return '$baseUrl/$avatarPath';
  }

  /// Lấy tên đầu và cuối từ họ tên (tương tự getFirstAndLastWord)
  static String getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return '?';
    }

    final words = fullName.trim().split(RegExp(r'\s+'));

    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  /// Tạo màu background cho avatar fallback
  static Color getAvatarColor(String text) {
    final bytes = utf8.encode(text);
    final hash = sha256.convert(bytes);
    final hashInt = hash.bytes.fold(0, (prev, byte) => prev + byte);
    return avatarColors[hashInt % avatarColors.length];
  }

  /// Kiểm tra xem URL có phải là ảnh không
  static bool isImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final lowerUrl = url.toLowerCase();

    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }
}

/// Avatar Memory Manager để optimize performance
class AvatarMemoryManager {
  static final Map<String, Widget> _avatarCache = {};
  static const int maxCacheSize = 100;

  static Widget getOrCreateAvatar({
    required String cacheKey,
    required String displayName,
    String? imageUrl,
    double size = 44,
  }) {
    if (_avatarCache.containsKey(cacheKey)) {
      return _avatarCache[cacheKey]!;
    }

    final avatar = _createAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      size: size,
    );

    if (_avatarCache.length >= maxCacheSize) {
      _avatarCache.remove(_avatarCache.keys.first);
    }

    _avatarCache[cacheKey] = avatar;
    return avatar;
  }

  static Widget _createAvatar({
    String? imageUrl,
    required String displayName,
    double size = 44,
  }) {
    final initials = AvatarUtils.getInitials(displayName);
    final avatarColor = AvatarUtils.getAvatarColor(displayName);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: AvatarUtils.getAvatarUrl(imageUrl) ?? '',
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => _buildTextAvatar(initials, avatarColor, size),
        errorWidget: (context, url, error) => _buildTextAvatar(initials, avatarColor, size),
      );
    }

    return _buildTextAvatar(initials, avatarColor, size);
  }

  static Widget _buildTextAvatar(String initials, Color bgColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static void clearCache() {
    _avatarCache.clear();
  }
}
