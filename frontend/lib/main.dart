import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'providers/follow_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/template_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ranking_provider.dart';
import 'core/theme/app_theme.dart';

// Auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';

// Home
import 'screens/home/home_screen.dart';

// Tasks
import 'screens/tasks/create_task_screen.dart';
import 'screens/tasks/task_detail_screen.dart';

// Calendar
import 'screens/calendar/calendar_screen.dart';

// Profile
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/settings_screen.dart';

// Social
import 'screens/social/search_screen.dart';
import 'screens/social/user_profile_screen.dart';
import 'screens/social/friends_screen.dart';

// Notifications
import 'screens/notifications/notifications_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RankingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        if (status == AuthStatus.checking) return null;
        final isAuth = status == AuthStatus.authenticated;
        final isAuthRoute = state.matchedLocation == '/login'         ||
                            state.matchedLocation == '/register'      ||
                            state.matchedLocation == '/welcome'       ||
                            state.matchedLocation == '/forgot-password';
        if (!isAuth && !isAuthRoute) return '/welcome';
        if (isAuth  && isAuthRoute)  return '/home';
        if (isAuth  && state.matchedLocation == '/') return '/home';
        return null;
      },
      routes: [
        // ── Splash ────────────────────────────────────────────────────────────
        GoRoute(path: '/',                builder: (_, __) => const SplashScreen()),

        // ── Auth ──────────────────────────────────────────────────────────────
        GoRoute(path: '/welcome',         builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/register',        builder: (_, __) => const RegisterScreen()),

        // ── Home ──────────────────────────────────────────────────────────────
        GoRoute(path: '/home',            builder: (_, __) => const HomeScreen()),

        // ── Tasks ─────────────────────────────────────────────────────────────
        // GoRoute(path: '/create-task',     builder: (_, __) => const CreateTaskScreen()),
        // GoRoute(
        //   path: '/task/:id',
        //   builder: (_, state) => TaskDetailScreen(
        //     taskId: int.parse(state.pathParameters['id']!),
        //   ),
        // ),

        // // ── Calendar ──────────────────────────────────────────────────────────
        // GoRoute(path: '/calendar',        builder: (_, __) => const CalendarScreen()),

        // // ── Profile ───────────────────────────────────────────────────────────
        // GoRoute(path: '/profile',         builder: (_, __) => const ProfileScreen()),
        // GoRoute(path: '/edit-profile',    builder: (_, __) => const EditProfileScreen()),
        // GoRoute(path: '/settings',        builder: (_, __) => const SettingsScreen()),

        // // ── Social ────────────────────────────────────────────────────────────
        // GoRoute(path: '/search',          builder: (_, __) => const SearchScreen()),
        // GoRoute(
        //   path: '/user/:username',
        //   builder: (_, state) => UserProfileScreen(
        //     username: state.pathParameters['username']!,
        //   ),
        // ),
        // GoRoute(path: '/friends',         builder: (_, __) => const FriendsScreen()),

        // // ── Notifications ─────────────────────────────────────────────────────
        // GoRoute(path: '/notifications',   builder: (_, __) => const NotificationsScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<SettingsProvider, bool>(
      (s) => s.isDarkTheme,
    );

    return MaterialApp.router(
      title:                      'Focus App',
      debugShowCheckedModeBanner: false,
      routerConfig:               _router,
      theme:                      AppTheme.light,
      darkTheme:                  AppTheme.dark,
      themeMode:                  isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}