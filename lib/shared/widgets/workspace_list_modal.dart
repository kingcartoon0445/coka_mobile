import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../api/repositories/workspace_repository.dart';
import '../../api/api_client.dart';
import 'avatar_widget.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';

class SkeletonWorkspaceItem extends StatelessWidget {
  final bool showAvatar;
  final bool showMemberCount;
  final bool showContactCount;

  const SkeletonWorkspaceItem({
    super.key,
    this.showAvatar = false,
    this.showMemberCount = false,
    this.showContactCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (showAvatar) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 150,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (showMemberCount) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showContactCount)
              Container(
                width: 30,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceListModal extends StatefulWidget {
  final String organizationId;
  final String? currentWorkspaceId;
  final Function(Map<String, dynamic>)? onWorkspaceSelected;
  final bool showAvatar;
  final bool showMemberCount;
  final bool showContactCount;

  const WorkspaceListModal({
    super.key,
    required this.organizationId,
    this.currentWorkspaceId,
    this.onWorkspaceSelected,
    this.showAvatar = false,
    this.showMemberCount = false,
    this.showContactCount = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String organizationId,
    String? currentWorkspaceId,
    Function(Map<String, dynamic>)? onWorkspaceSelected,
    bool showAvatar = false,
    bool showMemberCount = false,
    bool showContactCount = false,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => WorkspaceListModal(
          organizationId: organizationId,
          currentWorkspaceId: currentWorkspaceId,
          onWorkspaceSelected: onWorkspaceSelected,
          showAvatar: showAvatar,
          showMemberCount: showMemberCount,
          showContactCount: showContactCount,
        ),
      ),
    );
  }

  @override
  State<WorkspaceListModal> createState() => _WorkspaceListModalState();
}

class _WorkspaceListModalState extends State<WorkspaceListModal> {
  List<dynamic>? _workspaces;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
  }

  Future<void> _loadWorkspaces() async {
    final workspaceRepository = WorkspaceRepository(ApiClient());
    try {
      final response =
          await workspaceRepository.getWorkspaces(widget.organizationId);
      if (mounted) {
        setState(() {
          _workspaces = response['content'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error fetching workspaces: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải danh sách workspace')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildWorkspaceItem(Map<String, dynamic> workspace) {
    final bool isSelected = workspace['id'] == widget.currentWorkspaceId;
    developer.log(
        'Building workspace item: ${workspace['name']}, isSelected: $isSelected');

    return InkWell(
      onTap: () {
        developer.log('Workspace selected: ${workspace['name']}');
        context.pop();
        if (widget.onWorkspaceSelected != null) {
          widget.onWorkspaceSelected!(workspace);
        } else if (!isSelected) {
          context.go(
              '/organization/${widget.organizationId}/workspace/${workspace['id']}/customers');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (widget.showAvatar) ...[
              AppAvatar(
                size: 36,
                fallbackText: workspace['name'],
                shape: AvatarShape.circle,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    workspace['name'] ?? 'Không có tên',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.text,
                    ),
                  ),
                  if (widget.showMemberCount) ...[
                    const SizedBox(height: 1),
                    Text(
                      '${workspace['totalMember']} thành viên',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.showContactCount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${workspace['totalContact']}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Chọn không gian làm việc',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => SkeletonWorkspaceItem(
                    showAvatar: widget.showAvatar,
                    showMemberCount: widget.showMemberCount,
                    showContactCount: widget.showContactCount,
                  ),
                )
              : ListView.builder(
                  itemCount: _workspaces?.length ?? 0,
                  itemBuilder: (context, index) => _buildWorkspaceItem(
                    _workspaces![index],
                  ),
                ),
        ),
      ],
    );
  }
}
