import 'package:coka/shared/widgets/awesome_alert.dart';
import 'package:coka/shared/widgets/loading_indicator.dart';
import 'package:coka/pages/organization/components/profile_request_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';

class InvitationPage extends ConsumerStatefulWidget {
  const InvitationPage({super.key});

  @override
  ConsumerState<InvitationPage> createState() => _InvitationPageState();
}

class _InvitationPageState extends ConsumerState<InvitationPage> with SingleTickerProviderStateMixin {
  List invList = [];
  bool isFetching = false;
  late TabController _tabController;
  String _currentType = 'INVITE'; // Theo dõi loại hiện tại
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    fetchInviteList();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentType = _tabController.index == 0 ? 'INVITE' : 'REQUEST';
      });
      fetchInviteList();
    }
  }

  Future fetchInviteList() async {
    setState(() {
      isFetching = true;
    });
    try {
      final repository = ref.read(organizationRepositoryProvider);
      
      final res = await repository.getInvitedOrganizations(
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
          "Lời mời",
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
      body: isFetching
          ? const Center(child: LoadingIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab Đã nhận - INVITE
                RefreshIndicator(
                  onRefresh: () async {
                    await fetchInviteList();
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 120,
                    ),
                    child: _currentType == 'INVITE' ? InviteList(
                      invitedList: invList,
                      onReload: () {
                        fetchInviteList();
                      },
                    ) : const Center(child: LoadingIndicator()),
                  ),
                ),
                // Tab Đã gửi - REQUEST
                RefreshIndicator(
                  onRefresh: () async {
                    await fetchInviteList();
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 120,
                    ),
                    child: _currentType == 'REQUEST' ? RequestList(
                      requestList: invList,
                      onReload: () {
                        fetchInviteList();
                      },
                    ) : const Center(child: LoadingIndicator()),
                  ),
                )
              ],
            ),
    );
  }
}

class InviteList extends StatelessWidget {
  final List invitedList;
  final Function onReload;
  const InviteList(
      {super.key, required this.invitedList, required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (invitedList.isEmpty) {
      return const Center(
        child: Text("Không có lời mời nào"),
      );
    }
    
    return ListView.builder(
      itemBuilder: (context, index) {
        return ProfileInviteItem(
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

class RequestList extends StatelessWidget {
  final List requestList;
  final Function onReload;
  const RequestList(
      {super.key, required this.requestList, required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (requestList.isEmpty) {
      return const Center(
        child: Text("Không có yêu cầu nào"),
      );
    }
    
    return ListView.builder(
      itemBuilder: (context, index) {
        return ProfileRequestItem(
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