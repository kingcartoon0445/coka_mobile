import 'package:flutter/material.dart';
import 'dart:async';
import 'package:coka/api/repositories/team_repository.dart';
import 'package:coka/api/api_client.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../../shared/widgets/skeleton_widget.dart';

class AssigneeData {
  final String id;
  final String name;
  final String? avatar;
  final bool isTeam;

  AssigneeData({
    required this.id,
    required this.name,
    this.avatar,
    this.isTeam = false,
  });
}

class AssigneeSelectionDialog extends StatefulWidget {
  final String organizationId;
  final String workspaceId;
  final List<AssigneeData> initialValue;

  const AssigneeSelectionDialog({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.initialValue,
  });

  static Future<List<AssigneeData>?> show(
    BuildContext context,
    String organizationId,
    String workspaceId,
    List<AssigneeData> initialValue,
  ) {
    return showDialog<List<AssigneeData>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssigneeSelectionDialog(
        organizationId: organizationId,
        workspaceId: workspaceId,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<AssigneeSelectionDialog> createState() =>
      _AssigneeSelectionDialogState();
}

class _AssigneeSelectionDialogState extends State<AssigneeSelectionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _memberSearchController = TextEditingController();
  final TextEditingController _teamSearchController = TextEditingController();
  final TeamRepository _teamRepository = TeamRepository(ApiClient());
  List<AssigneeData> _selectedAssignees = [];
  List<AssigneeData> _members = [];
  List<AssigneeData> _teams = [];
  bool _isLoadingMembers = true;
  bool _isLoadingTeams = true;
  String _memberSearchText = '';
  String _teamSearchText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedAssignees = List.from(widget.initialValue);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberSearchController.dispose();
    _teamSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMembers(),
      _loadTeams(),
    ]);
  }

  Future<void> _loadMembers() async {
    try {
      final response = await _teamRepository.getTeamMemberList(
        widget.organizationId,
        widget.workspaceId,
        searchText: _memberSearchText.isNotEmpty ? _memberSearchText : null,
      );

      if (mounted) {
        setState(() {
          _members = (response['content'] as List).map((member) {
            final profile = member['profile'];
            return AssigneeData(
              id: profile['id'],
              name: profile['fullName'],
              avatar: profile['avatar'],
              isTeam: false,
            );
          }).toList();
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải danh sách thành viên')),
        );
      }
    }
  }

  Future<void> _loadTeams() async {
    try {
      final response = await _teamRepository.getTeamList(
        widget.organizationId,
        widget.workspaceId,
      );

      if (mounted) {
        final allTeams = (response['content'] as List).map((team) {
          return AssigneeData(
            id: team['id'],
            name: team['name'],
            isTeam: true,
          );
        }).toList();

        setState(() {
          if (_teamSearchText.isEmpty) {
            _teams = allTeams;
          } else {
            _teams = allTeams
                .where((team) => team.name
                    .toLowerCase()
                    .contains(_teamSearchText.toLowerCase()))
                .toList();
          }
          _isLoadingTeams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeams = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi tải danh sách đội')),
        );
      }
    }
  }

  void _toggleAssignee(AssigneeData assignee) {
    setState(() {
      if (_selectedAssignees.any((item) => item.id == assignee.id)) {
        _selectedAssignees.removeWhere((item) => item.id == assignee.id);
      } else {
        _selectedAssignees.add(assignee);
      }
    });
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 44,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          constraints: const BoxConstraints(maxHeight: 40),
          hintText: 'Tìm kiếm',
          hintStyle: const TextStyle(fontSize: 14),
          prefixIconConstraints: const BoxConstraints(maxHeight: 40),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.search, size: 20),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListItem(AssigneeData assignee) {
    final isSelected = _selectedAssignees.any((item) => item.id == assignee.id);
    return ListTile(
      leading: AppAvatar(
        size: 40,
        shape: AvatarShape.circle,
        imageUrl: assignee.avatar,
        fallbackText: assignee.name,
      ),
      title: Text(
        assignee.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF101828),
        ),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) => _toggleAssignee(assignee),
        activeColor: AppColors.primary,
      ),
      onTap: () => _toggleAssignee(assignee),
    );
  }

  Widget _buildMembersList() {
    return Column(
      children: [
        _buildSearchBar(
          controller: _memberSearchController,
          onChanged: (value) {
            setState(() {
              _memberSearchText = value;
            });
            _loadMembers();
          },
        ),
        Expanded(
          child: _isLoadingMembers
              ? const AssigneeListSkeleton()
              : _members.isEmpty
                  ? const Center(
                      child: Text('Không tìm thấy thành viên nào'),
                    )
                  : ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (context, index) =>
                          _buildListItem(_members[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildTeamsList() {
    return Column(
      children: [
        _buildSearchBar(
          controller: _teamSearchController,
          onChanged: (value) {
            setState(() {
              _teamSearchText = value;
            });
            _loadTeams();
          },
        ),
        Expanded(
          child: _isLoadingTeams
              ? const AssigneeListSkeleton()
              : _teams.isEmpty
                  ? const Center(
                      child: Text('Không tìm thấy đội nào'),
                    )
                  : ListView.builder(
                      itemCount: _teams.length,
                      itemBuilder: (context, index) =>
                          _buildListItem(_teams[index]),
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn đối tượng phụ trách',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF667085),
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Thành viên'),
                Tab(text: 'Đội sale'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersList(),
                  _buildTeamsList(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEAECF0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Huỷ'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop(_selectedAssignees);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
