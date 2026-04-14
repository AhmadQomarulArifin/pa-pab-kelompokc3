import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'models/role_config.dart';
import 'services/secure_storage_service.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

String? pendingNotificationPayload;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL tidak terbaca');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY tidak terbaca');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    await NotificationService.instance.init(
      onNotificationTap: (payload) {
        pendingNotificationPayload = payload;
      },
    );

    runApp(const NolPersenApp());
  } catch (e, st) {
    debugPrint('STARTUP ERROR: $e');
    debugPrintStack(stackTrace: st);

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Startup error:\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NolPersenApp extends StatelessWidget {
  const NolPersenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Nol Persen Kafe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppStartScreen(),
    );
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  late Future<_StartResult> _startFuture;

  @override
  void initState() {
    super.initState();
    _startFuture = _checkLoginState();
  }

  Future<_StartResult> _checkLoginState() async {
    try {
      final isLoggedIn = await SecureStorageService.instance.isLoggedIn();

      if (!isLoggedIn) {
        return const _StartResult.goToLogin();
      }

      final client = Supabase.instance.client;
      final authUser = client.auth.currentUser;

      if (authUser == null) {
        await SecureStorageService.instance.logout();
        return const _StartResult.goToLogin();
      }

      final profile = await client
          .from('users')
          .select('role, is_active')
          .eq('id', authUser.id)
          .maybeSingle();

      if (profile == null) {
        await SecureStorageService.instance.logout();
        await client.auth.signOut();
        return const _StartResult.goToLogin();
      }

      final role = (profile['role'] ?? '').toString().toLowerCase();
      final isActive = profile['is_active'] as bool? ?? true;

      if (!isActive) {
        await SecureStorageService.instance.logout();
        await client.auth.signOut();
        return const _StartResult.goToLogin();
      }

      final roleConfig = RoleConfig.fromRoleString(role);

      return _StartResult.goToMain(
        roleConfig,
        notificationPayload: pendingNotificationPayload,
      );
    } catch (_) {
      await SecureStorageService.instance.logout();
      return const _StartResult.goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartResult>(
      future: _startFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final result = snapshot.data ?? const _StartResult.goToLogin();

        if (result.openMain && result.roleConfig != null) {
          return MainShell(
            role: result.roleConfig!,
            initialNotificationPayload: result.notificationPayload,
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class _StartResult {
  final bool openMain;
  final RoleConfig? roleConfig;
  final String? notificationPayload;

  const _StartResult._({
    required this.openMain,
    this.roleConfig,
    this.notificationPayload,
  });

  const _StartResult.goToLogin()
      : openMain = false,
        roleConfig = null,
        notificationPayload = null;

  const _StartResult.goToMain(
    RoleConfig role, {
    String? notificationPayload,
  })  : openMain = true,
        roleConfig = role,
        notificationPayload = notificationPayload;
}