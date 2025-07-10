import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/complete_profile_page.dart';
import 'pages/organization/organization_page.dart';
import 'pages/organization/detail_organization/detail_organization_page.dart';
import 'pages/organization/messages/messages_page.dart';
import 'pages/organization/messages/message_settings_page.dart';
import 'pages/organization/messages/chat_detail_page.dart';
import 'pages/organization/campaigns/campaigns_page.dart';
import 'pages/organization/campaigns/multi_source_connection/multi_source_connection_page.dart';
import 'pages/organization/campaigns/ai_chatbot/ai_chatbot_page.dart';
import 'pages/organization/campaigns/ai_chatbot/create_chatbot_page.dart';
import 'pages/organization/campaigns/ai_chatbot/edit_chatbot_page.dart';
import 'pages/organization/campaigns/fill_data/fill_data_page.dart';
import 'pages/organization/campaigns/automation/automation_page.dart';
import 'pages/organization/detail_organization/workspace/detail_workspace_page.dart';
import 'pages/organization/detail_organization/workspace/customers/customers_page.dart';
import 'pages/organization/detail_organization/workspace/teams/teams_page.dart';
import 'pages/organization/detail_organization/workspace/teams/team_detail_page.dart';
import 'pages/organization/detail_organization/workspace/reports/reports_page.dart';
import 'pages/organization/detail_organization/workspace/customers/customer_detail/customer_detail_page.dart';
import 'pages/organization/detail_organization/workspace/customers/customer_detail/pages/customer_basic_info_page.dart';
import 'pages/organization/detail_organization/workspace/customers/edit_customer_page.dart';
import 'pages/organization/detail_organization/workspace/customers/add_customer_page.dart';
import 'pages/organization/detail_organization/workspace/customers/import_googlesheet_page.dart';
import 'pages/organization/detail_organization/workspace/reminders/reminder_list_page.dart';
import 'pages/organization/settings/settings_page.dart';
import 'pages/organization/notifications/notifications_page.dart';
import 'pages/organization/create_organization_page.dart';
import 'pages/organization/invitation_page.dart';
import 'pages/organization/join_request_page.dart';

