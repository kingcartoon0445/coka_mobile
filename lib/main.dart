import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/vi_messages.dart';
import 'router.dart';
import 'services/appsflyer_service.dart';
import 'services/fcm_service.dart';

// Global navigator key để navigation từ background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background message received: ${message.messageId}');

  print('Message: $message');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // final apiService = ApiService();

  final apiClient = ApiClient(); // Singleton instance
  await apiClient.init(); // Gọi trước khi dùng
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize AppsFlyer
  await AppsFlyerService.initialize();

  // Kiểm tra token
  final token = await ApiClient.storage.read(key: 'access_token');
  final defaultOrgId = await ApiClient.storage.read(key: 'default_organization_id');
  final initialLocation = token != null ? '/organization/${defaultOrgId ?? 'default'}' : '/';

  final appRouter = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    routes: appRoutes,
    redirect: (context, state) async {
      final token = await ApiClient.storage.read(key: 'access_token');
      final defaultOrgId = await ApiClient.storage.read(key: 'default_organization_id');
      final isLoginRoute = state.matchedLocation == '/';

      if (token == null && !isLoginRoute) {
        return '/';
      }

      if (token != null && isLoginRoute) {
        return '/organization/${defaultOrgId ?? 'default'}';
      }

      return null;
    },
    observers: [
      RouteObserver<ModalRoute<void>>(),
    ],
    debugLogDiagnostics: true,
  );

  // Lắng nghe sự thay đổi route
  appRouter.routerDelegate.addListener(() {
    final currentRoute = appRouter.routerDelegate.currentConfiguration;
    print('🚀 Route changed to: ${currentRoute.uri.toString()}');
  });

  timeago.setLocaleMessages('vi', CustomViMessages());

  runApp(
    ProviderScope(
      child: MyApp(router: appRouter),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    // required this.apiService,
    required this.router,
  });

  // final ApiService apiService;
  final GoRouter router;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    // Đợi một frame để context được khởi tạo và app hoàn toàn sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Delay thêm 2 giây để đảm bảo APNS token đã sẵn sàng (chỉ iOS)
      await Future.delayed(const Duration(seconds: 2));
      FCMService.initialize(context: context, router: widget.router);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Coka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: widget.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        // Update FCM context and router when available
        FCMService.updateContext(context);
        FCMService.updateRouter(widget.router);
        return child!;
      },
    );
  }
}
