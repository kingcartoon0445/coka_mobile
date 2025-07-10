import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final String organizationId;

  const SettingsPage({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: Center(
        child: Text(
          'Cài đặt của tổ chức $organizationId',
        ),
      ),
    );
  }
}
