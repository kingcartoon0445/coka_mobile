import 'package:flutter/material.dart';
import '../../../shared/widgets/notification_list_widget.dart';
import '../../../shared/widgets/elevated_btn.dart';
import '../../../api/repositories/notification_repository.dart';
import '../../../shared/widgets/loading_dialog.dart';
import '../../../api/api_client.dart';

class NotificationsPage extends StatefulWidget {
  final String organizationId;

  const NotificationsPage({
    super.key,
    required this.organizationId,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _notificationRepository;

  @override
  void initState() {
    super.initState();
    _notificationRepository = NotificationRepository(ApiClient());
  }

  Future<void> _markAllAsRead() async {
    try {
      showLoadingDialog(context);
      await _notificationRepository.setAllNotificationsRead();
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() {}); // Refresh the page
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi đánh dấu đã đọc tất cả thông báo'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          MenuAnchor(
            alignmentOffset: const Offset(-225, 0),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.check_rounded),
                onPressed: _markAllAsRead,
                child: const Text('Đánh dấu tất cả là đã đọc'),
              ),
            ],
            builder: (context, controller, child) {
              return ElevatedBtn(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                circular: 50,
                paddingAllValue: 4,
                child: const Icon(
                  Icons.more_vert,
                  size: 30,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotificationListWidget(
        organizationId: widget.organizationId,
        showTitle: false,
        showMoreOption: false,
        fullScreen: true,
        onMarkAsRead: (id) {
          // Chỉ làm mới state khi cần
          setState(() {});
        },
      ),
    );
  }
} 