// lib/main.dart (refactored with Bloc + GoRouter)

import 'package:coka/bloc/app/app_cubit.dart';
import 'package:coka/bloc/login/login_cubit.dart';
import 'package:coka/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiClient().init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await AppsFlyerService.initialize();

  final token = await ApiClient.storage.read(key: 'access_token');
  final orgId = await ApiClient.storage.read(key: 'default_organization_id');

  final initialLocation = token != null ? '/organization/${orgId ?? 'default'}' : '/';

  final router = createAppRouter(initialLocation);

  timeago.setLocaleMessages('vi', CustomViMessages());

  runApp(ProviderScope(child: MyApp(router: router)));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppCubit()..initialize()),
        BlocProvider(create: (_) => LoginCubit()..initialize()),
        // Add other cubits/blocs here
      ],
      child: MaterialApp.router(
        title: 'Coka',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
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
          FCMService.updateRouter(router);
          return child!;
        },
      ),
    );
  }
}
