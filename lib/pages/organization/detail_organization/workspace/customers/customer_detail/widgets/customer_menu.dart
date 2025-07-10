import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../providers/customer_provider.dart';
import 'assign_to_bottomsheet.dart';

class CustomerMenu extends ConsumerWidget {
  final Map<String, dynamic> customerDetail;

  const CustomerMenu({
    super.key,
    required this.customerDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = GoRouterState.of(context).pathParameters;
    final organizationId = params['organizationId']!;
    final workspaceId = params['workspaceId']!;

    return PopupMenuButton<String>(
      offset: const Offset(-160, 0),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.person_add_alt, size: 25),
              Gap(8),
              Text('Chuyển phụ trách'),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 100),
              () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AssignToBottomSheet(
                  organizationId: organizationId,
                  workspaceId: workspaceId,
                  customerId: customerDetail['id'],
                  defaultAssignees: customerDetail['assignToUsers'] != null 
                      ? List<Map<String, dynamic>>.from(customerDetail['assignToUsers']) 
                      : [],
                  onSelected: (selectedUser) {
                    // Callback này không còn được sử dụng vì đã xử lý trực tiếp trong bottomsheet
                  },
                ),
              ),
            );
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.edit, size: 25),
              Gap(8),
              Text('Chỉnh sửa thông tin'),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 100),
              () => context.push(
                '/organization/$organizationId/workspace/$workspaceId/customers/${customerDetail['id']}/edit',
                extra: customerDetail,
              ),
            );
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 25),
              Gap(8),
              Text(
                'Xóa khách hàng',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 100),
              () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa khách hàng?'),
                  content: const Text('Bạn có chắc muốn xóa khách hàng này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(customerDetailProvider(customerDetail['id'])
                                  .notifier)
                              .deleteCustomer(
                                organizationId,
                                workspaceId,
                              );
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            context.pop(); // Go back to customer list
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Có lỗi xảy ra khi xóa khách hàng')),
                            );
                          }
                        }
                      },
                      child: const Text('Xóa',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
