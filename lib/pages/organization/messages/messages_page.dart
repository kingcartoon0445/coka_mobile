import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/helpers.dart';
import 'tabs/all_messages_tab.dart';
import 'tabs/facebook_messages_tab.dart';
import 'tabs/zalo_messages_tab.dart';

/// Avatar Preloader để tối ưu performance
class AvatarPreloader {
  static Future<void> preloadAvatars(List<dynamic> messages, BuildContext context) async {
    final uniqueAvatars = messages
        .where((msg) => msg.avatar != null && msg.avatar!.isNotEmpty)
        .map((msg) => AvatarUtils.getAvatarUrl(msg.avatar))
        .where((url) => url != null)
        .toSet();

    for (final url in uniqueAvatars) {
      try {
        await precacheImage(CachedNetworkImageProvider(url!), context);
      } catch (e) {
        print('Failed to preload avatar: $url');
      }
    }
  }

  static void clearMemoryCache() {
    AvatarMemoryManager.clearCache();
  }
}

class MessagesPage extends StatelessWidget {
  final String organizationId;

  const MessagesPage({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _MessagesView(organizationId: organizationId),
    );
  }
}

class _MessagesView extends ConsumerWidget {
  final String organizationId;

  const _MessagesView({
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white,
            child: SafeArea(
              child: TabBar(
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Facebook'),
                  Tab(text: 'ZaloOA'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            AllMessagesTab(organizationId: organizationId),
            FacebookMessagesTab(organizationId: organizationId),
            ZaloMessagesTab(organizationId: organizationId),
          ],
        ),
      ),
    );
  }
}
