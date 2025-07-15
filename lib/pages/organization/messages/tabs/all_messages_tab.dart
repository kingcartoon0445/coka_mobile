import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/message_state.dart';
import '../widgets/message_item.dart';

class AllMessagesTab extends ConsumerStatefulWidget {
  final String organizationId;

  const AllMessagesTab({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<AllMessagesTab> createState() => _AllMessagesTabState();
}

class _AllMessagesTabState extends ConsumerState<AllMessagesTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  bool _isFirstBuild = true;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    ref.read(allMessageProvider.notifier).setupFirebaseListener(
          widget.organizationId,
          context,
        );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final state = ref.read(allMessageProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(allMessageProvider.notifier).fetchConversations(
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
        ref.read(allMessageProvider.notifier).reset();
        ref.read(allMessageProvider.notifier).fetchConversations(
              widget.organizationId,
              forceRefresh: true,
            );
      });
    }

    final state = ref.watch(allMessageProvider);

    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.isLoading && state.conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.read(allMessageProvider.notifier).reset();
          await ref.read(allMessageProvider.notifier).fetchConversations(
                widget.organizationId,
                forceRefresh: true,
              );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text('Không có tin nhắn nào'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(allMessageProvider.notifier).reset();
        await ref.read(allMessageProvider.notifier).fetchConversations(
              widget.organizationId,
              forceRefresh: true,
            );
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: state.conversations.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.conversations.length) {
            return state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox();
          }

          final conversation = state.conversations[index];
          return MessageItem(
            id: conversation.id,
            isRead: conversation.isRead,
            organizationId: widget.organizationId,
            sender: conversation.personName,
            content: conversation.snippet,
            isFileMessage: conversation.isFileMessage,
            time: conversation.updatedTime.toIso8601String(),
            platform: "ALL",
            avatar: conversation.personAvatar,
            pageAvatar: conversation.pageAvatar,
          );
        },
      ),
    );
  }
}
