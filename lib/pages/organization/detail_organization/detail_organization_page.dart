import 'package:flutter/material.dart';
import 'widgets/organization_detail_card.dart';
import 'widgets/workspace_list.dart';
import 'widgets/notification_list.dart';

class DetailOrganizationPage extends StatelessWidget {
  final String organizationId;
  const DetailOrganizationPage({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            OrganizationDetailCard(
              organizationId: organizationId,
            ),
            WorkspaceList(
              organizationId: organizationId,
            ),
            NotificationList(
              organizationId: organizationId,
            ),
          ],
        ),
      ),
    );
  }
}
