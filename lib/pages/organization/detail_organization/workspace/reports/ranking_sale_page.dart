import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';

class RankingSalePage extends ConsumerStatefulWidget {
  final List userList;

  const RankingSalePage({super.key, required this.userList});

  @override
  ConsumerState<RankingSalePage> createState() => _RankingSalePageState();
}

class _RankingSalePageState extends ConsumerState<RankingSalePage> {
  CustomSearchController searchController = CustomSearchController();
  late StreamSubscription<bool> keyboardSubscription;
  Map? currentUser = {};
  List hintUserList = [];
  var filteredUser = [];
  Timer? _debounce;
  bool isDismiss = true;
  Map hintPrefsData = {};
  String? currentUserId;

  Future<void> getHintCustomer() async {
    searchController.clear();

    // Giả lập việc lấy dữ liệu từ SharedPreferences
    hintPrefsData = {};

    // Lấy workGroupId từ provider hoặc từ nguồn khác
    const workGroupId = "default"; // Thay thế bằng ID thực tế

    setState(() {
      hintUserList = hintPrefsData[workGroupId] ?? [];
    });
  }

  @override
  void initState() {
    super.initState();
    getHintCustomer();

    // Lấy ID người dùng hiện tại từ provider hoặc từ nguồn khác
    currentUserId = "current_user_id"; // Thay thế bằng ID thực tế

    try {
      currentUser = widget.userList
          .firstWhere((element) => element["assignTo"] == currentUserId);
    } catch (e) {
      debugPrint("Không tìm thấy người dùng hiện tại: $e");
    }

    filteredUser = widget.userList;

    // Giả lập việc lắng nghe sự kiện bàn phím
    keyboardSubscription =
        Stream<bool>.periodic(const Duration(days: 1), (count) => false)
            .listen((visible) {
      // Xử lý khi bàn phím ẩn
      if (!visible) {
        if (searchController.text.isNotEmpty) {
          if (hintUserList.contains(searchController.text)) {
            hintUserList.remove(searchController.text);
          }
          if (hintUserList.length > 4) {
            hintUserList.removeLast();
          }
          hintUserList.insert(0, searchController.text);

          // Lấy workGroupId từ provider hoặc từ nguồn khác
          const workGroupId = "default"; // Thay thế bằng ID thực tế

          hintPrefsData[workGroupId] = hintUserList;
        }
        if (isDismiss && searchController.isOpen) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  void onTeamSearchChanged() {
    if (searchController.text == "") {
      setState(() {
        filteredUser = widget.userList;
      });
    }
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (searchController.text.isEmpty) {
        // show all contacts when the search query is empty
        filteredUser = widget.userList;
        return;
      }

      // filter the list of contacts based on the search query
      List filtered = [];
      for (var user in widget.userList) {
        if (user["fullName"]
                .toLowerCase()
                .contains(searchController.text.toLowerCase()) ==
            true) {
          filtered.add(user);
        }
      }
      setState(() {
        filteredUser = filtered;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Bảng xếp hạng sale",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          CustomSearchAnchor(
              builder: (BuildContext context, controller) {
                return IconButton(
                  icon: Badge(
                    isLabelVisible: controller.text.isNotEmpty,
                    child: Icon(Icons.search,
                        color: controller.text.isNotEmpty
                            ? const Color(0xFF5C33F0)
                            : null),
                  ),
                  onPressed: () {
                    controller.openView();
                  },
                );
              },
              searchController: searchController,
              onTextChanged: (p0) {
                if (p0.isEmpty) {
                  setState(() {
                    filteredUser = widget.userList;
                  });
                } else {
                  onTeamSearchChanged();
                }
              },
              isFullScreen: false,
              viewConstraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: hintUserList.length > 3
                      ? 300.0
                      : hintUserList.isEmpty
                          ? 112
                          : 57 + 62.0 * hintUserList.length,
                  maxWidth: double.infinity,
                  minWidth: double.infinity),
              suggestionsBuilder:
                  (BuildContext context, CustomSearchController sController) {
                return hintUserList.map((e) {
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(e),
                    onTap: () {
                      isDismiss = false;
                      searchController.closeView(e);
                      onTeamSearchChanged();

                      Timer(
                        const Duration(milliseconds: 300),
                        () {
                          isDismiss = true;
                        },
                      );
                    },
                  );
                }).toList();
              })
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (currentUser != null && currentUser!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE3DFFF),
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Vị trí của bạn",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Text(
                              currentUser!["index"].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            AppAvatar(
                              imageUrl: currentUser?["avatar"],
                              size: 40,
                              fallbackText: currentUser?["fullName"] ?? "",
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser?["fullName"] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      currentUser!["total"].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF554FE8),
                                          fontSize: 11),
                                    ),
                                    const Text(
                                      " Khách hàng",
                                      style: TextStyle(
                                          color: Color(0xFF554FE8),
                                          fontSize: 11),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.circle,
                                        size: 3,
                                      ),
                                    ),
                                    Text(
                                      currentUser!["potential"].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF554FE8),
                                          fontSize: 11),
                                    ),
                                    const Text(
                                      " Tiềm năng",
                                      style: TextStyle(
                                          color: Color(0xFF554FE8),
                                          fontSize: 11),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const Spacer(),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "0 tỷ",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF554FE8)),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  "0 Giao dịch",
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF554FE8)),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ...filteredUser.map((userData) {
              return Container(
                padding: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        userData["index"].toString(),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    AppAvatar(
                      imageUrl: userData?["avatar"],
                      size: 40,
                      fallbackText: userData?["fullName"] ?? "",
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData?["fullName"] ?? "T",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Row(
                          children: [
                            Text(
                              userData["total"].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF29315F),
                                  fontSize: 11),
                            ),
                            const Text(
                              " Khách hàng",
                              style: TextStyle(
                                  color: Color(0xFF29315F), fontSize: 11),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.circle,
                                size: 3,
                              ),
                            ),
                            Text(
                              userData["potential"].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF29315F),
                                  fontSize: 11),
                            ),
                            const Text(
                              " Tiềm năng",
                              style: TextStyle(
                                  color: Color(0xFF29315F), fontSize: 11),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Spacer(),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "0 tỷ",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2329)),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          "0 Giao dịch",
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF29315F)),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }),
            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }
}

// Placeholder cho CustomSearchAnchor và CustomSearchController
// Cần thay thế bằng implementation thực tế
class CustomSearchAnchor extends StatelessWidget {
  final Widget Function(BuildContext, CustomSearchController) builder;
  final CustomSearchController searchController;
  final Function(String) onTextChanged;
  final bool isFullScreen;
  final BoxConstraints viewConstraints;
  final List<Widget> Function(BuildContext, CustomSearchController)
      suggestionsBuilder;

  const CustomSearchAnchor({
    super.key,
    required this.builder,
    required this.searchController,
    required this.onTextChanged,
    required this.isFullScreen,
    required this.viewConstraints,
    required this.suggestionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, searchController);
  }
}

class CustomSearchController {
  String text = '';
  bool isOpen = false;

  void openView() {
    isOpen = true;
  }

  void closeView(String text) {
    this.text = text;
    isOpen = false;
  }

  void clear() {
    text = '';
  }
}

// Placeholder cho Badge
class Badge extends StatelessWidget {
  final Widget child;
  final bool isLabelVisible;

  const Badge({
    super.key,
    required this.child,
    this.isLabelVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (isLabelVisible)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// Placeholder cho userProvider
final userProvider = Provider<User?>((ref) => null);

// Placeholder cho User model
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}
