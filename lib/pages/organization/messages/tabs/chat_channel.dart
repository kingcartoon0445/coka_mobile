// import 'dart:convert';
// import 'dart:io';

// import 'package:coka/api/api_client.dart';
// import 'package:coka/api/repositories/message_repository.dart';
// import 'package:coka/constants.dart';
// import 'package:coka/pages/organization/messages/state/message_state.dart';
// import 'package:coka/shared/widgets/loading_dialog.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path/path.dart';

// class MyChromeSafariBrowser extends ChromeSafariBrowser {
//   final VoidCallback onWebClosed;

//   MyChromeSafariBrowser({required this.onWebClosed});

//   @override
//   void onClosed() {
//     onWebClosed();
//     super.onClosed();
//   }
// }

// class ChatChannelPage extends ConsumerStatefulWidget {
//   const ChatChannelPage({super.key});

//   @override
//   ConsumerState<ChatChannelPage> createState() => _ChatChannelPageState();
// }

// class _ChatChannelPageState extends ConsumerState<ChatChannelPage> {
//   final connectChatList = [
//     {
//       "name": "Liên kết qua messenger",
//       "iconPath": "assets/images/fb_messenger_icon.png",
//       "onPressed": () async {
//         final result = await FacebookAuth.i.login(
//           permissions: [
//             "email",
//             "openid",
//             "pages_show_list",
//             "pages_messaging",
//             "instagram_basic",
//             "leads_retrieval",
//             "instagram_manage_messages",
//             "pages_read_engagement",
//             "pages_manage_metadata",
//             "pages_read_user_content",
//             "pages_manage_engagement",
//             "public_profile"
//           ],
//         );
//         if (result.status == LoginStatus.success) {
//           Future.delayed(const Duration(milliseconds: 50), () => showLoadingDialog(context));

