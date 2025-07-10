import 'package:flutter/material.dart';

class MessageSettingsPage extends StatelessWidget {
  final String organizationId;

  const MessageSettingsPage({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt tin nhắn'),
      ),
      body: Center(
        child: Text('Cài đặt tin nhắn của tổ chức $organizationId'),
      ),
    );
  }
}
