// main.dart

import 'package:coka/paths.dart';
import 'package:coka/router.dart';
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
import 'services/appsflyer_service.dart';
import 'services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background message received: ${message.messageId}');
  print('Message: $message');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  await apiClient.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await AppsFlyerService.initialize();

  final token = await ApiClient.storage.read(key: 'access_token');
  final defaultOrgId = await ApiClient.storage.read(key: 'default_organization_id');

  final initialLocation =
      token != null ? AppPaths.organization(defaultOrgId ?? 'default') : AppPaths.login;

  final appRouter = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    routes: appRoutes,
    redirect: (context, state) async {
      final token = await ApiClient.storage.read(key: 'access_token');
      final defaultOrgId = await ApiClient.storage.read(key: 'default_organization_id');
      final isLoginRoute = state.matchedLocation == AppPaths.login;

      if (token == null && !isLoginRoute) return AppPaths.login;
      if (token != null && isLoginRoute) return AppPaths.organization(defaultOrgId ?? 'default');
      return null;
    },
    observers: [RouteObserver<ModalRoute<void>>()],
    debugLogDiagnostics: true,
  );

  appRouter.routerDelegate.addListener(() {
    final currentRoute = appRouter.routerDelegate.currentConfiguration;
    print('🚀 Route changed to: \${currentRoute.uri.toString()}');
  });

  timeago.setLocaleMessages('vi', CustomViMessages());

  runApp(ProviderScope(child: MyApp(router: appRouter)));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.router});
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
        FCMService.updateContext(context);
        FCMService.updateRouter(widget.router);
        return child!;
      },
    );
  }
}