//           MessageRepository(ApiClient())
//               .connectFacebook({"socialAccessToken": result.accessToken!.tokenString}).then((res) {
//             Get.back();
//             if (isSuccessStatus(res["code"])) {
//               final chatChannelController = Get.put(ChatChannelController());
//               chatChannelController.onRefresh();
//               Get.back();
//               successAlert(title: "Thành công", desc: "Đã kết nối với facebook");
//             } else {
//               errorAlert(title: "Lỗi", desc: res["message"]);
//             }
//           });
//         } else {
//           errorAlert(title: "Thất bại", desc: "Đã có lỗi xảy ra, xin vui lòng thử lại");
//         }
//       }
//     },
//     {
//       "name": "Liên kết qua Zalo OA",
//       "iconPath": "assets/images/zalo_icon.png",
//       "onPressed": () async {
//         if (Platform.isIOS) {
//           return errorAlert(
//               title: "Rất tiếc!", desc: "Tính năng này chưa được phát triển ở nền tảng iOS");
//         }
//         HomeController homeController = Get.put(HomeController());
//         final webController = MyChromeSafariBrowser(onWebClosed: () {
//           final chatChannelController = Get.put(ChatChannelController());
//           chatChannelController.onRefresh();
//           Get.back();
//         });
//         webController.open(
//           url: Uri.parse(
//             '${apiBaseUrl}api/v1/auth/zalo/message?accessToken=${await getAccessToken()}&organizationId=${jsonDecode(await getOData())["id"]}',
//           ),
//         );
//       },
//     },
//   ];
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ChatChannelController>(builder: (controller) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           surfaceTintColor: Colors.white,
//           title: const Text(
//             "Trang kết nối",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2329)),
//           ),
//           centerTitle: true,
//           automaticallyImplyLeading: true,
//           actions: [
//             IconButton(
//                 onPressed: () {
//                   showSelectBottomsheet(context);
//                 },
//                 icon: const Icon(
//                   Icons.add,
//                   size: 26,
//                 ))
//           ],
//           bottom: const PreferredSize(
//             preferredSize: Size.fromHeight(76.0), // Height of the search bar.
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
//               child: SearchBar(
//                 hintText: "Tìm kiếm",
//                 backgroundColor: WidgetStatePropertyAll(Color(0xFFF2F3F5)),
//                 leading: Icon(Icons.search),
//               ),
//             ),
//           ),
//           bottomOpacity: 1.0, // Ensures the search bar stays visible when scrolling.
//         ),
//         body: controller.isChannelFetching.value
//             ? const ListPlaceholder(
//                 length: 10,
//                 avatarSize: 44,
//               )
//             : RefreshIndicator(
//                 onRefresh: () => controller.onRefresh(),
//                 child: SingleChildScrollView(
//                   physics: const ClampingScrollPhysics(),
//                   child: controller.isChannelEmpty.value
//                       ? Column(
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(left: 30.0, right: 30, top: 40),
//                               child: Image.asset(
//                                 "assets/images/null_multi_connect.png",
//                               ),
//                             ),
//                             const SizedBox(
//                               height: 16,
//                             ),
//                             const Text(
//                               "Hiện chưa có kết nối nào",
//                               style: TextStyle(color: Colors.black, fontSize: 16),
//                             ),
//                             const SizedBox(
//                               height: 16,
//                             ),
//                             ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF5C33F0)),
//                                 onPressed: () {
//                                   showSelectBottomsheet(context);
//                                 },
//                                 child: const Padding(
//                                   padding: EdgeInsets.symmetric(horizontal: 35.0),
//                                   child: Text(
//                                     "Liên kết",
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16,
//                                         color: Colors.white),
//                                   ),
//                                 ))
//                           ],
//                         )
//                       : ConstrainedBox(
//                           constraints: BoxConstraints(minHeight: Get.height - 120),
//                           child: ListView.builder(
//                               physics: const NeverScrollableScrollPhysics(),
//                               itemBuilder: (context, index) {
//                                 final roomData = controller.channelList[index];
//                                 final title = roomData["name"];
//                                 final subtitle = roomData["provider"];
//                                 final avatar = roomData["avatar"];

//                                 var isActive = roomData["status"] == 1 ? true : false;
//                                 return ListTile(
//                                     onTap: () {
//                                       if (isActive) {
//                                         Get.to(() => ChatRoomPage(
//                                             pageName: title,
//                                             pageAvatar: avatar,
//                                             pageId: roomData["integrationAuthId"],
//                                             provider: subtitle));
//                                       }
//                                     },
//                                     title: Text(
//                                       title,
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     subtitle: Text(subtitle),
//                                     trailing: Switch(
//                                       value: isActive,
//                                       activeTrackColor: const Color(0xFFF07A22),
//                                       onChanged: (value) {
//                                         isActive = value;
//                                         showLoadingDialog(context);
//                                         LeadApi()
//                                             .updateMessageStatus(
//                                           roomData["id"],
//                                           value ? 1 : 0,
//                                         )
//                                             .then((res) {
//                                           Get.back();
//                                           if (isSuccessStatus(res["code"])) {
//                                             setState(() {
//                                               roomData["status"] = value ? 1 : 0;
//                                             });
//                                           } else {
//                                             errorAlert(title: "Lỗi", desc: res["message"]);
//                                           }
//                                         });
//                                       },
//                                     ),
//                                     leading: avatar == null
//                                         ? createCircleAvatar(name: title, radius: 22)
//                                         : Container(
//                                             height: 44,
//                                             width: 44,
//                                             decoration: BoxDecoration(
//                                                 shape: BoxShape.circle,
//                                                 border: Border.all(
//                                                     color: const Color(0x663949AB), width: 1),
//                                                 color: Colors.white),
//                                             child: ClipRRect(
//                                               borderRadius: BorderRadius.circular(50),
//                                               child: getAvatarWidget(avatar),
//                                             ),
//                                           ));
//                               },
//                               itemCount: controller.channelList.length,
//                               shrinkWrap: true),
//                         ),
//                 ),
//               ),
//       );
//     });
//   }

//   void showSelectBottomsheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       backgroundColor: Colors.white,
//       isScrollControlled: true,
//       builder: (context) => Wrap(
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text(
//                   "Liên kết trang",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ),
//               const Divider(height: 1),
//               const SizedBox(
//                 height: 20,
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Column(
//                   children: [
//                     ...connectChatList.map((e) {
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 8.0),
//                         child: Card(
//                           elevation: 0,
//                           color: Colors.white,
//                           child: ListTile(
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             onTap: e["onPressed"] as VoidCallback,
//                             leading: Image.asset(e["iconPath"] as String, width: 32, height: 32),
//                             title: Text(e["name"] as String),
//                           ),
//                         ),
//                       );
//                     })
//                   ],
//                 ),
//               ),
//               const SizedBox(
//                 height: 30,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
