import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/appsflyer_service.dart';

// Provider cho việc track events
final appsFlyerProvider = Provider<AppsFlyerService>((ref) {
  return AppsFlyerService();
});

// Provider cho việc lấy AppsFlyer ID
final appsFlyerIdProvider = FutureProvider<String?>((ref) async {
  return await AppsFlyerService.getAppsFlyerId();
});

// Helper functions để sử dụng dễ dàng
class AppsFlyerProvider {
  static void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    AppsFlyerService.logEvent(eventName, parameters);
  }

  static void logPurchase({
    required double revenue,
    required String currency,
    String? orderId,
    Map<String, dynamic>? additionalParameters,
  }) {
    AppsFlyerService.logPurchase(
      revenue: revenue,
      currency: currency,
      orderId: orderId,
      additionalParameters: additionalParameters,
    );
  }

  static void logRegistration({
    String? method,
    Map<String, dynamic>? additionalParameters,
  }) {
    AppsFlyerService.logRegistration(
      method: method,
      additionalParameters: additionalParameters,
    );
  }

  static void logLogin({
    String? method,
    Map<String, dynamic>? additionalParameters,
  }) {
    AppsFlyerService.logLogin(
      method: method,
      additionalParameters: additionalParameters,
    );
  }

  static Future<void> setCustomerUserId(String userId) async {
    await AppsFlyerService.setCustomerUserId(userId);
  }

  static Future<String?> getAppsFlyerId() async {
    return await AppsFlyerService.getAppsFlyerId();
  }

  // Custom events cho Coka app
  static void logCustomerAdded({String? source, String? method}) {
    logEvent('customer_added', {
      if (source != null) 'source': source,
      if (method != null) 'method': method,
    });
  }

  static void logMessageSent({String? platform, String? type}) {
    logEvent('message_sent', {
      if (platform != null) 'platform': platform,
      if (type != null) 'type': type,
    });
  }

  static void logCampaignCreated({String? type}) {
    logEvent('campaign_created', {
      if (type != null) 'type': type,
    });
  }

  static void logAutomationCreated({String? type}) {
    logEvent('automation_created', {
      if (type != null) 'type': type,
    });
  }

  static void logReportViewed({String? reportType}) {
    logEvent('report_viewed', {
      if (reportType != null) 'report_type': reportType,
    });
  }

  static void logWorkspaceCreated() {
    logEvent('workspace_created');
  }

  static void logOrganizationCreated() {
    logEvent('organization_created');
  }
} 