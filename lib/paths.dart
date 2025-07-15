// lib/router/paths.dart

class AppPaths {
  static const login = '/';
  static const completeProfile = '/complete-profile';
  static const organizationCreate = '/organization/create';

  // Organization
  static String organization(String id) => '/organization/$id';
  static String messages(String id) => '/organization/$id/messages';
  static String chatDetail(String id, String conversationId) =>
      '/organization/$id/messages/detail/$conversationId';
  static String campaigns(String id) => '/organization/$id/campaigns';
  static String multiSourceConnection(String id) =>
      '/organization/$id/campaigns/multi-source-connection';
  static String fillData(String id) => '/organization/$id/campaigns/fill-data';
  static String automation(String id) => '/organization/$id/campaigns/automation';
  static String aiChatbot(String id) => '/organization/$id/campaigns/ai-chatbot';
  static String createChatbot(String id) => '/organization/$id/campaigns/ai-chatbot/create';
  static String editChatbot(String id, String chatbotId) =>
      '/organization/$id/campaigns/ai-chatbot/edit/$chatbotId';

  static String settings(String id) => '/organization/$id/settings';
  static String notifications(String id) => '/organization/$id/notifications';
  static String invitations(String id) => '/organization/$id/invitations';
  static String joinRequests(String id) => '/organization/$id/join-requests';

  // Workspace
  static String workspace(String orgId, String wsId) => '/organization/$orgId/workspace/$wsId';
  static String customers(String orgId, String wsId) => '$workspace(orgId, wsId)/customers';
  static String teams(String orgId, String wsId) => '$workspace(orgId, wsId)/teams';
  static String reports(String orgId, String wsId) => '$workspace(orgId, wsId)/reports';
}
