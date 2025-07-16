class ApiPath {
  // Auth
  static const String login = '$_prefix/auth/login';
  static const String socialLogin = '$_prefix/auth/social/login';
  static const String verifyOtp = '$_prefix/otp/verify';
  static const String resendOtp = '$_prefix/otp/resend';
  static const String refreshToken = '$_prefix/account/refreshtoken';

  // User
  static const String profileDetail = '$_prefix/user/profile/getdetail';
  static const String profileUpdate = '$_prefix/user/profile/update';

  // Campaign
  static const String campaignBase = '$_prefix/campaigns';
  static const String campaignPaging = '$_prefix/campaign/getlistpaging';

  // Chatbot
  static const String chatbotPaging = '$_prefix/omni/chatbot/getlistpaging';
  static const String chatbotCreate = '$_prefix/omni/chatbot/create';
  static String chatbotDetail(String id) => '$_prefix/omni/chatbot/get/$id';
  static String chatbotUpdate(String id) => '$_prefix/omni/chatbot/update/$id';
  static String chatbotUpdateStatus(String id) => '$_prefix/omni/chatbot/updatestatus/$id';

  static String chatbotConversationUpdateStatus(String conversationId, int status) =>
      '$_prefix/omni/conversation/updatechatbotstatus/$conversationId?Status=$status';
// Message & Conversation
  static const String fbConnect = '$_prefix/auth/facebook/message';
  static const String conversationList = '$_prefix/omni/conversation/getlistpaging';
  static const String chatList = '$_prefix/social/message/getlistpaging';
  static const String sendMessage = '$_prefix/social/message/sendmessage';
  static const String assignConversation = '$_prefix/omni/conversation';
  static const String convertToLead = '$_prefix/omni/conversation';
  static const String subscriptionList = '$_prefix/integration/omnichannel/getlistpaging';
  static const String updateSubscription = '$_prefix/integration/omnichannel/updatestatus';
  static const String assignableUsers = '$_prefix/organization/workspace/user/getlistpaging';
  static const String teamList = '$_prefix/organization/workspace/team/getlistpaging';

  static String updateStatisOmniChannel(String id) =>
      '$_prefix/integration/omnichannel/updatestatus/$id';
  static String getListPage(String provider, String subscribed, String searchText) =>
      '$_prefix/integration/omnichannel/getlistpaging?Provider=$provider&Subscribed=$subscribed&searchText=$searchText&Fields=Name&limit=20';
  static String updateStatusRead(String conversationId) =>
      '$_prefix/integration/omni/conversation/read/$conversationId';
  // /api/v1/integration/omni/conversation/read/{conversationId}
  // Prefix
  static const String _prefix = '/api/v1';
}
