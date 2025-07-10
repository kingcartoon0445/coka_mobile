import 'package:flutter/material.dart';
import '../../../../../models/automation/automation_config.dart';

class AutomationDeleteDialog extends StatelessWidget {
  final AutomationConfig config;
  final VoidCallback onConfirm;

  const AutomationDeleteDialog({
    super.key,
    required this.config,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Bạn có chắc chắn muốn xóa automation "${config.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
} 