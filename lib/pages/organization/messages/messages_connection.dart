// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/message_repository.dart';
import 'package:coka/bloc/messages_connection/messages_connection_cubit.dart';
import 'package:coka/bloc/messages_connection/messages_connection_state.dart';
import 'package:coka/constants.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/pages/organization/messages/models/page_facebook_model.dart';
import 'package:coka/pages/organization/messages/widgets/chat_channel.dart';
import 'package:coka/shared/widgets/awesome_alert.dart';
import 'package:coka/widgets/auto_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shimmer/shimmer.dart';

import '../../../shared/widgets/loading_dialog.dart';

class MessagesConnectionPage extends StatefulWidget {
  final String organizationId;
  final String workspaceId;

  const MessagesConnectionPage(
      {super.key, required this.organizationId, required this.workspaceId});

  @override
  State<MessagesConnectionPage> createState() => _MessagesConnectionPageState();
}

class _MessagesConnectionPageState extends State<MessagesConnectionPage> {
  late MessagesConnectionCubit messagesCubit;

  @override
  void initState() {
    super.initState();
    messagesCubit = BlocProvider.of<MessagesConnectionCubit>(context);
    messagesCubit.initialize(widget.organizationId);
  }

  bool isSuccessStatus(int? code) => code != null && (code == 0 || (code >= 200 && code < 300));

  String buildAccessTokenJson(List<FacebookPage> pages) {
    final tokens = pages.map((e) => e.accessToken).toList();
    return jsonEncode({'accessTokens': tokens});
  }

  Future<List<FacebookPage>> showFacebookPageDialog(
      BuildContext context, List<FacebookPage> pages) async {
    final selectedPages = <String>{};
    return await showDialog<List<FacebookPage>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chọn trang Facebook'),
            content: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: pages.map((page) {
                    final isSelected = selectedPages.contains(page.id);
                    return CheckboxListTile(
                      title: Text(page.name),
                      subtitle: Text(page.category),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() => value == true
                            ? selectedPages.add(page.id)
                            : selectedPages.remove(page.id));
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, <FacebookPage>[]),
                  child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  final selected = pages.where((p) => selectedPages.contains(p.id)).toList();
                  Navigator.pop(context, selected);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ) ??
        [];
  }

