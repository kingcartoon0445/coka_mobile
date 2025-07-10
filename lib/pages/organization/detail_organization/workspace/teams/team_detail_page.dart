import 'package:flutter/material.dart';

class TeamDetailPage extends StatelessWidget {
  final String organizationId;
  final String workspaceId;
  final String teamId;

  const TeamDetailPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đội sale $teamId'),
      ),
      body: Center(
        child: Text(
          'Chi tiết đội sale $teamId của workspace $workspaceId',
        ),
      ),
    );
  }
}
