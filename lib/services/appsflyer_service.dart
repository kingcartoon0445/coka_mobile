import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

class AppsFlyerService {
  static AppsflyerSdk? _appsflyerSdk;
  static bool _isInitialized = false;
  static bool _initializationFailed = false;
  
  // Thay thế bằng Dev Key thực tế từ AppsFlyer dashboard
  static const String _devKey = "cnbvawgJtE4vn3ao2DzLuC";
  
  // App ID cho iOS (từ App Store Connect)
  static const String _appId = "6447948044";

  static Future<void> initialize() async {
    if (_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('⚠️ AppsFlyer already processed (initialized: $_isInitialized, failed: $_initializationFailed)');
      }
      return;
    }

    try {
      final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: _devKey,
        appId: _appId, // Chỉ cần cho iOS
        showDebug: kDebugMode, // Hiển thị debug logs trong development
        timeToWaitForATTUserAuthorization: 50, // Thời gian chờ ATT authorization (iOS 14.5+)
        disableAdvertisingIdentifier: false,
        disableCollectASA: false, // Apple Search Ads
        manualStart: false, // Tự động start tracking
      );

      _appsflyerSdk = AppsflyerSdk(options);

      // Set up event listeners TRƯỚC khi init SDK
      _setupEventListeners();

      // Delay một chút để đảm bảo listeners được setup
      await Future.delayed(const Duration(milliseconds: 100));

      // Initialize SDK
      _appsflyerSdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ AppsFlyer SDK initialized successfully');
      }

    } catch (e) {
      _initializationFailed = true;
      if (kDebugMode) {
        print('❌ AppsFlyer initialization error: $e');
        print('🔄 AppsFlyer will work in fallback mode');
      }
    }
  }

  static void _setupEventListeners() {
    if (_appsflyerSdk == null) return;

    try {
      // Conversion Data Callback - để tracking install campaigns
      _appsflyerSdk!.onInstallConversionData((data) {
        if (kDebugMode) {
          print('📊 AppsFlyer Conversion Data: $data');
        }
        _handleConversionData(data);
      });

      // Attribution Data Callback - để tracking re-engagement campaigns
      _appsflyerSdk!.onAppOpenAttribution((data) {
        if (kDebugMode) {
          print('🔗 AppsFlyer Attribution Data: $data');
        }
        _handleAttributionData(data);
      });

      // Deep Link Callback - để handle deep links
      _appsflyerSdk!.onDeepLinking((result) {
        if (kDebugMode) {
          print('🔗 AppsFlyer Deep Link: ${result.deepLink?.deepLinkValue}');
        }
        _handleDeepLink(result);
      });

      if (kDebugMode) {
        print('✅ AppsFlyer event listeners setup successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AppsFlyer event listeners setup error: $e');
      }
    }
  }

  static void _handleConversionData(Map<dynamic, dynamic> data) {
    // Xử lý conversion data
    // Ví dụ: track campaign performance, user attribution
    final String? campaign = data['campaign'];
    final String? mediaSource = data['media_source'];
    final bool? isFirstLaunch = data['is_first_launch'];

    if (isFirstLaunch == true) {
      // User mới từ campaign
      if (kDebugMode) {
        print('🆕 New user from campaign: $campaign, media source: $mediaSource');
      }
    }
  }

  static void _handleAttributionData(Map<dynamic, dynamic> data) {
    // Xử lý attribution data cho re-engagement
    final String? campaign = data['campaign'];
    final String? mediaSource = data['media_source'];
    
    if (kDebugMode) {
      print('🔄 Re-engagement from campaign: $campaign, media source: $mediaSource');
    }
  }

  static void _handleDeepLink(DeepLinkResult result) {
    // Xử lý deep link data
    final String? deepLinkValue = result.deepLink?.deepLinkValue;
    
    if (deepLinkValue != null) {
      if (kDebugMode) {
        print('🔗 Deep link received: $deepLinkValue');
      }
      // TODO: Navigate to specific screen based on deep link
    }
  }

  // Phương thức để track custom events
  static void logEvent(String eventName, Map<String, dynamic>? parameters) {
    if (_initializationFailed) {
      if (kDebugMode) {
        print('📝 [Fallback] Event: $eventName with parameters: $parameters');
      }
      return;
    }

    if (!_isInitialized || _appsflyerSdk == null) {
      if (kDebugMode) {
        print('⚠️ AppsFlyer SDK not ready - event: $eventName');
      }
      return;
    }

    try {
      _appsflyerSdk!.logEvent(eventName, parameters ?? {});
      if (kDebugMode) {
        print('📊 AppsFlyer event logged: $eventName with parameters: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppsFlyer event logging error: $e');
        print('📝 Event was: $eventName with parameters: $parameters');
      }
    }
  }

  // Set user ID cho tracking cross-device
  static Future<void> setCustomerUserId(String userId) async {
    if (_appsflyerSdk == null) return;

    try {
      _appsflyerSdk!.setCustomerUserId(userId);
      if (kDebugMode) {
        print('👤 AppsFlyer Customer User ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppsFlyer set customer user ID error: $e');
      }
    }
  }

  // Get AppsFlyer ID
  static Future<String?> getAppsFlyerId() async {
    if (_appsflyerSdk == null) return null;

    try {
      return await _appsflyerSdk!.getAppsFlyerUID();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppsFlyer get ID error: $e');
      }
      return null;
    }
  }

  // Predefined events cho common use cases
  static void logPurchase({
    required double revenue,
    required String currency,
    String? orderId,
    Map<String, dynamic>? additionalParameters,
  }) {
    final Map<String, dynamic> parameters = {
      'af_revenue': revenue,
      'af_currency': currency,
      if (orderId != null) 'af_order_id': orderId,
      ...?additionalParameters,
    };

    logEvent('af_purchase', parameters);
  }

  static void logRegistration({
    String? method,
    Map<String, dynamic>? additionalParameters,
  }) {
    final Map<String, dynamic> parameters = {
      if (method != null) 'af_registration_method': method,
      ...?additionalParameters,
    };

    logEvent('af_complete_registration', parameters);
  }

  static void logLogin({
    String? method,
    Map<String, dynamic>? additionalParameters,
  }) {
    final Map<String, dynamic> parameters = {
      if (method != null) 'af_login_method': method,
      ...?additionalParameters,
    };

    logEvent('af_login', parameters);
  }
} 