  Future<void> connectFacebookMessenger(BuildContext context) async {
    final result = await FacebookAuth.i.login(permissions: [
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
    ]);

    if (result.status != LoginStatus.success) {
      errorAlert(title: "Thất bại", desc: "Đã có lỗi xảy ra, xin vui lòng thử lại");
      return;
    }

    final tokenFB = result.accessToken!.tokenString;
    showLoadingDialog(context);

    try {
      final value = await MessageRepository(ApiClient()).getPagesFaceWithToken(tokenFB);
      final pages = FacebookPageList.fromJson(value).data;

      if (pages.isEmpty) {
        Navigator.of(context).pop();
        errorAlert(
            title: "Không có trang nào",
            desc: "Bạn chưa liên kết trang nào với tài khoản Facebook này");
        return;
      }

      final selectedPages = await showFacebookPageDialog(context, pages);
      if (selectedPages.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      final res = await MessageRepository(ApiClient()).connectFacebook(
        widget.organizationId,
        widget.workspaceId,
        buildAccessTokenJson(selectedPages),
      );

      Navigator.of(context).pop();
      Navigator.of(context).pop();

      if (isSuccessStatus(res["code"])) {
        messagesCubit.initialize(widget.organizationId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã kết nối với facebook"),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi kết nối: ${res["message"]}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      errorAlert(title: "Lỗi", desc: "Đã xảy ra lỗi khi kết nối");
    }
  }

  void showSelectBottomsheet(BuildContext context) {
    final connectChatList = [
      {
        "name": "Liên kết qua messenger",
        "iconPath": "assets/images/fb_messenger_icon.png",
        "onPressed": () => connectFacebookMessenger(context),
      },
      {
        "name": "Liên kết qua Zalo OA",
        "iconPath": "assets/images/zalo_icon.png",
        "onPressed": () async {
          // if (Platform.isIOS) {
          //   return errorAlert(
          //       title: "Rất tiếc!", desc: "Tính năng này chưa được phát triển ở nền tảng iOS");
          // }
          final webController = MyChromeSafariBrowser(onWebClosed: () {}, organizationId: "");
          final oData = await getOData();
          final oId = oData["id"];
          webController.open(
            url: WebUri(
                '${ApiClient.baseUrl}/api/v1/auth/zalo/message?accessToken=${await getAccessToken()}&organizationId=$oId'),
          );
        },
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Liên kết trang",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(height: 24),
                ...connectChatList.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: e["onPressed"] as VoidCallback,
                          leading: Image.asset(e["iconPath"] as String, width: 32, height: 32),
                          title: Text(e["name"] as String),
                        ),
                      ),
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagesConnectionCubit, MessagesConnectionState>(
      bloc: messagesCubit,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Kết nối tin nhắn",
                style:
                    TextStyle(color: Color(0xFF1F2329), fontSize: 20, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                  icon: const Icon(Icons.add), onPressed: () => showSelectBottomsheet(context))
            ],
          ),
          body: state.messagesConectionResponse == null
              ? const ListPlaceholder(length: 10, avatarSize: 44)
              : RefreshIndicator(
                  onRefresh: () async => messagesCubit.initialize(widget.organizationId),
                  child: buildConnectionList(state),
                ),
        );
      },
    );
  }

  Widget buildConnectionList(MessagesConnectionState state) {
    final connections = state.messagesConectionResponse?.content ?? [];
    if (connections.isEmpty) {
      return buildEmptyConnectionState();
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      itemCount: connections.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final roomData = connections[index];
        final isActive = roomData.status == 1;
        return ListTile(
          title: Text(roomData.name ?? "",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2329)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(roomData.provider ?? "",
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B8B8B))),
          trailing: Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isActive,
              activeTrackColor: AppColors.primary,
              onChanged: (value) async {
                showLoadingDialog(context);
                final result = await messagesCubit.updateStatisOmniChannel(
                    widget.organizationId, roomData.id!, value ? 1 : 0);
                Navigator.of(context).pop();
                if (result) {
                  messagesCubit.initialize(widget.organizationId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Lỗi khi cập nhật trạng thái'), backgroundColor: Colors.red));
                }
              },
            ),
          ),
          leading: roomData.avatar == null
              ? createCircleAvatar(name: roomData.name ?? "", radius: 15)
              : CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.network(
                      roomData.avatar!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return createCircleAvatar(name: roomData.name ?? "", radius: 22);
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget buildEmptyConnectionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/null_multi_connect.png"),
            const SizedBox(height: 16),
            const Text("Hiện chưa có kết nối nào", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C33F0)),
              onPressed: () => showSelectBottomsheet(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.0),
                child: Text("Liên kết",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Shimmer loading
class ListPlaceholder extends StatelessWidget {
  final int length;
  final double? contentHeight, avatarSize, bottomPadding;

  const ListPlaceholder(
      {super.key, required this.length, this.contentHeight, this.avatarSize, this.bottomPadding});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
            length,
            (x) => Padding(
                  padding: EdgeInsets.only(top: 11.0, bottom: bottomPadding ?? 23.0),
                  child: ContentPlaceholder(
                    lineType: ContentLineType.twoLines,
                    contentHeight: contentHeight ?? 10,
                    avatarSize: avatarSize ?? 50,
                  ),
                )),
      ),
    );
  }
}

enum ContentLineType { twoLines, threeLines }

class ContentPlaceholder extends StatelessWidget {
  final ContentLineType lineType;
  final double contentHeight, avatarSize;

  const ContentPlaceholder(
      {super.key, required this.lineType, required this.contentHeight, required this.avatarSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 160,
                    height: contentHeight,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8.0)),
                if (lineType == ContentLineType.threeLines)
                  Container(
                      width: 160,
                      height: contentHeight,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8.0)),
                Container(width: 70.0, height: contentHeight, color: Colors.white)
              ],
            ),
          )
        ],
      ),
    );
  }
}
