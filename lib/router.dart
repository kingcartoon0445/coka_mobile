import 'package:coka/pages/organization/create_organization_page.dart';
import 'package:go_router/go_router.dart';

import 'pages/auth/complete_profile_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/organization/campaigns/ai_chatbot/ai_chatbot_page.dart';
import 'pages/organization/campaigns/ai_chatbot/create_chatbot_page.dart';
import 'pages/organization/campaigns/ai_chatbot/edit_chatbot_page.dart';
import 'pages/organization/campaigns/automation/automation_page.dart';
import 'pages/organization/campaigns/campaigns_page.dart';
import 'pages/organization/campaigns/fill_data/fill_data_page.dart';
import 'pages/organization/campaigns/multi_source_connection/multi_source_connection_page.dart';
import 'pages/organization/detail_organization/detail_organization_page.dart';
import 'pages/organization/detail_organization/workspace/customers/add_customer_page.dart';
import 'pages/organization/detail_organization/workspace/customers/customer_detail/customer_detail_page.dart';
import 'pages/organization/detail_organization/workspace/customers/customer_detail/pages/customer_basic_info_page.dart';
import 'pages/organization/detail_organization/workspace/customers/customers_page.dart';
import 'pages/organization/detail_organization/workspace/customers/edit_customer_page.dart';
import 'pages/organization/detail_organization/workspace/customers/import_googlesheet_page.dart';
import 'pages/organization/detail_organization/workspace/detail_workspace_page.dart';
import 'pages/organization/detail_organization/workspace/reminders/reminder_list_page.dart';
import 'pages/organization/detail_organization/workspace/reports/reports_page.dart';
import 'pages/organization/detail_organization/workspace/teams/team_detail_page.dart';
import 'pages/organization/detail_organization/workspace/teams/teams_page.dart';
import 'pages/organization/invitation_page.dart';
import 'pages/organization/join_request_page.dart';
import 'pages/organization/messages/chat_detail_page.dart';
import 'pages/organization/messages/message_settings_page.dart';
import 'pages/organization/messages/messages_page.dart';
import 'pages/organization/notifications/notifications_page.dart';
import 'pages/organization/organization_page.dart';
import 'pages/organization/settings/settings_page.dart';
import 'paths.dart';

GoRouter createAppRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: appRoutes,
    redirect: (context, state) async {
      // Logic điều hướng như kiểm tra token
      return null;
    },
    debugLogDiagnostics: true,
  );
}

