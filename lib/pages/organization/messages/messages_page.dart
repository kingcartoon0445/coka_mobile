import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/message_repository.dart';
import 'package:coka/shared/widgets/awesome_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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

bool isSuccessStatus(int number) {
  if (number == 0 || (number >= 200 && number <= 299)) {
    return true;
  } else {
    return false;
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await FacebookAuth.i.login(
              permissions: [
                "email",
                "openid",
                "pages_show_list",
                "pages_messaging",
                "instagram_basic",
                "leads_retrieval",
                "instagram_manage_messages",
                "pages_read_engagement",
                "pages_manage_metadata",
                "pages_read_user_content",
                "pages_manage_engagement",
                "public_profile"
              ],
            );

            if (result.status == LoginStatus.success) {
              // Future.delayed(const Duration(milliseconds: 50), () => showLoadingDialog(context));

              MessageRepository(ApiClient()).connectFacebook(organizationId,
                  {"socialAccessToken": result.accessToken!.tokenString}).then((res) {
                if (isSuccessStatus(res["code"])) {
                  // final chatChannelController = Get.put(ChatChannelController());
                  // chatChannelController.onRefresh();
                  // Get.back();
                  // Navigator.of(context).pop(); // Đóng dialog loading
                  // Đóng dialog loading
                  successAlert(title: "Thành công", desc: "Đã kết nối với facebook");
                } else {
                  // errorAlert(title: "Lỗi", desc: res["message"]);
                }
              });
            } else {
              // errorAlert(title: "Thất bại", desc: "Đã có lỗi xảy ra, xin vui lòng thử lại");
            }
          } // Navigate to create message page
          ,
          child: Text("data"),
        ),
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
