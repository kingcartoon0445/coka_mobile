class AppPaths {
  // Private constructor to prevent instantiation
  AppPaths._();

  // Auth paths
  static const String login = '/';
  static const String completeProfile = '/complete-profile';

  // Organization creation
  static const String createOrganization = '/organization/create';

  // Organization base paths
  static String organization(String organizationId) => '/organization/$organizationId';

  // Messages paths
  static String messages(String organizationId) => '/organization/$organizationId/messages';
  static String messageSettings(String organizationId) =>
      '/organization/$organizationId/messages/settings';
  static String chatDetail(String organizationId, String conversationId) =>
      '/organization/$organizationId/messages/detail/$conversationId';

  // Campaigns paths
  static String campaigns(String organizationId) => '/organization/$organizationId/campaigns';
  static String multiSourceConnection(String organizationId) =>
      '/organization/$organizationId/campaigns/multi-source-connection';
  static String fillData(String organizationId) =>
      '/organization/$organizationId/campaigns/fill-data';
  static String automation(String organizationId) =>
      '/organization/$organizationId/campaigns/automation';

  // AI Chatbot paths
  static String aiChatbot(String organizationId) =>
      '/organization/$organizationId/campaigns/ai-chatbot';
  static String createChatbot(String organizationId) =>
      '/organization/$organizationId/campaigns/ai-chatbot/create';
  static String editChatbot(String organizationId, String chatbotId) =>
      '/organization/$organizationId/campaigns/ai-chatbot/edit/$chatbotId';

  // Organization management paths
  static String notifications(String organizationId) =>
      '/organization/$organizationId/notifications';
  static String settings(String organizationId) => '/organization/$organizationId/settings';
  static String invitations(String organizationId) => '/organization/$organizationId/invitations';
  static String joinRequests(String organizationId) =>
      '/organization/$organizationId/join-requests';

  // Workspace paths
  static String workspace(String organizationId, String workspaceId) =>
      '/organization/$organizationId/workspace/$workspaceId';

  // Customers paths
  static String customers(String organizationId, String workspaceId) =>
      '/organization/$organizationId/workspace/$workspaceId/customers';
  static String addCustomer(String organizationId, String workspaceId) =>
      '/organization/$organizationId/workspace/$workspaceId/customers/new';
  static String importGoogleSheet(String organizationId, String workspaceId) =>
      '/organization/$organizationId/workspace/$workspaceId/customers/import-googlesheet';
  static String customerDetail(String organizationId, String workspaceId, String customerId) =>
      '/organization/$organizationId/workspace/$workspaceId/customers/$customerId';
  static String customerBasicInfo(String organizationId, String workspaceId, String customerId) =>
      '/organization/$organizationId/workspace/$workspaceId/customers/$customerId/basic-info';
  static String editCustomer(String organizationId, String workspaceId, String customerId) =>
      '/organization/$organizationId/workspace/$workspaceId/customers/$customerId/edit';
  static String customerReminders(String organizationId, String workspaceId, String customerId) =>
      '/organization/$organizationId/workspace/$workspaceId/customers/$customerId/reminders';

  // Teams paths
  static String teams(String organizationId, String workspaceId) =>
      '/organization/$organizationId/workspace/$workspaceId/teams';
  static String teamDetail(String organizationId, String workspaceId, String teamId) =>
      '/organization/$organizationId/workspace/$workspaceId/teams/$teamId';

  // Reports paths
  static String reports(String organizationId, String workspaceId) =>
      '/organization/$organizationId/workspace/$workspaceId/reports';

  // Validation helper methods
  static bool isValidOrganizationPath(String path) {
    return path.startsWith('/organization/') && path.split('/').length >= 3;
  }

  static bool isValidWorkspacePath(String path) {
    return path.contains('/workspace/') && path.split('/').length >= 5;
  }

  static bool isValidCustomerPath(String path) {
    return path.contains('/customers/') && path.split('/').length >= 7;
  }
}

// Navigation helper methods
class AppNavigation {
  // Private constructor to prevent instantiation
  AppNavigation._();

  // Helper method to navigate to organization with GoRouter
  static String goToOrganization(String organizationId) => AppPaths.organization(organizationId);

  // Helper method to navigate to workspace
  static String goToWorkspace(String organizationId, String workspaceId) =>
      AppPaths.workspace(organizationId, workspaceId);

  // Helper method to navigate to customers
  static String goToCustomers(String organizationId, String workspaceId) =>
      AppPaths.customers(organizationId, workspaceId);

  // Helper method to navigate to specific customer
  static String goToCustomer(String organizationId, String workspaceId, String customerId) =>
      AppPaths.customerDetail(organizationId, workspaceId, customerId);

  // Helper method to navigate to messages
  static String goToMessages(String organizationId) => AppPaths.messages(organizationId);

  // Helper method to navigate to campaigns
  static String goToCampaigns(String organizationId) => AppPaths.campaigns(organizationId);
}

// Route parameters - useful for extracting params from context
class AppParams {
  // Private constructor to prevent instantiation
  AppParams._();

  static const String organizationId = 'organizationId';
  static const String workspaceId = 'workspaceId';
  static const String customerId = 'customerId';
  static const String teamId = 'teamId';
  static const String conversationId = 'conversationId';
  static const String chatbotId = 'chatbotId';
}

// Route patterns - useful for route matching
class AppPatterns {
  // Private constructor to prevent instantiation
  AppPatterns._();

  static const String organizationPattern = '/organization/:organizationId';
  static const String workspacePattern = '/organization/:organizationId/workspace/:workspaceId';
  static const String customerPattern =
      '/organization/:organizationId/workspace/:workspaceId/customers/:customerId';
  static const String teamPattern =
      '/organization/:organizationId/workspace/:workspaceId/teams/:teamId';
  static const String chatDetailPattern =
      '/organization/:organizationId/messages/detail/:conversationId';
  static const String chatbotEditPattern =
      '/organization/:organizationId/campaigns/ai-chatbot/edit/:chatbotId';

  // Validation helper methods
  static bool isValidOrganizationPath(String path) {
    return path.startsWith('/organization/') && path.split('/').length >= 3;
  }

  static bool isValidWorkspacePath(String path) {
    return path.contains('/workspace/') && path.split('/').length >= 5;
  }

  static bool isValidCustomerPath(String path) {
    return path.contains('/customers/') && path.split('/').length >= 7;
  }
}
