import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../shared/widgets/search_bar.dart';
import '../../../../../shared/widgets/dropdown_button_widget.dart';
import '../../../../../models/find_child.dart';
import 'package:coka/providers/team_provider.dart';

class TeamsPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String? parentId;

  const TeamsPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    this.parentId,
  });

  @override
  ConsumerState<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends ConsumerState<TeamsPage> {
  final searchText = TextEditingController();
  List filteredTeam = [];
  Timer? _debounce;
  Map teamChild = {};
  List teamList = [];
  List leadList = [];

  @override
  void initState() {
    super.initState();
    // Sử dụng provider đúng
    Future.microtask(() {
      ref.read(teamListProvider.notifier).fetchTeamList(
          widget.organizationId, widget.workspaceId,
          isTreeView: true);
      ref.read(memberListProvider.notifier).fetchMemberList(
          widget.organizationId, widget.workspaceId, "", // Cần teamId ở đây?
          searchText: searchText.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void onTeamSearchChanged(String query) {
    if (query == "") {
      setState(() {
        filteredTeam = teamList;
      });
    }
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (query.isEmpty) {
        setState(() {
          filteredTeam = teamList;
        });
        return;
      }

      List filtered = [];
      for (var team in teamList) {
        if (team["name"].toLowerCase().contains(query.toLowerCase()) == true) {
          filtered.add(team);
        }
      }
      setState(() {
        filteredTeam = filtered;
      });
    });
  }

  void showTreeViewBottomSheet(BuildContext context) {
    // Kiểm tra danh sách team trước khi mở bottomsheet
    if (teamList.isEmpty) {
      // Không mở bottomsheet nếu không có nhánh con
      return;
    }
    
    // Lấy dữ liệu team hiện tại từ danh sách team
    final teamAsync = ref.read(teamListProvider);
    final currentTeam = teamAsync.value != null && widget.parentId != null
        ? findBranchWithParentId(teamAsync.value!, widget.parentId)
        : null;
        
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          snap: false,
          minChildSize: 0.4,
          builder: (context, controller) {
            return Theme(
              data: ThemeData(
                dividerColor: Colors.transparent,
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      widget.parentId == null ? "Đội sale" : (currentTeam != null ? currentTeam["name"] : ""),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                    const SizedBox(height: 2),
                    ...buildMultiWidgetList(
                      teamList,
                      (data) {
                                              // Chỉ navigate nếu có children
                      if (data["childs"] != null && (data["childs"] as List).isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamsPage(
                              organizationId: widget.organizationId,
                              workspaceId: widget.workspaceId,
                              parentId: data["id"],
                            ),
                          ),
                        );
                      }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Iterable<Widget> buildMultiWidgetList(List childs, Function(Map) onTap) {
    return childs.map((e) {
      return CExpansionTile(
        name: e["name"],
        id: e["id"],
        managers: e["managers"] ?? [],
        childs: e["childs"] ?? [],
        avatar: e["avatar"],
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
        onTap: () => onTap(e),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng provider đúng
    final teamListAsync = ref.watch(teamListProvider);
    final memberListAsync = ref.watch(memberListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2329),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TitleDropdownButton(
          text: widget.parentId == null
              ? "Đội sale"
              : findBranchWithParentId(teamListAsync.value ?? [],
                      widget.parentId)?["name"] ??
                  "",
          onTap: () {
            if (teamListAsync.value != null) {
              // Kiểm tra trước nếu không có dữ liệu thì không mở
              if (teamListAsync.value!.isEmpty) {
                return;
              }
              showTreeViewBottomSheet(context);
            }
          },
          isEnabled: teamListAsync.value?.isNotEmpty ?? false,
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
            child: CustomSearchBar(
              width: MediaQuery.of(context).size.width - 32,
              hintText: "Tìm kiếm",
              onQueryChanged: (value) {
                searchText.text = value;
                onTeamSearchChanged(value);
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: teamListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
              data: (allTeams) {
                if (widget.parentId == null) {
                  if (allTeams.isEmpty) {
                    return const Center(
                      child: Text('Chưa có đội sale nào'),
                    );
                  }

                  teamList = allTeams;
                  final displayList =
                      searchText.text.isEmpty ? teamList : filteredTeam;

                  return ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final team = displayList[index];
                      return ListTile(
                        leading: AppAvatar(
                          imageUrl: team['avatar'],
                          fallbackText: team['name'],
                          size: 40,
                        ),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                team['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2329),
                                ),
                              ),
                            ),
                            if (team['isAutomation'] == true)
                              Tooltip(
                                triggerMode: TooltipTriggerMode.tap,
                                waitDuration: const Duration(seconds: 4),
                                message: "Phân phối khách hàng tự động",
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3DEF7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Tự động",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          team['managers']?.isEmpty ?? true
                              ? 'Chưa có trưởng nhóm'
                              : team['managers'][0]['fullName'],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamsPage(
                                organizationId: widget.organizationId,
                                workspaceId: widget.workspaceId,
                                parentId: team["id"],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  final teamChild =
                      findBranchWithParentId(allTeams, widget.parentId);
                  if (teamChild == null) {
                    return const Center(
                        child: Text('Không tìm thấy thông tin team'));
                  }

                  teamList = teamChild["childs"] ?? [];
                  leadList = teamChild["managers"] ?? [];

                  return memberListAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Lỗi: $err')),
                    data: (members) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            if (teamList.isNotEmpty) ...[
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: teamList.length,
                                itemBuilder: (context, index) {
                                  final team = teamList[index];
                                  return ListTile(
                                    leading: AppAvatar(
                                      imageUrl: team['avatar'],
                                      fallbackText: team['name'],
                                      size: 40,
                                    ),
                                    title: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            team['name'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              overflow: TextOverflow.ellipsis,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2329),
                                            ),
                                          ),
                                        ),
                                        if (team['isAutomation'] == true)
                                          Tooltip(
                                            triggerMode: TooltipTriggerMode.tap,
                                            waitDuration:
                                                const Duration(seconds: 4),
                                            message:
                                                "Phân phối khách hàng tự động",
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE3DEF7),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                "Tự động",
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      team['managers']?.isEmpty ?? true
                                          ? 'Chưa có trưởng nhóm'
                                          : team['managers'][0]['fullName'],
                                    ),
                                    onTap: () {
                                      // Chỉ navigate nếu có children
                                      if (team["childs"] != null && (team["childs"] as List).isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeamsPage(
                                              organizationId:
                                                  widget.organizationId,
                                              workspaceId: widget.workspaceId,
                                              parentId: team["id"],
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              const Divider(),
                            ],
                            if (leadList.isNotEmpty) ...[
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: leadList.length,
                                itemBuilder: (context, index) {
                                  final leader = leadList[index];
                                  return ListTile(
                                    leading: AppAvatar(
                                      imageUrl: leader['avatar'],
                                      fallbackText: leader['fullName'],
                                      size: 40,
                                    ),
                                    title: Text(
                                      leader['fullName'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2329),
                                      ),
                                    ),
                                    subtitle: Text(
                                      leader['role'] == 'TEAM_LEADER'
                                          ? 'Trưởng nhóm'
                                          : 'Phó nhóm',
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                            ],
                            if (members.isNotEmpty)
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final profile = member['profile'];
                                  return ListTile(
                                    leading: AppAvatar(
                                      imageUrl: profile['avatar'],
                                      fallbackText: profile['fullName'],
                                      size: 40,
                                    ),
                                    title: Text(
                                      profile['fullName'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2329),
                                      ),
                                    ),
                                    subtitle: const Text('Thành viên'),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CExpansionTile extends StatefulWidget {
  final String name;
  final String? id;
  final List managers, childs;
  final Function()? onTap;
  final String? avatar;
  final String organizationId;
  final String workspaceId;

  const CExpansionTile({
    super.key,
    required this.name,
    required this.managers,
    required this.childs,
    required this.organizationId,
    required this.workspaceId,
    this.id,
    this.onTap,
    this.avatar,
  });

  @override
  State<CExpansionTile> createState() => _CExpansionTileState();
}

class _CExpansionTileState extends State<CExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: AppAvatar(
            imageUrl: widget.avatar,
            fallbackText: widget.name,
            size: 40,
          ),
          title: Text(
            widget.name,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2329),
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            widget.managers.isEmpty
                ? "Chưa có trưởng nhóm"
                : widget.managers[0]["fullName"],
            style: const TextStyle(fontSize: 12, color: Color(0xFF646A72)),
          ),
          trailing: widget.childs.isEmpty
              ? null
              : Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF646A72),
                ),
          onTap: () {
            if (widget.childs.isEmpty) {
              // Không navigate tới team detail cho nhánh cuối
              return;
            } else {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          },
        ),
        if (_isExpanded && widget.childs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Column(
              children: widget.childs
                  .map((child) => CExpansionTile(
                        name: child["name"],
                        id: child["id"],
                        managers: child["managers"] ?? [],
                        childs: child["childs"] ?? [],
                        avatar: child["avatar"],
                        organizationId: widget.organizationId,
                        workspaceId: widget.workspaceId,
                        onTap: () {
                          // Chỉ navigate nếu có children
                          if (child["childs"] != null && (child["childs"] as List).isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamsPage(
                                  organizationId: widget.organizationId,
                                  workspaceId: widget.workspaceId,
                                  parentId: child["id"],
                                ),
                              ),
                            );
                          }
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
