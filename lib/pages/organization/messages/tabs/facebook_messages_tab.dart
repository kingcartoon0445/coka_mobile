import 'package:coka/pages/organization/messages/widgets/message_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/enhanced_avatar_widget.dart';
import '../state/message_state.dart';

class FacebookMessagesTab extends ConsumerStatefulWidget {
  final String organizationId;

  const FacebookMessagesTab({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<FacebookMessagesTab> createState() => _FacebookMessagesTabState();
}

class _FacebookMessagesTabState extends ConsumerState<FacebookMessagesTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  bool _isFirstBuild = true;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref
        .read(facebookMessageProvider.notifier)
        .setupFirebaseListener(widget.organizationId, context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final state = ref.read(facebookMessageProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(facebookMessageProvider.notifier).fetchConversations(
              widget.organizationId,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Reset và fetch lại data khi tab được focus
    if (_isFirstBuild) {
      _isFirstBuild = false;
      Future.microtask(() {
        ref.read(facebookMessageProvider.notifier).reset();
        ref.read(facebookMessageProvider.notifier).fetchConversations(
              widget.organizationId,
              forceRefresh: true,
            );
      });
    }

    final state = ref.watch(facebookMessageProvider);

    if (state.isLoading && state.conversations.isEmpty) {
      return _buildLoadingState();
    }

    if (!state.isLoading && state.conversations.isEmpty) {
      return _buildEmptyState();
    }

    return _buildConversationList(state);
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF554FE8),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(facebookMessageProvider.notifier).reset();
          await ref.read(facebookMessageProvider.notifier).fetchConversations(
                widget.organizationId,
                forceRefresh: true,
              );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.facebook,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có tin nhắn Facebook nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kết nối trang Facebook để nhận tin nhắn',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _connectFacebookPage(),
                    icon: const Icon(Icons.add_link),
                    label: const Text('Kết nối trang Facebook'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF554FE8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(MessageState state) {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(facebookMessageProvider.notifier).reset();
          await ref.read(facebookMessageProvider.notifier).fetchConversations(
                widget.organizationId,
                forceRefresh: true,
              );
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          itemCount: state.conversations.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 0.5,
            color: Color(0xFFE5E5E5),
          ),
          itemBuilder: (context, index) {
            if (index == state.conversations.length) {
              return state.isLoading ? _buildLoadingMoreIndicator() : const SizedBox();
            }

            final conversation = state.conversations[index];
            return MessageItem(
              isRead: conversation.isRead,
              id: conversation.id,
              organizationId: widget.organizationId,
              sender: conversation.personName,
              isFileMessage: conversation.isFileMessage,
              content: conversation.snippet,
              time: conversation.updatedTime.toIso8601String(),
              platform: conversation.provider,
              avatar: conversation.avatar,
              pageAvatar: conversation.pageAvatar,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF554FE8),
        ),
      ),
    );
  }

  Widget _buildEnhancedMessageItem(Conversation conversation, int index) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _navigateToChat(conversation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online indicator
              _buildConversationAvatar(conversation),

              const SizedBox(width: 12),

              // Conversation info
              Expanded(
                child: _buildConversationInfo(conversation),
              ),

              const SizedBox(width: 8),

              // Time and badges
              _buildConversationMeta(conversation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationAvatar(Conversation conversation) {
    return Stack(
      children: [
        // Main avatar
        CustomAvatar(
          imageUrl: conversation.avatar,
          displayName: conversation.personName,
          size: 48,
          showBorder: true,
          borderColor: Colors.white,
          borderWidth: 2,
        ),

        // Page avatar overlay (Facebook logo)
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2), // Facebook blue
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.facebook,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),

        // Online status (based on recent activity)
        if (conversation.status == 'ACTIVE')
          Positioned(
            top: 0,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversationInfo(Conversation conversation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer name
        Text(
          conversation.personName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // Last message preview
        Text(
          conversation.snippet,
          style: TextStyle(
            fontSize: 14,
            color: !conversation.isRead ? Colors.black87 : Colors.grey[600],
            fontWeight: !conversation.isRead ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildConversationMeta(Conversation conversation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Time
        Text(
          ChatHelpers.getTimeAgo(conversation.updatedTime),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 4),

        // Badges
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unread indicator (if not read)
            if (!conversation.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF554FE8),
                  shape: BoxShape.circle,
                ),
              ),

            // Assigned indicator
            if (conversation.assignName != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.person,
                color: Colors.green[600],
                size: 16,
              ),
            ],

            // GPT status indicator
            if (conversation.gptStatus == 1) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.smart_toy,
                color: Colors.blue[600],
                size: 16,
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _navigateToChat(Conversation conversation) {
    // TODO: Navigate to chat detail page
    print('Navigate to chat: ${conversation.id}');
  }

  void _connectFacebookPage() {
    // TODO: Navigate to Facebook connection page
    print('Connect Facebook page');
  }
}
