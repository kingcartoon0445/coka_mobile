import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../api/repositories/workspace_repository.dart';
import '../../../../api/api_client.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import 'package:go_router/go_router.dart';

class WorkspaceList extends StatefulWidget {
  final String organizationId;

  const WorkspaceList({
    super.key,
    required this.organizationId,
  });

  @override
  State<WorkspaceList> createState() => _WorkspaceListState();
}

class _WorkspaceListState extends State<WorkspaceList> {
  late final WorkspaceRepository _workspaceRepository;
  List<dynamic>? _workspaces;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _workspaceRepository = WorkspaceRepository(ApiClient());
    _fetchWorkspaces();
  }

  @override
  void didUpdateWidget(WorkspaceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      setState(() {
        _isLoading = true;
        _workspaces = null;
      });
      _fetchWorkspaces();
    }
  }

  Future<void> _fetchWorkspaces() async {
    if (widget.organizationId == 'default') {
      return;
    }
    try {
      final response =
          await _workspaceRepository.getWorkspaces(widget.organizationId);
      if (mounted) {
        setState(() {
          _workspaces = response['content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải danh sách workspace')),
        );
      }
    }
  }

  void _showAllWorkspaces() {
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
        builder: (context, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                'Không gian làm việc',
                style: TextStyles.title,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _workspaces?.length ?? 0,
                itemBuilder: (context, index) =>
                    _buildWorkspaceItem(_workspaces![index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceItem(Map<String, dynamic> workspace) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: InkWell(
        onTap: () {
          // Sử dụng go thay vì push để replace route thay vì thêm vào stack
          context.go(
              '/organization/${widget.organizationId}/workspace/${workspace['id']}/customers');
        },
        child: Row(
          children: [
            AppAvatar(
              imageUrl: workspace['image'],
              fallbackText: workspace['name'],
              size: 40,
              shape: AvatarShape.rectangle,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    workspace['name'] ?? 'Không có tên',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${workspace['totalMember']} thành viên',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 0, top: 8),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
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
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE4E7EC),
            thickness: 0.3,
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_workspaces == null || _workspaces!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có workspace nào'),
        ),
      );
    }

    final displayWorkspaces = _workspaces!.take(4).toList();
    final hasMore = _workspaces!.length > 4;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 0, top: 8),
            itemCount: displayWorkspaces.length,
            itemBuilder: (context, index) =>
                _buildWorkspaceItem(displayWorkspaces[index]),
          ),
          if (hasMore)
            Column(
              children: [
                const Divider(
                  height: 1,
                  color: Color(0xFFE4E7EC),
                  thickness: 0.3,
                ),
                InkWell(
                  onTap: _showAllWorkspaces,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(
            'Không gian làm việc',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _isLoading ? _buildShimmerLoading() : _buildContent(),
      ],
    );
  }
}
