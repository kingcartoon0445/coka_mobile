import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../api/repositories/notification_repository.dart';
import '../api/user_api.dart';
import '../api/api_client.dart';
import 'package:go_router/go_router.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static late NotificationRepository _notificationRepository;
  static late UserApi _userApi;
  static BuildContext? _context;
  static GoRouter? _router; // Thêm router reference
  
  // Khởi tạo FCM service
  static Future<void> initialize({
    BuildContext? context,
    GoRouter? router, // Thêm optional router parameter
  }) async {
    try {
      _context = context;
      _router = router; // Lưu router reference
      _notificationRepository = NotificationRepository(ApiClient());
      _userApi = UserApi();
      
      print('🔔 Initializing FCM Service...');
      
      // Request permission
      await _requestPermission();
      
      // Get và update FCM token
      await _handleTokenRefresh();
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        print('🔄 FCM Token refreshed: $token');
        _updateTokenToServer(token);
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Handle initial message if app was opened from notification
      _handleInitialMessage();
      
      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM Service: $e');
    }
  }
  
  // Request notification permission
  static Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('📋 Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional permission');
      } else {
        print('❌ User declined or has not accepted permission');
      }
    } catch (e) {
      print('❌ Error requesting permission: $e');
    }
  }
  
  // Get FCM token và update lên server
  static Future<void> _handleTokenRefresh() async {
    try {
      String? token;
      
      if (Platform.isIOS) {
        // Thử lấy FCM token với fallback strategy
        token = await _getFCMTokenWithFallback();
      } else {
        // Android - lấy token trực tiếp
        token = await _firebaseMessaging.getToken();
      }
      
      if (token != null) {
        print('📱 FCM Token: $token');
        await _updateTokenToServer(token);
      } else {
        print('⚠️ FCM Token is null, will retry later...');
        // Retry sau 30 giây
        _scheduleTokenRetry();
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      // Retry sau 30 giây
      _scheduleTokenRetry();
    }
  }
  
  // Lấy FCM token với fallback strategy cho iOS
  static Future<String?> _getFCMTokenWithFallback() async {
    if (!Platform.isIOS) return await _firebaseMessaging.getToken();
    
    try {
             print('🍎 Trying to get FCM token for iOS device...');
      
             // Thử 1: Lấy token trực tiếp 
       try {
         print('🔄 Attempting direct FCM token...');
         String? token = await _firebaseMessaging.getToken();
         if (token != null && !token.startsWith('simulator_') && !token.startsWith('fallback_')) {
           print('✅ FCM token received directly');
           return token;
         }
       } catch (e) {
         print('⚠️ Direct FCM token failed: $e');
         
         // Nếu lỗi APNS, thử request notification permission lại
         if (e.toString().contains('apns-token-not-set')) {
           print('🔄 APNS issue detected, requesting permission again...');
           await _requestPermission();
           await Future.delayed(const Duration(seconds: 2));
         }
       }
      
      // Thử 2: Request APNS token explicitly
      print('🔄 Requesting APNS token explicitly...');
      for (int i = 0; i < 5; i++) {
        try {
          // Request notification permission lại
          if (i == 0) {
            await _requestPermission();
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
                     String? apnsToken = await _firebaseMessaging.getAPNSToken();
          
          if (apnsToken != null) {
            print('✅ APNS token received, getting FCM token...');
            await Future.delayed(const Duration(milliseconds: 500));
            
                         String? fcmToken = await _firebaseMessaging.getToken();
             if (fcmToken != null) {
               print('✅ FCM token received');
               return fcmToken;
             }
          }
        } catch (e) {
          print('⏳ APNS/FCM attempt $i failed: $e');
        }
        
        await Future.delayed(const Duration(seconds: 1));
      }
      
      print('⚠️ All FCM token attempts failed - using fallback');
      return 'fallback_token_${DateTime.now().millisecondsSinceEpoch}';
      
    } catch (e) {
      print('❌ Error in FCM token fallback: $e');
      return 'error_token_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  

  
  // Schedule token retry
  static void _scheduleTokenRetry() {
    Future.delayed(const Duration(seconds: 30), () {
      print('🔄 Retrying FCM token...');
      _handleTokenRefresh();
    });
  }
  
  // Update FCM token lên server
  static Future<void> _updateTokenToServer(String token) async {
    try {
      // Generate device ID
      String deviceId = await _userApi.getDeviceId();
      
      await _userApi.updateFcmToken({
        "deviceId": deviceId,
        "fcmToken": token,
        "status": 1, // 1 là đang hoạt động, 0 là đã đăng xuất
      });
      
      print('✅ FCM token updated to server successfully');
    } catch (e) {
      print('❌ Error updating FCM token to server: $e');
    }
  }
  

  
  // Xử lý notification khi app đang foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Received foreground message: ${message.messageId}');
    print('Data: ${message.data}');
    
    // Hiển thị in-app notification hoặc update UI
    _showInAppNotification(message);
  }
  
  // Xử lý notification tap (từ background/terminated)
  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');
    
    // Navigate dựa trên notification data
    _navigateFromNotification(message);
  }
  
  // Xử lý initial message khi app mở từ notification
  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('🚀 App opened from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }
  
  // Hiển thị in-app notification
  static void _showInAppNotification(RemoteMessage message) {
    if (_context != null && _context!.mounted) {
      // Có thể sử dụng SnackBar, Toast, hoặc custom dialog
      final title = message.notification?.title ?? 'Thông báo';
      final body = message.notification?.body ?? '';
      
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Xem',
            onPressed: () => _navigateFromNotification(message),
          ),
        ),
      );
      
      // Play notification sound
      _playNotificationSound();
    }
  }
  
  // Navigate dựa trên notification data
  static void _navigateFromNotification(RemoteMessage message) {
    print('🔄 Attempting navigation from notification...');
    
    try {
      final data = message.data;
      print(message);
      
      // Parse navigation data
      final String? route = data['route'];
      final String? organizationId = data['organizationId'];
      final String? workspaceId = data['workspaceId'];
      final String? customerId = data['customerId'];
      final String? conversationId = data['conversationId'];
      final String? chatbotId = data['chatbotId'];
      final String? teamId = data['teamId'];
      final String? notificationId = data['notificationId'];
      
      // Mark notification as read nếu có notificationId
      if (notificationId != null) {
        _markNotificationAsRead(notificationId);
      }
      
      // SPECIAL CASE: chat_detail cần stack gồm MessagesPage -> ChatDetailPage để hỗ trợ back
      if (route == 'chat_detail' && organizationId != null && conversationId != null) {
        String messagesRoute = '/organization/$organizationId/messages';
        String detailRoute = '/organization/$organizationId/messages/detail/$conversationId';
        
        bool handled = false;
        try {
          if (_router != null) {
            _router!.go(messagesRoute);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_router != null) {
                _router!.push(detailRoute);
              } else if (_context != null && _context!.mounted) {
                _context!.push(detailRoute);
              }
            });
            handled = true;
          }
        } catch (e) {
          print('❌ Router navigation for chat_detail failed: $e');
        }
        
        if (!handled && _context != null && _context!.mounted) {
          try {
            _context!.go(messagesRoute);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_context != null && _context!.mounted) {
                _context!.push(detailRoute);
              }
            });
            handled = true;
          } catch (e) {
            print('❌ Context navigation for chat_detail failed: $e');
          }
        }
        
        if (handled) return;
      }
      
      // SPECIAL CASE 2: các route ngoài shell thuộc campaigns cần stack CampaignsPage -> Destination
      if (organizationId != null && route != null &&
          ['multi_source_connection', 'fill_data', 'automation'].contains(route)) {
        String campaignsRoute = '/organization/$organizationId/campaigns';
        String destRoute = _buildTargetRoute(
          route: route,
          organizationId: organizationId,
          workspaceId: workspaceId,
          customerId: customerId,
          chatbotId: chatbotId,
          conversationId: conversationId,
          teamId: teamId,
        );
        bool handled = false;
        try {
          if (_router != null) {
            _router!.go(campaignsRoute);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_router != null) {
                _router!.push(destRoute);
              } else if (_context != null && _context!.mounted) {
                _context!.push(destRoute);
              }
            });
            handled = true;
          }
        } catch (e) {
          print('❌ Router navigation for $route failed: $e');
        }
        if (!handled && _context != null && _context!.mounted) {
          try {
            _context!.go(campaignsRoute);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_context != null && _context!.mounted) {
                _context!.push(destRoute);
              }
            });
            handled = true;
          } catch (e) {
            print('❌ Context navigation for $route failed: $e');
          }
        }
        if (handled) return;
      }
      
      // Thử nhiều cách navigation khác nhau
      bool navigationSuccess = false;
      
      // Cách 1: Sử dụng router reference nếu có
      if (_router != null && route != null && organizationId != null) {
        try {
          String targetRoute = _buildTargetRoute(
            route: route,
            organizationId: organizationId,
            workspaceId: workspaceId,
            customerId: customerId,
            conversationId: conversationId,
            chatbotId: chatbotId,
            teamId: teamId,
          );
          
          // Routes nằm ngoài ShellRoute cần push để back hoạt động
          const routesWithoutShell = {
            'multi_source_connection',
            'fill_data',
            'automation',
          };
          
          final shouldPush = routesWithoutShell.contains(route);
          
          print('🎯 Navigating via router to: $targetRoute (push=$shouldPush)');
          if (shouldPush) {
            _router!.push(targetRoute);
          } else {
            _router!.go(targetRoute);
          }
          navigationSuccess = true;
          print('✅ Navigation via router successful');
        } catch (e) {
          print('❌ Router navigation failed: $e');
        }
      }
      
      // Cách 2: Fallback sử dụng context nếu router không hoạt động
      if (!navigationSuccess && _context != null && _context!.mounted) {
        try {
          if (route != null && organizationId != null) {
            String targetRoute = _buildTargetRoute(
              route: route,
              organizationId: organizationId,
              workspaceId: workspaceId,
              customerId: customerId,
              conversationId: conversationId,
              chatbotId: chatbotId,
              teamId: teamId,
            );
            
            print('🎯 Navigating via context to: $targetRoute');
            _context!.go(targetRoute);
            navigationSuccess = true;
            print('✅ Navigation via context successful');
          }
        } catch (e) {
          print('❌ Context navigation failed: $e');
        }
      }
      
      // Cách 3: Fallback cuối cùng - navigate đến default organization
      if (!navigationSuccess) {
        try {
          final fallbackRoute = '/organization/${organizationId ?? 'default'}';
          print('🎯 Fallback navigation to: $fallbackRoute');
          
          if (_router != null) {
            _router!.go(fallbackRoute);
          } else if (_context != null && _context!.mounted) {
            _context!.go(fallbackRoute);
          }
          
          print('✅ Fallback navigation successful');
        } catch (e) {
          print('❌ All navigation methods failed: $e');
        }
      }
      
    } catch (e) {
      print('❌ Error navigating from notification: $e');
    }
  }
  
  // Build target route dựa trên route type và parameters
  static String _buildTargetRoute({
    required String route,
    required String organizationId,
    String? workspaceId,
    String? customerId,
    String? conversationId,
    String? chatbotId,
    String? teamId,
  }) {
    switch (route) {
      // Organization routes
      case 'organization':
        return '/organization/$organizationId';
        
      case 'messages':
        return '/organization/$organizationId/messages';
        
      case 'message_settings':
        return '/organization/$organizationId/messages/settings';
        
      case 'chat_detail':
        if (conversationId != null) {
          return '/organization/$organizationId/messages/detail/$conversationId';
        }
        return '/organization/$organizationId/messages';
        
      case 'campaigns':
        return '/organization/$organizationId/campaigns';
        
      case 'ai_chatbot':
        return '/organization/$organizationId/campaigns/ai-chatbot';
        
      case 'create_chatbot':
        return '/organization/$organizationId/campaigns/ai-chatbot/create';
        
      case 'edit_chatbot':
        if (chatbotId != null) {
          return '/organization/$organizationId/campaigns/ai-chatbot/edit/$chatbotId';
        }
        return '/organization/$organizationId/campaigns/ai-chatbot';
        
      case 'multi_source_connection':
        return '/organization/$organizationId/campaigns/multi-source-connection';
        
      case 'fill_data':
        return '/organization/$organizationId/campaigns/fill-data';
        
      case 'automation':
        return '/organization/$organizationId/campaigns/automation';
        
      case 'notifications':
        return '/organization/$organizationId/notifications';
        
      case 'settings':
        return '/organization/$organizationId/settings';
        
      case 'invitations':
        return '/organization/$organizationId/invitations';
        
      case 'join_requests':
        return '/organization/$organizationId/join-requests';
      
      // Workspace routes
      case 'workspace':
        if (workspaceId != null) {
          return '/organization/$organizationId/workspace/$workspaceId';
        }
        return '/organization/$organizationId';
        
      case 'customers':
        if (workspaceId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/customers';
        }
        return '/organization/$organizationId';
        
      case 'customer_detail':
        if (workspaceId != null && customerId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/customers/$customerId';
        }
        return '/organization/$organizationId';
        
      case 'add_customer':
        if (workspaceId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/customers/new';
        }
        return '/organization/$organizationId';
        
      case 'edit_customer':
        if (workspaceId != null && customerId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/customers/$customerId/edit';
        }
        return '/organization/$organizationId';
        
      case 'customer_basic_info':
        if (workspaceId != null && customerId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/customers/$customerId/basic-info';
        }
        return '/organization/$organizationId';
        
      case 'customer_reminders':
        if (workspaceId != null && customerId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/customers/$customerId/reminders';
        }
        return '/organization/$organizationId';
        
      case 'import_googlesheet':
        if (workspaceId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/customers/import-googlesheet';
        }
        return '/organization/$organizationId';
        
      case 'teams':
        if (workspaceId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/teams';
        }
        return '/organization/$organizationId';
        
      case 'team_detail':
        if (workspaceId != null && teamId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/teams/$teamId';
        }
        return '/organization/$organizationId';
        
      case 'reports':
        if (workspaceId != null) {
          return '/organization/$organizationId/workspace/$workspaceId/reports';
        }
        return '/organization/$organizationId';
      
      // Default fallback
      default:
        return '/organization/$organizationId';
    }
  }
  
  // Mark notification as read
  static Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _notificationRepository.setNotificationRead(notificationId);
      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }
  
  // Play notification sound
  static void _playNotificationSound() {
    try {
      // Có thể thêm audio package để play custom sound
      // SystemSound.play(SystemSound.click);
      print('🔊 Playing notification sound');
    } catch (e) {
      print('❌ Error playing notification sound: $e');
    }
  }
  
  // Get current FCM token
  static Future<String?> getToken() async {
    try {
      String? token;
      if (Platform.isIOS) {
        token = await _getFCMTokenWithFallback();
      } else {
        token = await _firebaseMessaging.getToken();
      }
      
             // Log token status
       if (token != null) {
         print('📱 FCM Token: ${token.substring(0, 20)}...');
       } else {
         print('⚠️ FCM Token is null');
       }
      
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }
  
  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }
  
  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }
  
  // Update context (gọi khi context thay đổi)
  static void updateContext(BuildContext context) {
    _context = context;
  }
  
  // Update router reference
  static void updateRouter(GoRouter router) {
    _router = router;
  }
}

// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  
  // Có thể xử lý data ở background
  // Ví dụ: cập nhật local database, sync data, etc.
} 