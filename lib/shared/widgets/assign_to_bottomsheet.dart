import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pages/organization/messages/state/message_state.dart';
import '../../core/utils/helpers.dart';

class AssignToBottomSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSelected;
  final String? currentAssignedId;
  final String organizationId;
  final String workspaceId;

  const AssignToBottomSheet({
    super.key,
    required this.onSelected,
    this.currentAssignedId,
    required this.organizationId,
    required this.workspaceId,
  });

  @override
  ConsumerState<AssignToBottomSheet> createState() => _AssignToBottomSheetState();
}

class _AssignToBottomSheetState extends ConsumerState<AssignToBottomSheet>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> memberList = [];
  List<Map<String, dynamic>> teamList = [];
  List<Map<String, dynamic>> filteredMembers = [];
  List<Map<String, dynamic>> filteredTeams = [];

  bool isMemberFetching = false;
  bool isTeamFetching = false;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchMemberList(""),
      _fetchTeamList(""),
    ]);
  }

  Future<void> _fetchMemberList(String searchText) async {
    setState(() {
      isMemberFetching = true;
    });

    try {
      final messageRepo = ref.read(messageRepositoryProvider);
      final response = await messageRepo.getAssignableUsers(
        widget.organizationId,
        widget.workspaceId,
      );

      if (Helpers.isResponseSuccess(response)) {
        setState(() {
          memberList = List<Map<String, dynamic>>.from(response['content'] ?? []);
          _filterMembers(searchText);
        });
      } else {
        _showErrorSnackBar('Lỗi tải danh sách thành viên: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi tải danh sách thành viên: $e');
    } finally {
      setState(() {
        isMemberFetching = false;
      });
    }
  }

  Future<void> _fetchTeamList(String searchText) async {
    setState(() {
      isTeamFetching = true;
    });

    try {
      final messageRepo = ref.read(messageRepositoryProvider);
      final response = await messageRepo.getTeamList(
        widget.organizationId,
        widget.workspaceId,
        searchText,
        isTreeView: false,
      );

      if (Helpers.isResponseSuccess(response)) {
        setState(() {
          teamList = List<Map<String, dynamic>>.from(response['content'] ?? []);
          _filterTeams(searchText);
        });
      } else {
        _showErrorSnackBar('Lỗi tải danh sách team: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi tải danh sách team: $e');
    } finally {
      setState(() {
        isTeamFetching = false;
      });
    }
  }

  void _filterMembers(String query) {
    if (query.isEmpty) {
      filteredMembers = List.from(memberList);
    } else {
      filteredMembers = memberList.where((member) {
        final profile = member['profile'] ?? {};
        final fullName = profile['fullName']?.toString() ?? '';
        return fullName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  void _filterTeams(String query) {
    if (query.isEmpty) {
      filteredTeams = List.from(teamList);
    } else {
      filteredTeams = teamList.where((team) {
        final name = team['name']?.toString() ?? '';
        return name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filterMembers(query);
        _filterTeams(query);
      });
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Chuyển phụ trách",
                  style: TextStyle(
                    color: Color(0xFF1F2329),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEBEBEB)),

              // Tab bar
              TabBar(
                controller: tabController,
                indicatorColor: const Color(0xFF0F5ABF),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(
                    child: Text(
                      "Thành viên",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "Đội Sale",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0F5ABF)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _buildMemberTab(),
                    _buildTeamTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberTab() {
    if (isMemberFetching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredMembers.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy thành viên nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final profile = member['profile'] ?? {};
        final avatar = profile['avatar'];
        final fullName = profile['fullName'] ?? 'Không tên';
        final teamName = member['team']?['name'] ?? '';
        final isCurrentAssigned = widget.currentAssignedId == member['profileId'];

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(fullName),
          subtitle: teamName.isNotEmpty ? Text(teamName) : null,
          trailing: isCurrentAssigned
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () {
            if (!isCurrentAssigned) {
              widget.onSelected({
                "assignTo": member["profileId"],
                "teamId": member["team"]?["id"],
                "assignedName": fullName,
              });
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  Widget _buildTeamTab() {
    if (isTeamFetching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredTeams.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy team nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTeams.length,
      itemBuilder: (context, index) {
        final team = filteredTeams[index];
        final teamName = team['name'] ?? 'Không tên';
        final description = team['description'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue[300],
            child: Icon(
              Icons.group,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(teamName),
          subtitle: description.isNotEmpty ? Text(description) : null,
          onTap: () {
            widget.onSelected({
              "teamId": team["id"],
              "assignedName": teamName,
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

// Provider cho MessageRepository sẽ được import từ message_state.dart 