final appRoutes = <RouteBase>[
  GoRoute(path: AppPaths.login, builder: (context, state) => const LoginPage()),
  GoRoute(path: AppPaths.completeProfile, builder: (context, state) => const CompleteProfilePage()),
  GoRoute(
      path: AppPaths.createOrganization,
      builder: (context, state) => const CreateOrganizationPage()),
  GoRoute(
    path: AppPaths.chatDetail(':organizationId', ':conversationId'),
    builder: (context, state) => ChatDetailPage(
      organizationId: state.pathParameters['organizationId']!,
      conversationId: state.pathParameters['conversationId']!,
    ),
  ),
  GoRoute(
    path: AppPaths.multiSourceConnection(':organizationId'),
    builder: (context, state) => MultiSourceConnectionPage(
      organizationId: state.pathParameters['organizationId']!,
    ),
  ),
  GoRoute(
    path: AppPaths.fillData(':organizationId'),
    builder: (context, state) => FillDataPage(
      organizationId: state.pathParameters['organizationId']!,
    ),
  ),
  GoRoute(
    path: AppPaths.automation(':organizationId'),
    builder: (context, state) => AutomationPage(
      organizationId: state.pathParameters['organizationId']!,
    ),
  ),
  ShellRoute(
    builder: (context, state, child) => OrganizationPage(
      organizationId: state.pathParameters['organizationId']!,
      child: child,
    ),
    routes: [
      GoRoute(
        path: AppPaths.organization(':organizationId'),
        builder: (context, state) => DetailOrganizationPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.messages(
          ':organizationId',
        ),
        builder: (context, state) => MessagesPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => MessageSettingsPage(
              organizationId: state.pathParameters['organizationId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppPaths.campaigns(':organizationId'),
        builder: (context, state) => CampaignsPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.aiChatbot(':organizationId'),
        builder: (context, state) => AIChatbotPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.createChatbot(':organizationId'),
        builder: (context, state) => CreateChatbotPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.editChatbot(':organizationId', ':chatbotId'),
        builder: (context, state) => EditChatbotPage(
          organizationId: state.pathParameters['organizationId']!,
          chatbotId: state.pathParameters['chatbotId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.notifications(':organizationId'),
        builder: (context, state) => NotificationsPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.settings(':organizationId'),
        builder: (context, state) => SettingsPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.invitations(':organizationId'),
        builder: (context, state) => const InvitationPage(),
      ),
      GoRoute(
        path: AppPaths.joinRequests(':organizationId'),
        builder: (context, state) => JoinRequestPage(
          organizationId: state.pathParameters['organizationId']!,
        ),
      ),
    ],
  ),
  ShellRoute(
    builder: (context, state, child) => DetailWorkspacePage(
      organizationId: state.pathParameters['organizationId']!,
      workspaceId: state.pathParameters['workspaceId']!,
      child: child,
    ),
    routes: [
      GoRoute(
        path: AppPaths.customers(':organizationId', ':workspaceId'),
        builder: (context, state) => CustomersPage(
          organizationId: state.pathParameters['organizationId']!,
          workspaceId: state.pathParameters['workspaceId']!,
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => AddCustomerPage(
              organizationId: state.pathParameters['organizationId']!,
              workspaceId: state.pathParameters['workspaceId']!,
            ),
          ),
          GoRoute(
            path: 'import-googlesheet',
            builder: (context, state) => ImportGoogleSheetPage(
              organizationId: state.pathParameters['organizationId']!,
              workspaceId: state.pathParameters['workspaceId']!,
            ),
          ),
          GoRoute(
            path: ':customerId',
            builder: (context, state) => CustomerDetailPage(
              organizationId: state.pathParameters['organizationId']!,
              workspaceId: state.pathParameters['workspaceId']!,
              customerId: state.pathParameters['customerId']!,
            ),
            routes: [
              GoRoute(
                path: 'basic-info',
                builder: (context, state) => CustomerBasicInfoPage(
                  customerDetail: state.extra as Map<String, dynamic>,
                ),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) => EditCustomerPage(
                  organizationId: state.pathParameters['organizationId']!,
                  workspaceId: state.pathParameters['workspaceId']!,
                  customerId: state.pathParameters['customerId']!,
                  customerData: state.extra as Map<String, dynamic>,
                ),
              ),
              GoRoute(
                path: 'reminders',
                builder: (context, state) => ReminderListPage(
                  organizationId: state.pathParameters['organizationId']!,
                  workspaceId: state.pathParameters['workspaceId']!,
                  contactId: state.pathParameters['customerId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppPaths.teams(':organizationId', ':workspaceId'),
        builder: (context, state) => TeamsPage(
          organizationId: state.pathParameters['organizationId']!,
          workspaceId: state.pathParameters['workspaceId']!,
        ),
        routes: [
          GoRoute(
            path: ':teamId',
            builder: (context, state) => TeamDetailPage(
              organizationId: state.pathParameters['organizationId']!,
              workspaceId: state.pathParameters['workspaceId']!,
              teamId: state.pathParameters['teamId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppPaths.reports(':organizationId', ':workspaceId'),
        builder: (context, state) => ReportsPage(
          organizationId: state.pathParameters['organizationId']!,
          workspaceId: state.pathParameters['workspaceId']!,
        ),
      ),
    ],
  ),
];
