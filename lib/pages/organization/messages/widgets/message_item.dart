import 'package:coka/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../shared/widgets/avatar_widget.dart';
import '../state/message_state.dart';

class MessageItem extends ConsumerWidget {
  final String id;
  final String organizationId;
  final String sender;
  final String content;
  final String time;
  final String platform;
  final bool isRead;
  final bool isFileMessage; // Biến này có thể được sử dụng nếu cần thiết
  final String? avatar;
  final String? pageAvatar;

  const MessageItem({
    super.key,
    required this.id,
    required this.isRead,
    this.isFileMessage = false, // Mặc định là false, có thể thay đổi nếu cần
    required this.organizationId,
    required this.sender,
    required this.content,
    required this.time,
    required this.platform,
    this.avatar,
    this.pageAvatar,
  });

  String _getFirstAndLastWord(String text) {
    final words = text.split(' ');
    if (words.length == 1) return words[0][0];
    return words.first[0] + words.last[0];
  }

  Widget _buildAvatar(String name, String? imageUrl, double size) {
    return AppAvatar(
      imageUrl: imageUrl,
      size: size,
      shape: AvatarShape.circle,
      fallbackText: name,
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Kiểm tra conversation trong state tương ứng và cập nhật selected conversation
    if (platform == 'FACEBOOK') {
      if (ref.read(facebookMessageProvider).conversations.any((c) => c.id == id)) {
        if (!isRead) {
          ref.read(facebookMessageProvider.notifier).updateStatusRead(organizationId, id);
          ref.read(allMessageProvider.notifier).updateStatusRead(organizationId, id);
        }
        ref.read(facebookMessageProvider.notifier).selectConversation(id);
        ref.read(allMessageProvider.notifier).selectConversation(id);
      } else if (ref.read(allMessageProvider).conversations.any((c) => c.id == id)) {
        if (!isRead) {
          ref.read(allMessageProvider.notifier).updateStatusRead(organizationId, id);
        }
        ref.read(allMessageProvider.notifier).selectConversation(id);
      }
    }
    if (platform == 'ZALO') {
      if (ref.read(zaloMessageProvider).conversations.any((c) => c.id == id)) {
        if (!isRead) {
          ref.read(zaloMessageProvider.notifier).updateStatusRead(organizationId, id);
        }
        ref.read(zaloMessageProvider.notifier).selectConversation(id);
      } else {
        if (ref.read(allMessageProvider).conversations.any((c) => c.id == id)) {
          if (!isRead) {
            ref.read(allMessageProvider.notifier).updateStatusRead(organizationId, id);
          }
          ref.read(allMessageProvider.notifier).selectConversation(id);
        }
        // Nếu không tìm thấy conversation trong state, có thể là do chưa tải dữ liệu
        // Bạn có thể thêm logic để tải dữ liệu nếu cần thiết
        print('Conversation with id $id not found in allMessageProvider');
      }
    }

    // Điều hướng đến trang chi tiết
    context.push('/organization/$organizationId/messages/detail/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      elevation: 0,
      child: InkWell(
        onTap: () {
          // Cập nhật trạng thái đã đọc khi người dùng nhấn vào tin nhắn

          _handleTap(context, ref);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(sender, avatar, 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            sender,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              timeago.format(
                                DateTime.parse(time),
                                locale: 'vi',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SvgPicture.asset(
                              platform == 'FACEBOOK'
                                  ? 'assets/icons/messenger.svg'
                                  : 'assets/icons/zalo.svg',
                              width: 16,
                              height: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            isFileMessage ? "Đã nhận được 1 ảnh/file" : content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontStyle: isFileMessage ? FontStyle.italic : null,
                                color: isRead ? Colors.black54 : Colors.black,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w600),
                          ),
                        ),
                        if (pageAvatar != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildAvatar('Page', pageAvatar, 15),
                          ),
                        if (!isRead) ...[
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            height: 12,
                            width: 12,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
