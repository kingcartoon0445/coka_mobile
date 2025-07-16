import 'dart:developer';
import 'dart:io';

import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/message_repository.dart';
import 'package:coka/bloc/messages_connection/messages_connection_cubit.dart';
import 'package:coka/bloc/messages_connection/messages_connection_state.dart';
import 'package:coka/constants.dart';
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
  // String provider;
  final String organizationId;
  // final Function(String,String) onTap;
  const MessagesConnectionPage({
    super.key,
    required this.organizationId,
    // required this.onTap,
    // required this.provider,
  });

  @override
  State<MessagesConnectionPage> createState() => _MessagesConnectionPageState();
}

class _MessagesConnectionPageState extends State<MessagesConnectionPage> {
  late MessagesConnectionCubit messagesCubit;
  bool isSuccessStatus(int number) {
    if (number == 0 || (number >= 200 && number <= 299)) {
      return true;
    } else {
      return false;
    }
  }

  void showSelectBottomsheet(BuildContext context) {
    final connectChatList = [
      {
        "name": "Liên kết qua messenger",
        "iconPath": "assets/images/fb_messenger_icon.png",
        "onPressed": () async {
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
            Future.delayed(const Duration(milliseconds: 50), () => showLoadingDialog(context));

            MessageRepository(ApiClient()).connectFacebook(widget.organizationId,
                {"socialAccessToken": result.accessToken!.tokenString}).then((res) {
              // Get.back();
              if (isSuccessStatus(res["code"])) {
                messagesCubit.initialize(widget.organizationId);
                // final chatChannelController = Get.put(ChatChannelController());
                // chatChannelController.onRefresh();
                // Get.back();
                Navigator.of(context).pop();
                successAlert(title: "Thành công", desc: "Đã kết nối với facebook");
              } else {
                errorAlert(title: "Lỗi", desc: res["message"]);
              }
            });
          } else {
            errorAlert(title: "Thất bại", desc: "Đã có lỗi xảy ra, xin vui lòng thử lại");
          }
        }
      },
      {
        "name": "Liên kết qua Zalo OA",
        "iconPath": "assets/images/zalo_icon.png",
        "onPressed": () async {
          if (Platform.isIOS) {
            return errorAlert(
                title: "Rất tiếc!", desc: "Tính năng này chưa được phát triển ở nền tảng iOS");
          }
          // HomeController homeController = Get.put(HomeController());
          final webController = MyChromeSafariBrowser(
              onWebClosed: () {
                // final chatChannelController = Get.put(ChatChannelController());
                // chatChannelController.onRefresh();
                // Get.back();
              },
              organizationId: "");
          final oData = await getOData();
          final oId = oData["id"];
          log("duy: '${ApiClient.baseUrl}/api/v1/auth/zalo/message?accessToken=${await getAccessToken()}&organizationId=$oId");
          webController.open(
            url: WebUri(
              '${ApiClient.baseUrl}/api/v1/auth/zalo/message?accessToken=${await getAccessToken()}&organizationId=$oId',
            ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Liên kết trang",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    ...connectChatList.map((e) {
                      return Padding(
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
                      );
                    })
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    messagesCubit = BlocProvider.of<MessagesConnectionCubit>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    messagesCubit.initialize(
      widget.organizationId,
    );
    return BlocBuilder<MessagesConnectionCubit, MessagesConnectionState>(
        bloc: messagesCubit,
        builder: (context, state) {
          // if (state.status != MessagesConnectionStatus.loading &&
          //     state.messagesConectionResponse == null) {
          //   return _buildEmptyState();
          // }

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                "Kết nối tin nhắn",
                style: TextStyle(
                  color: Color(0xFF1F2329),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // Nav
                    showSelectBottomsheet(context);
                  },
                ),
              ],
            ),
            body: state.messagesConectionResponse == null
                ? const ListPlaceholder(
                    length: 10,
                    avatarSize: 44,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      messagesCubit.initialize(widget.organizationId);
                      // await controller.fetchChannelList();
                    },
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: state.messagesConectionResponse!.content!.isEmpty
                          ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 30.0, right: 30, top: 40),
                                  child: Image.asset(
                                    "assets/images/null_multi_connect.png",
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                const Text(
                                  "Hiện chưa có kết nối nào",
                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5C33F0)),
                                    onPressed: () {
                                      // showSelectBottomsheet(context);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 35.0),
                                      child: Text(
                                        "Liên kết",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white),
                                      ),
                                    ))
                              ],
                            )
                          : ConstrainedBox(
                              constraints: BoxConstraints(minHeight: 220),
                              child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final roomData =
                                        state.messagesConectionResponse!.content![index];
                                    final title = roomData.name;
                                    final subtitle = roomData.provider;
                                    final avatar = roomData.avatar;

                                    var isActive = roomData.status == 1 ? true : false;
                                    return ListTile(
                                        // onTap: () {
                                        //   if (isActive) {
                                        //     // widget.onTap.call(roomData.integrationAuthId!,roomData.name);
                                        //     // context.push(AppPaths.messages(
                                        //     //     widget.organizationId, roomData.integrationAuthId!));
                                        //   }
                                        // },
                                        title: Text(
                                          title ?? "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(subtitle ?? ""),
                                        trailing: Switch(
                                          value: isActive,
                                          activeTrackColor: const Color(0xFFF07A22),
                                          onChanged: (value) {
                                            // setState(() {
                                            //   isActive = value;
                                            // });
                                            showLoadingDialog(context);
                                            messagesCubit
                                                .updateStatisOmniChannel(
                                              widget.organizationId,
                                              roomData.id!,
                                              value ? 1 : 0,
                                            )
                                                .then((value) {
                                              Navigator.of(context).pop();
                                              if (value) {
                                                messagesCubit.initialize(widget.organizationId);
                                                // ScaffoldMessenger.of(context).showSnackBar(
                                                //   const SnackBar(
                                                //     content: Text('Đã kích hoạt kết nối'),
                                                //     backgroundColor: Colors.green,
                                                //   ),
                                                // );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Đã tắt kết nối'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            });
                                            // Tắt dialog
                                            // Navigator.of(context).pop();
                                            // LeadApi()
                                            //     .updateMessageStatus(
                                            //   roomData["id"],
                                            //   value ? 1 : 0,
                                            // )
                                            //     .then((res) {
                                            //   Get.back();
                                            //   if (isSuccessStatus(res["code"])) {
                                            //     setState(() {
                                            //       roomData["status"] = value ? 1 : 0;
                                            //     });
                                            //   } else {
                                            //     errorAlert(title: "Lỗi", desc: res["message"]);
                                            //   }
                                            // });
                                          },
                                        ),
                                        leading: avatar == null
                                            ? createCircleAvatar(name: title ?? "", radius: 22)
                                            : Container(
                                                height: 44,
                                                width: 44,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: const Color(0x663949AB), width: 1),
                                                    color: Colors.white),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(50),
                                                  child: getAvatarWidget(avatar),
                                                ),
                                              ));
                                  },
                                  itemCount: state.messagesConectionResponse!.content!.length,
                                  shrinkWrap: true),
                            ),
                    ),
                  ),
          );
        });
  }
}