final appRoutes = [
  // Auth routes
  GoRoute(
    path: '/',
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    path: '/complete-profile',
    builder: (context, state) => const CompleteProfilePage(),
  ),
  GoRoute(
    path: '/organization/create',
    builder: (context, state) => const CreateOrganizationPage(),
  ),

  // Chat detail route (đặt trước ShellRoute để ưu tiên match)
  GoRoute(
    path: '/organization/:organizationId/messages/detail/:conversationId',
    builder: (context, state) {
      final organizationId = state.pathParameters['organizationId']!;
      final conversationId = state.pathParameters['conversationId']!;
      return ChatDetailPage(
        organizationId: organizationId,
        conversationId: conversationId,
      );
    },
  ),
  
  // Multi-source connection route (độc lập, không dùng ShellRoute)
  GoRoute(
    path: '/organization/:organizationId/campaigns/multi-source-connection',
    builder: (context, state) {
      final organizationId = state.pathParameters['organizationId']!;
      return MultiSourceConnectionPage(organizationId: organizationId);
    },
  ),

  // Fill Data route (độc lập, không dùng ShellRoute)
  GoRoute(
    path: '/organization/:organizationId/campaigns/fill-data',
    builder: (context, state) {
      final organizationId = state.pathParameters['organizationId']!;
      return FillDataPage(organizationId: organizationId);
    },
  ),

  // Automation route (độc lập, không dùng ShellRoute)
  GoRoute(
    path: '/organization/:organizationId/campaigns/automation',
    builder: (context, state) {
      final organizationId = state.pathParameters['organizationId']!;
      return AutomationPage(organizationId: organizationId);
    },
  ),

  // Organization routes with shell
  ShellRoute(
    builder: (context, state, child) {
      final organizationId = state.pathParameters['organizationId'];
      if (organizationId == null) return const SizedBox();
      return OrganizationPage(
        organizationId: organizationId,
        child: child,
      );
    },
    routes: [
      GoRoute(
        path: '/organization/:organizationId',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return DetailOrganizationPage(organizationId: organizationId);
        },
      ),
      GoRoute(
        path: '/organization/:organizationId/messages',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return MessagesPage(organizationId: organizationId);
        },
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) {
              final organizationId = state.pathParameters['organizationId']!;
              return MessageSettingsPage(organizationId: organizationId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/organization/:organizationId/campaigns',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return CampaignsPage(organizationId: organizationId);
        },
      ),
      // AI Chatbot routes
      GoRoute(
        path: '/organization/:organizationId/campaigns/ai-chatbot',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return AIChatbotPage(organizationId: organizationId);
        },
      ),
      GoRoute(
        path: '/organization/:organizationId/campaigns/ai-chatbot/create',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return CreateChatbotPage(organizationId: organizationId);
        },
      ),
      GoRoute(
        path: '/organization/:organizationId/campaigns/ai-chatbot/edit/:chatbotId',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          final chatbotId = state.pathParameters['chatbotId']!;
          return EditChatbotPage(
            organizationId: organizationId,
            chatbotId: chatbotId,
          );
        },
      ),
      GoRoute(
        path: '/organization/:organizationId/notifications',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return NotificationsPage(organizationId: organizationId);
        },
      ),
      GoRoute(
        path: '/organization/:organizationId/settings',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return SettingsPage(organizationId: organizationId);
        },
      ),
      GoRoute(
        path: '/organization/:organizationId/invitations',
        builder: (context, state) {
          return const InvitationPage();
        },
      ),
      GoRoute(
        path: '/organization/:organizationId/join-requests',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return JoinRequestPage(organizationId: organizationId);
        },
      ),
    ],
  ),

  // Workspace routes with shell
  ShellRoute(
    builder: (context, state, child) {
      final organizationId = state.pathParameters['organizationId'];
      final workspaceId = state.pathParameters['workspaceId'];
      if (organizationId == null || workspaceId == null) {
        return const SizedBox();
      }
      return DetailWorkspacePage(
        organizationId: organizationId,
        workspaceId: workspaceId,
        child: child,
      );
    },
    routes: [
      GoRoute(
        path: '/organization/:organizationId/workspace/:workspaceId/customers',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          final workspaceId = state.pathParameters['workspaceId']!;
          return CustomersPage(
            organizationId: organizationId,
            workspaceId: workspaceId,
          );
        },
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) {
              final organizationId = state.pathParameters['organizationId']!;
              final workspaceId = state.pathParameters['workspaceId']!;
              return AddCustomerPage(
                organizationId: organizationId,
                workspaceId: workspaceId,
              );
            },
          ),
          GoRoute(
            path: 'import-googlesheet',
            builder: (context, state) {
              final organizationId = state.pathParameters['organizationId']!;
              final workspaceId = state.pathParameters['workspaceId']!;
              return ImportGoogleSheetPage(
                organizationId: organizationId,
                workspaceId: workspaceId,
              );
            },
          ),
          GoRoute(
            path: ':customerId',
            builder: (context, state) {
              final organizationId = state.pathParameters['organizationId']!;
              final workspaceId = state.pathParameters['workspaceId']!;
              final customerId = state.pathParameters['customerId']!;
              return CustomerDetailPage(
                organizationId: organizationId,
                workspaceId: workspaceId,
                customerId: customerId,
              );
            },
            routes: [
              GoRoute(
                path: 'basic-info',
                builder: (context, state) {
                  final organizationId =
                      state.pathParameters['organizationId']!;
                  final workspaceId = state.pathParameters['workspaceId']!;
                  final customerId = state.pathParameters['customerId']!;
                  final customerDetail = state.extra as Map<String, dynamic>;
                  return CustomerBasicInfoPage(
                    customerDetail: customerDetail,
                  );
                },
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final organizationId =
                      state.pathParameters['organizationId']!;
                  final workspaceId = state.pathParameters['workspaceId']!;
                  final customerId = state.pathParameters['customerId']!;
                  final customerDetail = state.extra as Map<String, dynamic>;
                  return EditCustomerPage(
                    organizationId: organizationId,
                    workspaceId: workspaceId,
                    customerId: customerId,
                    customerData: customerDetail,
                  );
                },
              ),
              GoRoute(
                path: 'reminders',
                builder: (context, state) {
                  final organizationId =
                      state.pathParameters['organizationId']!;
                  final workspaceId = state.pathParameters['workspaceId']!;
                  final customerId = state.pathParameters['customerId']!;
                  return ReminderListPage(
                    organizationId: organizationId,
                    workspaceId: workspaceId,
                    contactId: customerId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/organization/:organizationId/workspace/:workspaceId/teams',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          final workspaceId = state.pathParameters['workspaceId']!;
          return TeamsPage(
            organizationId: organizationId,
            workspaceId: workspaceId,
          );
        },
        routes: [
          GoRoute(
            path: ':teamId',
            builder: (context, state) {
              final organizationId = state.pathParameters['organizationId']!;
              final workspaceId = state.pathParameters['workspaceId']!;
              final teamId = state.pathParameters['teamId']!;
              return TeamDetailPage(
                organizationId: organizationId,
                workspaceId: workspaceId,
                teamId: teamId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/organization/:organizationId/workspace/:workspaceId/reports',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          final workspaceId = state.pathParameters['workspaceId']!;
          return ReportsPage(
            organizationId: organizationId,
            workspaceId: workspaceId,
          );
        },
      ),
    ],
  ),


];
