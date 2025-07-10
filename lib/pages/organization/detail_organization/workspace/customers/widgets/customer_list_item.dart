import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/helpers.dart';
import '../../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../../shared/widgets/custom_alert_dialog.dart';
import '../../../../../../shared/widgets/context_menu.dart';
import '../../../../../../providers/customer_provider.dart';
import '../customer_detail/widgets/assign_to_bottomsheet.dart';

class CustomerListItem extends ConsumerWidget {
  final Map<String, dynamic> customer;
  final String organizationId;
  final String workspaceId;

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.organizationId,
    required this.workspaceId,
  });

  Widget _buildAssigneeInfo() {
    final assignToUser = customer['assignToUser'];
    final assignToUsers = customer['assignToUsers'] as List<dynamic>?;
    final teamResponse = customer['teamResponse'];

    // Trường hợp có nhiều người phụ trách
    final hasAssignToUsers = assignToUsers != null && assignToUsers.isNotEmpty;
    
    if (hasAssignToUsers) {
      final displayUsers = assignToUsers.take(3).toList();
      final stackWidth = 20.0 + (displayUsers.length > 1 ? (displayUsers.length - 1) * 12.0 : 0);
      
      return Row(
        children: [
          // Hiển thị avatar chồng lên nhau (tối đa 3 avatar)
          SizedBox(
            width: stackWidth,
            height: 20,
            child: Stack(
              clipBehavior: Clip.none,
              children: displayUsers.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                return Positioned(
                  left: index * 10.0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: AppAvatar(
                        size: 17,
                        shape: AvatarShape.circle,
                        imageUrl: user['avatar'],
                        fallbackText: user['fullName'],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          if (assignToUsers.length > 3)
            Text(
              '+${assignToUsers.length - 3}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF828489),
              ),
            ),
        ],
      );
    }
    
    // Trường hợp có một người phụ trách duy nhất
    if (assignToUser != null) {
      return Row(
        children: [
          AppAvatar(
            size: 16,
            shape: AvatarShape.circle,
            imageUrl: assignToUser['avatar'],
            fallbackText: assignToUser['fullName'],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              assignToUser['fullName'] ?? '',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF828489),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    
    // Trường hợp có team phụ trách
    if (teamResponse != null && teamResponse['name'] != null) {
      return Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.group,
              size: 10,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              teamResponse['name'],
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF828489),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    
    // Trường hợp chưa phân công
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.person_outline,
            size: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Chưa phân công',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF828489),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, RenderBox itemBox) {
    final items = [
      ContextMenuItem(
        icon: Icons.swap_horiz,
        title: 'Chuyển phụ trách',
        onTap: () {
          Future.delayed(
            const Duration(milliseconds: 100),
            () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              builder: (context) => AssignToBottomSheet(
                organizationId: organizationId,
                workspaceId: workspaceId,
                customerId: customer['id'],
                defaultAssignees: customer['assignToUsers'] != null 
                    ? List<Map<String, dynamic>>.from(customer['assignToUsers']) 
                    : [],
                onSelected: (selectedUser) {
                  // Callback được xử lý trong bottomsheet
                },
              ),
            ),
          );
        },
      ),
      ContextMenuItem(
        icon: Icons.edit_outlined,
        title: 'Chỉnh sửa khách hàng',
        onTap: () {
          Future.delayed(
            const Duration(milliseconds: 100),
            () => context.push(
              '/organization/$organizationId/workspace/$workspaceId/customers/${customer['id']}/edit',
              extra: customer,
            ),
          );
        },
      ),
      ContextMenuItem(
        icon: Icons.delete_outline,
        title: 'Xóa khách hàng',
        iconColor: Colors.red,
        textColor: Colors.red,
        onTap: () {
          Future.delayed(
            const Duration(milliseconds: 100),
            () => showDialog(
              context: context,
              builder: (context) => CustomAlertDialog(
                title: 'Xóa khách hàng?',
                subtitle: 'Bạn có chắc muốn xóa khách hàng "${customer['fullName']}"? Hành động này không thể hoàn tác.',
                onSubmit: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(customerDetailProvider(customer['id']).notifier)
                        .deleteCustomer(organizationId, workspaceId);
                    
                    // Trigger refresh cho customers list
                    ref.read(customerListRefreshProvider.notifier).notifyCustomerListChanged();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã xóa khách hàng "${customer['fullName']}" thành công')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Có lỗi xảy ra: $e')),
                      );
                    }
                  }
                },
                onCancel: () => Navigator.pop(context),
              ),
            ),
          );
        },
      ),
    ];

    ContextMenu.show(
      context: context,
      itemBox: itemBox,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = customer['stage'];
    final createdDate = DateTime.parse(customer['createdDate']);
    final timeAgo = timeago.format(createdDate, locale: 'vi');
    final isNewStage = stage?['name'] == 'Mới';

    return Builder(
      builder: (BuildContext context) {
        return InkWell(
          onTap: () {
            context.push(
              '/organization/$organizationId/workspace/$workspaceId/customers/${customer['id']}',
            );
          },
          onLongPress: () {
            // Debug message
            print('Long press detected on customer: ${customer['fullName']}');
            
            // Thêm haptic feedback
            HapticFeedback.mediumImpact();
            
            // Lấy RenderBox của item hiện tại
            final RenderBox itemBox = context.findRenderObject() as RenderBox;
            _showContextMenu(context, ref, itemBox);
          },
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(
                  size: 48,
                  shape: AvatarShape.circle,
                  imageUrl: customer['avatar'],
                  fallbackText: customer['fullName'],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer['fullName'] ?? 'Không có tên',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isNewStage ? FontWeight.w500 : FontWeight.w400,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF828489),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (stage != null)
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Helpers.getTabBadgeColor(
                                  Helpers.getStageGroupName(stage['id']) ?? '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stage['name'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    isNewStage ? FontWeight.w500 : FontWeight.w400,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAssigneeInfo(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 