Widget _buildEmptyState() {
  return Container(
    color: const Color(0xFFF8F8F8),
    child: RefreshIndicator(
      onRefresh: () async {
        // ref.read(facebookMessageProvider.notifier).reset();
        // await ref.read(facebookMessageProvider.notifier).fetchConversations(
        //       widget.organizationId,
        //       forceRefresh: true,
        //       integrationAuthId: widget.integrationAuthId,
        //     );
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
                  onPressed: () {},
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

enum ContentLineType {
  twoLines,
  threeLines,
}

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
        enabled: true,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              for (var x = 0; x < length; x++)
                Padding(
                  padding: EdgeInsets.only(top: 11.0, bottom: bottomPadding ?? 23.0),
                  child: ContentPlaceholder(
                    lineType: ContentLineType.twoLines,
                    contentHeight: contentHeight ?? 10,
                    avatarSize: avatarSize ?? 50,
                  ),
                )
            ],
          ),
        ));
  }
}

class ContentPlaceholder extends StatelessWidget {
  final ContentLineType lineType;
  final double contentHeight, avatarSize;

  const ContentPlaceholder({
    super.key,
    required this.lineType,
    required this.contentHeight,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  height: contentHeight,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8.0),
                ),
                if (lineType == ContentLineType.threeLines)
                  Container(
                    width: 160,
                    height: contentHeight,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8.0),
                  ),
                Container(
                  width: 70.0,
                  height: contentHeight,
                  color: Colors.white,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
