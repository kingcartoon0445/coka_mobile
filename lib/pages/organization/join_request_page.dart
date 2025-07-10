import 'dart:async';

import 'package:flutter/material.dart';
import 'package:coka/shared/widgets/awesome_alert.dart';
import 'package:coka/shared/widgets/loading_indicator.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';
import 'package:coka/shared/widgets/search_bar.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';
import 'package:coka/api/api_client.dart';

class JoinRequestPage extends ConsumerStatefulWidget {
  final String? organizationId;
  
  const JoinRequestPage({super.key, this.organizationId});

  @override
  ConsumerState<JoinRequestPage> createState() => _JoinRequestPageState();
}

class _JoinRequestPageState extends ConsumerState<JoinRequestPage> with SingleTickerProviderStateMixin {
  List invList = [];
  bool isFetching = false;
  late TabController _tabController;
  String _currentType = 'REQUEST'; // Theo dõi loại hiện tại
  Timer? _debounce;
  TextEditingController searchController = TextEditingController();
  String? _organizationId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadOrganizationId();
  }
  
  Future<void> _loadOrganizationId() async {
    String? orgId = widget.organizationId;
    
    // Nếu không có organizationId từ tham số, lấy từ storage
    if (orgId == null || orgId.isEmpty) {
      orgId = await ApiClient.storage.read(key: 'default_organization_id');
    }
    
    setState(() {
      _organizationId = orgId;
    });
    
    fetchInviteList('');
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentType = _tabController.index == 0 ? 'REQUEST' : 'INVITE';
      });
      fetchInviteList('');
    }
  }

  void onDebounce(Function(String) searchFunction, int debounceTime) {
    // Hủy bỏ bất kỳ timer nào nếu có
    _debounce?.cancel();

    // Tạo mới timer với thời gian debounce
    _debounce = Timer(Duration(milliseconds: debounceTime), () {
      // Lấy dữ liệu từ trường văn bản và gọi hàm tìm kiếm
      searchFunction(searchController.text);
    });
  }

  Future fetchInviteList(String searchText) async {
    // Kiểm tra xem có organizationId không
    if (_organizationId == null || _organizationId!.isEmpty) {
      showAwesomeAlert(
        context: context,
        title: "Thông báo",
        description: "Vui lòng chọn tổ chức trước khi xem các yêu cầu",
        confirmText: "Đóng",
        icon: Icons.info_outline,
        isWarning: true,
      );
      return;
    }
    
    setState(() {
      isFetching = true;
    });
    
    try {
      final repository = ref.read(organizationRepositoryProvider);
      
      if (_currentType == 'REQUEST') {
        // Lấy các yêu cầu đã nhận
        final res = await repository.getOrganizationRequests(
          _organizationId!,
          type: _currentType,
        );
        
        setState(() {
          isFetching = false;
          if (res["code"] == 0) {
            invList = res["content"] ?? [];
          } else {
            showAwesomeAlert(
              context: context,
              title: "Thất bại",
              description: res["message"] ?? "Có lỗi xảy ra khi tải dữ liệu",
              confirmText: "Đóng",
              icon: Icons.error_outline,
              isWarning: true,
              iconColor: const Color(0xFFFFE9E9),
            );
          }
        });
      } else {
        // Lấy các yêu cầu đã gửi
        final res = await repository.getInvitedOrganizations(
          type: 'REQUEST',
        );
        
        setState(() {
          isFetching = false;
          if (res["code"] == 0) {
            invList = res["content"] ?? [];
          } else {
            showAwesomeAlert(
              context: context,
              title: "Thất bại",
              description: res["message"] ?? "Có lỗi xảy ra khi tải dữ liệu",
              confirmText: "Đóng",
              icon: Icons.error_outline,
              isWarning: true,
              iconColor: const Color(0xFFFFE9E9),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        isFetching = false;
      });
      showAwesomeAlert(
        context: context,
        title: "Thất bại",
        description: "Có lỗi xảy ra khi tải dữ liệu",
        confirmText: "Đóng",
        icon: Icons.error_outline,
        isWarning: true,
        iconColor: const Color(0xFFFFE9E9),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Yêu cầu gia nhập",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2329)),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              child: Text("Đã nhận",
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            Tab(
              child: Text("Đã gửi",
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: CustomSearchBar(
              width: double.infinity,
              hintText: "Tìm kiếm...",
              onQueryChanged: (value) {
                onDebounce((v) {
                  fetchInviteList(value);
                }, 800);
              },
            ),
          ),
          Expanded(
            child: isFetching
                ? const Center(child: LoadingIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Đã nhận - REQUEST
                      RefreshIndicator(
                        onRefresh: () async {
                          await fetchInviteList('');
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 180,
                          ),
                          child: _currentType == 'REQUEST' ? RequestList(
                            requestList: invList,
                            onReload: () {
                              fetchInviteList('');
                            },
                          ) : const Center(child: LoadingIndicator()),
                        ),
                      ),
                      // Tab Đã gửi - INVITE
                      RefreshIndicator(
                        onRefresh: () async {
                          await fetchInviteList('');
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 180,
                          ),
                          child: _currentType == 'INVITE' ? InviteList(
                            invitedList: invList,
                            onReload: () {
                              fetchInviteList('');
                            },
                          ) : const Center(child: LoadingIndicator()),
                        ),
                      )
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class RequestList extends StatelessWidget {
  final List requestList;
  final Function onReload;

  const RequestList({
    super.key, 
    required this.requestList, 
    required this.onReload
  });

  @override
  Widget build(BuildContext context) {
    if (requestList.isEmpty) {
      return const Center(
        child: Text("Không có yêu cầu nào",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    
    return ListView.builder(
      itemBuilder: (context, index) {
        return OrgRequestItem(
          dataItem: requestList[index],
          onReload: onReload,
        );
      },
      itemCount: requestList.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
    );
  }
}

class InviteList extends StatelessWidget {
  final List invitedList;
  final Function onReload;
  
  const InviteList({
    super.key, 
    required this.invitedList, 
    required this.onReload
  });

  @override
  Widget build(BuildContext context) {
    if (invitedList.isEmpty) {
      return const Center(
        child: Text("Không có lời mời nào",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    
    return ListView.builder(
      itemBuilder: (context, index) {
        return OrgInviteItem(
          dataItem: invitedList[index],
          onReload: onReload,
        );
      },
      itemCount: invitedList.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
    );
  }
}

class OrgRequestItem extends ConsumerWidget {
  final Map<String, dynamic> dataItem;
  final Function onReload;

  const OrgRequestItem({
    super.key,
    required this.dataItem,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        leading: AppAvatar(
          size: 36,
          shape: AvatarShape.circle,
          imageUrl: dataItem['profile']['avatar'],
          fallbackText: dataItem['profile']['fullName'],
        ),
        title: Text(
          dataItem['profile']['fullName'] ?? '',
          style: TextStyles.heading3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          dataItem['profile']['email'] ?? "Không có email",
          style: TextStyles.subtitle1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () => _acceptRequest(context, ref, true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: Size.zero,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Đồng ý',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () => _acceptRequest(context, ref, false),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: Size.zero,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'Từ chối',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRequest(BuildContext context, WidgetRef ref, bool isAccept) {
    final action = isAccept ? 'đồng ý' : 'từ chối';
    final successMessage = isAccept ? 'Đã chấp nhận yêu cầu tham gia' : 'Đã từ chối yêu cầu tham gia';
    
    showAwesomeAlert(
      context: context,
      title: 'Xác nhận',
      description: 'Bạn có chắc muốn $action yêu cầu này?',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      isWarning: true,
      icon: Icons.help_outline,
      onConfirm: () async {
        try {
          final repository = ref.read(organizationRepositoryProvider);
          final result = await repository.acceptOrRejectJoinRequest(
            dataItem['organizationId'],
            dataItem['id'],
            isAccept,
          );
          
          if (result['code'] == 0) {
            showAwesomeAlert(
              context: context,
              title: 'Thành công',
              description: successMessage,
              confirmText: 'Đóng',
              icon: Icons.check_circle_outline,
            );
            onReload();
          } else {
            showAwesomeAlert(
              context: context,
              title: 'Thất bại',
              description: result['message'] ?? 'Có lỗi xảy ra',
              confirmText: 'Đóng',
              icon: Icons.error_outline,
              isWarning: true,
              iconColor: const Color(0xFFFFE9E9),
            );
          }
        } catch (e) {
          showAwesomeAlert(
            context: context,
            title: 'Thất bại',
            description: 'Có lỗi xảy ra',
            confirmText: 'Đóng',
            icon: Icons.error_outline,
            isWarning: true,
            iconColor: const Color(0xFFFFE9E9),
          );
        }
      },
    );
  }
}

class OrgInviteItem extends ConsumerWidget {
  final Map<String, dynamic> dataItem;
  final Function onReload;

  const OrgInviteItem({
    super.key,
    required this.dataItem,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        leading: AppAvatar(
          size: 36,
          shape: AvatarShape.circle,
          imageUrl: dataItem['organization']?['avatar'],
          fallbackText: dataItem['organization']?['name'],
        ),
        title: Text(
          dataItem['organization']?['name'] ?? '',
          style: TextStyles.heading3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          dataItem['organization']?['subscription'] == 'PERSONAL' ? 'Cá nhân' : 'Doanh nghiệp',
          style: TextStyles.subtitle1,
        ),
        trailing: SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: () => _cancelInvitation(context, ref),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: Size.zero,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cancelInvitation(BuildContext context, WidgetRef ref) {
    showAwesomeAlert(
      context: context,
      title: 'Xác nhận',
      description: 'Bạn có chắc muốn hủy yêu cầu này?',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      isWarning: true,
      icon: Icons.help_outline,
      onConfirm: () async {
        try {
          final repository = ref.read(organizationRepositoryProvider);
          final result = await repository.cancelJoinRequest(dataItem['id']);
          
          if (result['code'] == 0) {
            showAwesomeAlert(
              context: context,
              title: 'Thành công',
              description: 'Đã hủy yêu cầu thành công',
              confirmText: 'Đóng',
              icon: Icons.check_circle_outline,
            );
            onReload();
          } else {
            showAwesomeAlert(
              context: context,
              title: 'Thất bại',
              description: result['message'] ?? 'Có lỗi xảy ra',
              confirmText: 'Đóng',
              icon: Icons.error_outline,
              isWarning: true,
              iconColor: const Color(0xFFFFE9E9),
            );
          }
        } catch (e) {
          showAwesomeAlert(
            context: context,
            title: 'Thất bại',
            description: 'Có lỗi xảy ra',
            confirmText: 'Đóng',
            icon: Icons.error_outline,
            isWarning: true,
            iconColor: const Color(0xFFFFE9E9),
          );
        }
      },
    );
  }
} 