import 'package:flutter/material.dart';
import '../../../../shared/widgets/notification_list_widget.dart';

class NotificationList extends StatelessWidget {
  final String organizationId;

  const NotificationList({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListWidget(
      organizationId: organizationId,
      maxItems: 5,
    );
  }
}
